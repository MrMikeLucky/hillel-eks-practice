variable "prefix" {
  description = "Префікс імен усіх ресурсів. Поставте своє прізвище: усі студенти в одному регіоні."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.prefix))
    error_message = "Префікс: лише малі літери, цифри й дефіс, від 3 до 20 символів."
  }
}

variable "region" {
  description = "Регіон AWS."
  type        = string
  default     = "eu-central-1"
}

variable "kubernetes_version" {
  description = <<-EOT
    Версія Kubernetes. Закріплена навмисно.
    УВАГА: версія, що вийшла зі стандартної підтримки (14 місяців), коштує $0.60/год
    замість $0.10 — це $438 на місяць замість $73. Перевіряйте раз на півроку.
  EOT
  type        = string
  default     = "1.34"
}

variable "vpc_cidr" {
  description = "Діапазон адрес VPC."
  type        = string
  default     = "10.30.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr має бути коректним записом CIDR, наприклад 10.30.0.0/16."
  }
}

variable "node_desired_size" {
  description = <<-EOT
    Скільки вузлів тримати.
    2 — під час заняття. 0 — між заняттями: кластер лишається живим,
    але за вузли ви не платите. Підняти назад — близько трьох хвилин.
  EOT
  type        = number
  default     = 2

  validation {
    condition     = var.node_desired_size >= 0 && var.node_desired_size <= 4
    error_message = "Від 0 до 4. Більше для навчального кластера не потрібно."
  }
}

variable "node_instance_types" {
  description = <<-EOT
    Типи машин для spot-групи. Кілька типів принципово важливі:
    spot шукає вільну потужність серед усіх перелічених, і один тип у списку —
    найчастіша причина, чому група не піднімається.
  EOT
  type        = list(string)
  default     = ["t3.medium", "t3a.medium", "t2.medium"]

  validation {
    condition     = length(var.node_instance_types) >= 2
    error_message = "Вкажіть щонайменше два типи машин, інакше spot часто не знайде потужності."
  }
}
