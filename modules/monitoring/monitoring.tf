resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "grafana_external_secret" {
  name      = "grafana-external-secret"
  chart     = "${path.module}/charts/grafana-external-secret"
  namespace = kubernetes_namespace.monitoring.metadata[0].name

  set {
    name  = "secretArn"
    value = var.grafana_secret_arn
  }
}

# kube-prometheus-stack bundles Prometheus, Grafana, Alertmanager and the
# metrics-server-compatible adapters used for HPA (autoscaling criterion).
resource "helm_release" "kube_prometheus_stack" {
  name       = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "60.3.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [file("${path.module}/values.yaml")]

  timeout = 900
  wait    = true

  depends_on = [helm_release.grafana_external_secret]
}

# Metrics Server is required for HorizontalPodAutoscaler (charts/django-app/hpa.yaml)
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.1"
  namespace  = "kube-system"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }
}
