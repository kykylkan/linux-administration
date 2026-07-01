output "namespace" {
  value = kubernetes_namespace.jenkins.metadata[0].name
}

output "release_name" {
  value = helm_release.jenkins.name
}

output "admin_password_command" {
  value = "kubectl exec --namespace ${kubernetes_namespace.jenkins.metadata[0].name} -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password"
}
