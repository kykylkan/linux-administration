resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
  }
}

# Service Account, під яким Jenkins Kubernetes-агенти (Kaniko) зможуть пушити
# образи в ECR через IAM-права нод (IRSA не використовується для спрощення,
# права видаються ролі ноди модуля eks - AmazonEC2ContainerRegistryReadOnly
# вже додано; для push потрібен додатково ecr:PutImage і т.д., див. README).
resource "kubernetes_service_account" "jenkins_agent" {
  metadata {
    name      = "jenkins-agent"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = var.chart_version
  namespace  = kubernetes_namespace.jenkins.metadata[0].name

  values = [
    file("${path.module}/values.yaml")
  ]

  # Передаємо URL ECR та регіон як env-змінні агента, щоб Jenkinsfile
  # міг використовувати їх без хардкоду.
  set {
    name  = "agent.envVars[0].name"
    value = "ECR_REPO_URL"
  }

  set {
    name  = "agent.envVars[0].value"
    value = var.ecr_repo_url
  }

  set {
    name  = "agent.envVars[1].name"
    value = "AWS_REGION"
  }

  set {
    name  = "agent.envVars[1].value"
    value = var.aws_region
  }

  timeout = 600
}
