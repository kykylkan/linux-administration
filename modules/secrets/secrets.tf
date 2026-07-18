resource "random_password" "django_secret_key" {
  length  = 64
  special = true
}

resource "random_password" "grafana_admin" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "django" {
  name                    = "${var.project_name}/django"
  recovery_window_in_days = 7
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "django" {
  secret_id = aws_secretsmanager_secret.django.id
  secret_string = jsonencode({
    secret_key = random_password.django_secret_key.result
  })
}

resource "aws_secretsmanager_secret" "grafana" {
  name                    = "${var.project_name}/grafana"
  recovery_window_in_days = 7
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "grafana" {
  secret_id = aws_secretsmanager_secret.grafana.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.grafana_admin.result
  })
}
