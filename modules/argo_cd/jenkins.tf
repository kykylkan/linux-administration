# NOTE: filename kept as jenkins.tf per the project structure spec, but this
# file installs Argo CD (not Jenkins - that lives in ../jenkins).
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.3.11"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [file("${path.module}/values.yaml")]

  timeout = 600
  wait    = true
}

# App-of-Apps: a single Argo CD Application that points at charts/ in this
# repo, which in turn declares the django-app Application/Repository CRs.
resource "helm_release" "app_of_apps" {
  name       = "app-of-apps"
  chart      = "${path.module}/charts"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  set {
    name  = "repoURL"
    value = var.repo_url
  }

  set {
    name  = "targetRevision"
    value = var.target_revision
  }

  depends_on = [helm_release.argocd]
}
