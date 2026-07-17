# DevOps Final Project — AWS + EKS + CI/CD + Monitoring

Terraform-провізована інфраструктура на AWS: VPC, EKS, RDS, ECR, Jenkins,
Argo CD, Prometheus/Grafana, і Django-застосунок, що деплоїться через
Jenkins (build/push) + Argo CD (GitOps sync) у кластер EKS.

## Структура

Відповідає структурі з ТЗ: `main.tf` / `backend.tf` / `outputs.tf` в корені,
усі ресурси розкладені по `modules/*`, Helm-чарт застосунку — у
`charts/django-app`, чарт Argo CD App-of-Apps — у
`modules/argo_cd/charts`, вихідний код Django — у `Django/`.

## Порядок запуску (bootstrap)

Backend S3+DynamoDB створюється тим самим кодом, який його потім
використовує — класична проблема "курки і яйця" в Terraform. Порядок:

1. **Перший прогін — локальний state.** Закоментуйте блок `backend "s3"`
   у `backend.tf`, залиште лише `required_providers`.
   ```bash
   terraform init
   terraform apply -target=module.s3_backend
   ```
2. **Міграція state в S3.** Розкоментуйте `backend "s3"` (бакет і таблиця
   вже існують — назви збігаються з `${project_name}-tfstate` /
   `${project_name}-tf-lock`), потім:
   ```bash
   terraform init -migrate-state
   ```
3. **Повне розгортання інфраструктури:**
   ```bash
   terraform apply
   ```
   Це підніме VPC → EKS → ECR/RDS → Jenkins/Argo CD/Monitoring (Helm-релізи
   в модулях залежать від `module.eks` через `depends_on`, тож порядок
   витримується автоматично).

4. **kubeconfig:**
   ```bash
   aws eks update-kubeconfig --region eu-central-1 --name devops-final-eks
   ```

5. **Перевірка ресурсів:**
   ```bash
   kubectl get all -n jenkins
   kubectl get all -n argocd
   kubectl get all -n monitoring
   ```

6. **Доступ до сервісів:**
   ```bash
   kubectl port-forward svc/jenkins 8080:8080 -n jenkins
   kubectl port-forward svc/argocd-server 8081:443 -n argocd
   kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
   ```
   - Jenkins admin-пароль: `modules/jenkins` → output `admin_password_command`.
   - Argo CD admin-пароль: `modules/argo_cd` → output `initial_admin_password_command`.
   - Grafana: логін `admin`, пароль — значення `grafana.adminPassword` у
     `modules/monitoring/values.yaml` (замініть перед реальним деплоєм).

7. **CI/CD цикл:** пуш у `main` → Jenkins (`Django/Jenkinsfile`) білдить
   образ, пушить в ECR, оновлює Helm-values і синхронізує через Argo CD
   (`modules/argo_cd` App-of-Apps стежить за `charts/django-app`).

## Перед `terraform apply` заповніть

- `db_password` — через `TF_VAR_db_password` або `terraform.tfvars`
  (не комітити!).
- `argocd_repo_url` — URL цього репозиторію (використовується Argo CD і
  `modules/argo_cd/charts/values.yaml`).
- `charts/django-app/values.yaml` → `image.repository` і `env.DB_HOST`
  підставляються автоматично з Jenkinsfile / terraform output, але для
  ручного `helm install` їх треба виставити самому.
- Jenkins credentials `ecr-repo-url`, `db-password` — створити в
  Jenkins UI (Credentials store) перед першим прогоном пайплайну.

## ⚠️ Видалення ресурсів

```bash
terraform destroy
```
Видаляє все, включно з S3-бакетом/DynamoDB стейту — після цього стейт
локальний, наступний `apply` знову починайте з кроку 1.

## Відповідність критеріям оцінювання

| Критерій | Де реалізовано |
|---|---|
| Коректна архітектура (20) | `modules/vpc` (public/private subnets, NAT, IGW), `modules/eks` |
| Безпека: VPC/IAM/SG (20) | приватні subnet для нод і RDS, `aws_security_group.db` дозволяє тільки трафік з EKS SG, окремі IAM-ролі cluster/node з мінімально необхідними policy |
| CI/CD деплой (30) | `Django/Jenkinsfile` (build→test→push ECR→helm upgrade) + `modules/argo_cd` (GitOps sync) |
| Моніторинг + автомасштабування (20) | `modules/monitoring` (kube-prometheus-stack, metrics-server) + `charts/django-app/templates/hpa.yaml` |
| Документація (10) | цей README + коментарі в `.tf`/`values.yaml` |
