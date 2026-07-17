output "namespace" {
  value = kubernetes_namespace.jenkins.metadata[0].name
}

output "release_name" {
  value = helm_release.jenkins.name
}

output "admin_password_command" {
  description = "Run this after apply to fetch the initial admin password"
  value       = "kubectl exec -n ${var.namespace} -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password"
}
