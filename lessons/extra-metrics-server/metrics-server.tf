# ---------------------------------------------------------------------------
# Додатково, не на занятті. Скопіюйте в cluster/ ПІСЛЯ файлів заняття 9:
# цей файл використовує провайдер helm із kubernetes-providers.tf.
#
# metrics-server збирає метрики використання подів і вузлів. Без нього не
# працює ані kubectl top, ані горизонтальне автомасштабування подів.
# Обраний як приклад, бо не потребує жодної ролі IAM — лише сам чарт.
# ---------------------------------------------------------------------------
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.2"
  namespace  = "kube-system"

  values = [yamlencode({
    resources = {
      requests = {
        cpu    = "100m"
        memory = "200Mi"
      }
    }
  })]

  depends_on = [module.eks]
}
