resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = "5.7.7"
  namespace  = kubernetes_namespace.jenkins.metadata[0].name

  values = [file("${path.module}/values.yaml")]

  timeout = 600
  wait    = true
}
