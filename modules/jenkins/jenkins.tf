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

  values = [
    file("${path.module}/values.yaml"),
    yamlencode({
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.ecr_push.arn
        }
      }
      controller = {
        JCasC = {
          configScripts = {
            global-environment = <<-EOT
              jenkins:
                globalNodeProperties:
                  - envVars:
                      env:
                        - key: ECR_REPO
                          value: "${var.ecr_repository_url}"
            EOT
          }
        }
      }
    }),
  ]

  timeout = 900
  wait    = true

  depends_on = [aws_iam_role_policy.ecr_push]
}
