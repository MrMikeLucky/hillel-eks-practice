variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "tfc_organization" {
  description = "Ім'я вашої організації в HCP Terraform."
  type        = string
}

variable "workspace_prefix" {
  description = <<-EOT
    Префікс імен воркспейсів, яким дозволено приміряти роль.
    Зірочка в шаблоні дозволяє мати кілька середовищ без правок в AWS.
  EOT
  type        = string
  default     = "hillel-eks"
}

variable "role_name" {
  type    = string
  default = "tfc-hillel-eks"
}
