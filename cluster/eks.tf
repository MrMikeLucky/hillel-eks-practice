# ---------------------------------------------------------------------------
# Кластер EKS.
#
# Вартість: контрольний рівень $0.10/год ($73 на місяць) незалежно ні від чого —
# навіть якщо вузлів нуль і подів нуль. Саме тому між заняттями ми опускаємо
# вузли в нуль (node_desired_size = 0), а не видаляємо кластер: перестворення
# контрольного рівня триває 9-12 хвилин щоразу.
# ---------------------------------------------------------------------------

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.name
  kubernetes_version = var.kubernetes_version

  # Сервер API доступний з інтернету. Інакше знадобився б бастіон або VPN.
  endpoint_public_access  = true
  endpoint_private_access = true

  # Той, хто створив кластер, одразу отримує права адміністратора в ньому.
  # Без цього kubectl не запрацює навіть у вас.
  enable_cluster_creator_admin_permissions = true

  vpc_id = module.vpc.vpc_id

  # Вузли у публічних підмережах — див. пояснення у vpc.tf
  subnet_ids = module.vpc.public_subnets

  # -------------------------------------------------------------------------
  # Доповнення EKS: компоненти, які AWS постачає, версіонує й оновлює
  # як частину сервісу. Порожні {} означають версію за замовчуванням
  # для цієї версії Kubernetes.
  # -------------------------------------------------------------------------
  addons = {
    # Мережевий плагін має бути налаштований ДО появи вузлів,
    # інакше перші поди отримають не ті адреси. Це реальна залежність
    # порядку, а не декоративний прапорець.
    vpc-cni = {
      before_compute = true
    }

    coredns                = {}
    kube-proxy             = {}
    eks-pod-identity-agent = {}

    # Драйверу дисків потрібен доступ до AWS: він створює й підключає томи EBS
    # на вимогу PersistentVolumeClaim. Роль прив'язується до службового акаунта.
    aws-ebs-csi-driver = {
      pod_identity_association = [{
        role_arn        = aws_iam_role.ebs_csi.arn
        service_account = "ebs-csi-controller-sa"
      }]
    }
  }

  # -------------------------------------------------------------------------
  # Група вузлів на spot-машинах.
  # Знижка 70-90% від звичайної ціни. Плата за це — AWS може забрати машину,
  # попередивши за дві хвилини.
  # -------------------------------------------------------------------------
  eks_managed_node_groups = {
    spot = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      capacity_type  = "SPOT"

      # min_size = 0 — саме це дозволяє опускати кластер у нуль
      # між заняттями, не видаляючи його.
      min_size     = 0
      max_size     = 4
      desired_size = var.node_desired_size

      disk_size = 20

      labels = {
        workload = "general"
      }

      tags = local.common_tags
    }
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Роль для драйвера дисків EBS.
#
# Драйвер створює й підключає томи EBS на вимогу PersistentVolumeClaim,
# тому йому потрібен доступ до AWS. Дає його роль, прив'язана до службового
# акаунта через Pod Identity — под не зберігає жодного ключа.
#
# ВАЖЛИВО ПРО ПОЛІТИКУ ДОВІРИ:
# для Pod Identity роль довіряє СЕРВІСУ pods.eks.amazonaws.com.
# Це відрізняється від старшого механізму IRSA, де роль довіряла
# OIDC-провайдеру кластера. Плутанина між ними — часта причина помилки
# "is not authorized to perform: sts:AssumeRole".
#
# Друга відмінність: окрім sts:AssumeRole потрібна ще й sts:TagSession.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "ebs_csi_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "${var.prefix}-ebs-csi"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_trust.json

  tags = local.common_tags
}

# Готова керована політика від AWS саме для цього драйвера.
resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
