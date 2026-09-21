# ---------------------------------------------------------------------------
# Flux — система доставки застосунків у кластер.
#
# ЧОМУ ОКРЕМА КОНФІГУРАЦІЯ: провайдер helm підключається до кластера, якого
# на момент планування cluster/ ще не існує. Тому кластер і те, що в ньому,
# розводимо по різних конфігураціях і різних воркспейсах.
#
# Застосовується ПІСЛЯ того, як cluster/ піднявся і вузли в стані Ready.
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.9"

  cloud {
    organization = "ОРГАНІЗАЦІЯ"

    workspaces {
      tags = ["hillel-eks-flux"]
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

# ---------------------------------------------------------------------------
# Токен для доступу до кластера.
#
# ЧОМУ НЕ exec { command = "aws" ... }, як у більшості прикладів в інтернеті:
# на раннерах HCP Terraform немає AWS CLI, тому виклик зовнішньої команди
# впаде. Data-джерело нижче отримує той самий токен засобами провайдера aws,
# без жодних зовнішніх програм. Токен живе 15 хвилин — для одного запуску
# з запасом.
# ---------------------------------------------------------------------------
data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
