output "check_commands" {
  description = "Команди для перевірки, що Flux працює."
  value       = <<-EOT
    kubectl get pods -n flux-system
    kubectl get gitrepositories,kustomizations -n flux-system
    kubectl get pods -n shop
  EOT
}
