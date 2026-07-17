output "namespace" {
  value = kubernetes_namespace.monitoring.metadata[0].name
}

output "grafana_service_name" {
  value = "monitoring-grafana"
}
