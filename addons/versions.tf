# ---------------------------------------------------------------------------
# Зовнішні компоненти кластера.
#
# ЧОМУ ЦЕ ОКРЕМА КОНФІГУРАЦІЯ, А НЕ ЧАСТИНА cluster/
#
# Провайдер helm налаштовується на кластер, якого на момент планування
# ще може не існувати — і план падає з незрозумілою помилкою підключення.
# Тому кластер і те, що в ньому працює, майже завжди розводять по різних
# конфігураціях або застосовують у два кроки.
#
# Ця конфігурація читає дані створеного кластера через data-джерела,
# тому вимагає, щоб cluster/ був застосований раніше.
#
# НА ЗАНЯТТІ 8 МИ ЇЇ НЕ ЗАСТОСОВУЄМО. Вона тут як приклад того,
# про що йшлося в четвертому розділі, і знадобиться на наступних заняттях.
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.9"

  cloud {
    organization = "ОРГАНІЗАЦІЯ"

    workspaces {
      tags = ["hillel-eks-addons"]
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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

# Токен засобами провайдера aws, а не зовнішньою командою:
# на раннерах HCP Terraform немає AWS CLI, тому exec { command = "aws" } там падає.
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

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}
