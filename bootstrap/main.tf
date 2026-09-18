# ---------------------------------------------------------------------------
# OIDC-провайдер: реєструє факт довіри до токенів, які видає HCP Terraform.
# Один на акаунт.
#
# Два значення, які не вгадуються, — вони задані платформою:
#   url            https://app.terraform.io   (без скісної риски в кінці)
#   client_id_list aws.workload.identity
#
# Аргумент thumbprint_list у сучасних версіях провайдера необов'язковий:
# з липня 2023 AWS перевіряє сертифікат через власну бібліотеку кореневих
# центрів, а не за відбитком. Якщо бачите його у старих прикладах — це спадок.
# ---------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "tfc" {
  url            = "https://app.terraform.io"
  client_id_list = ["aws.workload.identity"]
}

# ---------------------------------------------------------------------------
# Політика довіри: ХТО може приміряти роль.
#
# Claim sub має вигляд:
#   organization:ОРГ:project:ПРОЄКТ:workspace:ВОРКСПЕЙС:run_phase:plan|apply
#
# Зірочки вимагають оператора StringLike. Зі StringEquals вони не працюють —
# це найчастіша причина помилки "Not authorized to perform
# sts:AssumeRoleWithWebIdentity".
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.tfc.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "app.terraform.io:aud"
      values   = ["aws.workload.identity"]
    }

    condition {
      test     = "StringLike"
      variable = "app.terraform.io:sub"
      values = [
        "organization:${var.tfc_organization}:project:*:workspace:${var.workspace_prefix}*:run_phase:*",
      ]
    }
  }
}

resource "aws_iam_role" "tfc" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

# ---------------------------------------------------------------------------
# Права ролі.
#
# Для навчального кластера беремо готові керовані політики. У продакшні
# так НЕ роблять: там права звужують до конкретних дій і ресурсів.
# ---------------------------------------------------------------------------

locals {
  policies = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser",
  ]
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(local.policies)

  role       = aws_iam_role.tfc.name
  policy_arn = each.value
}

# EKS потребує кількох дій, яких немає в готових політиках.
data "aws_iam_policy_document" "eks_extra" {
  statement {
    effect = "Allow"
    actions = [
      "eks:*",
      "logs:*",
      "autoscaling:*",
      "cloudformation:Describe*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "eks_extra" {
  name   = "${var.role_name}-extra"
  role   = aws_iam_role.tfc.id
  policy = data.aws_iam_policy_document.eks_extra.json
}

output "role_arn" {
  description = "Покладіть це значення у змінну середовища TFC_AWS_RUN_ROLE_ARN вашого воркспейса."
  value       = aws_iam_role.tfc.arn
}
