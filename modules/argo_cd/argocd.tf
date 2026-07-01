resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_namespace" "target" {
  metadata {
    name = var.target_namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    file("${path.module}/values.yaml")
  ]

  timeout = 600
}

# ---------------------------------------------------------------------------
# Argo CD Application, що синхронізує Helm chart django-app з git-репозиторію
# в кластер. Реалізовано через окремий Helm chart (modules/argo_cd/charts),
# що рендерить Application + Repository CR.
# ---------------------------------------------------------------------------
resource "helm_release" "argocd_apps" {
  name      = "argocd-apps"
  chart     = "${path.module}/charts"
  namespace = kubernetes_namespace.argocd.metadata[0].name

  set {
    name  = "application.name"
    value = "django-app"
  }

  set {
    name  = "application.repoURL"
    value = var.git_repo_url
  }

  set {
    name  = "application.targetRevision"
    value = var.git_repo_revision
  }

  set {
    name  = "application.path"
    value = var.chart_path
  }

  set {
    name  = "application.destinationNamespace"
    value = var.target_namespace
  }

  depends_on = [helm_release.argocd, kubernetes_namespace.target]
}
