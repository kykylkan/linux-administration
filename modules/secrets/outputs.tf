output "django_secret_arn" {
  value = aws_secretsmanager_secret.django.arn
}

output "grafana_secret_arn" {
  value = aws_secretsmanager_secret.grafana.arn
}
