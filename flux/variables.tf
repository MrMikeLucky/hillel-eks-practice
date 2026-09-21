variable "cluster_name" {
  description = "Ім'я кластера. Візьміть із виводу конфігурації cluster/: terraform output cluster_name"
  type        = string
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "git_url" {
  description = <<-EOT
    Адреса ВАШОГО форку цього репозиторію, звідки Flux братиме маніфести.
    Репозиторій має бути публічним: тоді Flux читає його без жодних облікових
    даних. Формат: https://github.com/ваш-логін/hillel-eks-practice
  EOT
  type        = string

  validation {
    condition     = can(regex("^https://", var.git_url))
    error_message = "Вкажіть адресу, що починається з https:// — для публічного репозиторію цього досить."
  }
}

variable "git_branch" {
  description = <<-EOT
    Гілка, за якою стежить Flux.
    УВАГА: чарт flux2-sync за замовчуванням дивиться в гілку master, а GitHub
    для нових репозиторіїв створює main. Не змінюйте, якщо не знаєте навіщо.
  EOT
  type        = string
  default     = "main"
}

variable "app_path" {
  description = "Тека з маніфестами застосунку всередині репозиторію."
  type        = string
  default     = "./apps/shop"
}

variable "sync_interval" {
  description = "Як часто Flux перевіряє репозиторій. На занятті ставимо коротко, щоб бачити результат одразу."
  type        = string
  default     = "1m"
}
