resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = var.namespace
  }
}

resource "aws_iam_role" "external_secrets" {
  name = "${var.project_name}-external-secrets-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:${var.namespace}:external-secrets"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "read_secrets" {
  name = "read-application-secrets"
  role = aws_iam_role.external_secrets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
      ]
      Resource = var.secret_arns
    }]
  })
}

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.10.5"
  namespace  = kubernetes_namespace.external_secrets.metadata[0].name

  set {
    name  = "serviceAccount.name"
    value = "external-secrets"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_secrets.arn
  }

  timeout = 600
  wait    = true

  depends_on = [aws_iam_role_policy.read_secrets]
}

resource "helm_release" "secret_store" {
  name      = "aws-secret-store"
  chart     = "${path.module}/charts/secret-store"
  namespace = kubernetes_namespace.external_secrets.metadata[0].name

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  depends_on = [helm_release.external_secrets]
}
