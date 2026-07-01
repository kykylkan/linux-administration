output "namespace" {
  value = kubernetes_namespace.argocd.metadata[0].name
}

output "admin_password_command" {
  value = "kubectl -n ${kubernetes_namespace.argocd.metadata[0].name} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}
