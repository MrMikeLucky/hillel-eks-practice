variable "cluster_name" {
  description = "Ім'я кластера з виводу конфігурації cluster/."
  type        = string
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "enable_metrics_server" {
  description = "Найпростіший компонент для першого знайомства: без нього не працює kubectl top."
  type        = bool
  default     = true
}
