output "namespace" {
  value = kubernetes_namespace.argocd.metadata[0].name
}

output "initial_admin_password_command" {
  description = "Run this after apply to fetch the initial admin password"
  value       = "kubectl -n ${var.namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}
