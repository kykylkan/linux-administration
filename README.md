# DevOps Final Project — AWS, EKS і GitOps

Terraform створює VPC, EKS, ECR, PostgreSQL RDS або Aurora, Jenkins,
Argo CD, External Secrets Operator та Prometheus/Grafana. Django
розгортається тільки через Argo CD.

## Найпростіший запуск

На macOS запустіть:

```bash
./scripts/deploy.sh
```

Скрипт перевірить і запропонує встановити Homebrew, AWS CLI, Terraform,
kubectl та Helm. Потім він попросить AWS credentials і URL публічного
GitHub repository, створить унікальний S3 backend, розгорне інфраструктуру
та налаштує kubectl.

Скрипт не просить GitHub token: його потрібно один раз додати безпосередньо
в Jenkins після деплою, щоб token не потрапив у Terraform state або файл.

## Архітектура CI/CD

```text
Git push → Jenkins tests → immutable image → ECR
                                      ↓
Jenkins updates charts/django-app/values.yaml
                                      ↓
                     Argo CD automated sync → EKS
```

Jenkins не виконує `helm upgrade`. Це усуває конфлікт із Argo CD
`selfHeal`. ECR repository URL передається в Jenkins через Terraform/JCasC,
а ECR URL і RDS address/port — у Django Application через Helm parameters.

## Bootstrap Terraform state

State backend має окремий lifecycle у `bootstrap/`. `backend.tf` використовує
partial backend configuration: конкретні S3/DynamoDB names передаються в
`terraform init`. `scripts/deploy.sh` формує унікальні назви з AWS account ID.

Для ручного запуску:

```bash
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
STATE_BUCKET="devops-final-${ACCOUNT_ID}-tfstate"
LOCK_TABLE="devops-final-${ACCOUNT_ID}-tf-lock"

terraform -chdir=bootstrap init
terraform -chdir=bootstrap apply \
  -var="state_bucket_name=${STATE_BUCKET}" \
  -var="lock_table_name=${LOCK_TABLE}"

terraform init -reconfigure \
  -backend-config="bucket=${STATE_BUCKET}" \
  -backend-config="dynamodb_table=${LOCK_TABLE}" \
  -backend-config="region=eu-central-1"
```

Ресурси state мають `prevent_destroy` і не входять до основного
`terraform destroy`.

## Налаштування

Перед застосуванням задайте URL цього Git-репозиторію:

```bash
terraform apply \
  -var='argocd_repo_url=https://github.com/OWNER/REPOSITORY.git'
```

Наведений Argo CD Repository Secret розрахований на public repository. Для
private repository додайте repository credential у Argo CD окремо, не
зберігаючи token у Git або Terraform variables.

Для Aurora:

```bash
terraform apply -var='use_aurora=true'
```

RDS сам створює master credentials у AWS Secrets Manager. Terraform також
генерує окремі Django і Grafana secrets. External Secrets Operator читає
тільки ці ARN через IRSA та створює Kubernetes Secrets. Секретні значення
не зберігаються в Git або Helm values.

## IAM та IRSA

- EKS node role має `AmazonEC2ContainerRegistryReadOnly` лише для pull.
- Jenkins service account має окрему least-privilege role для push у
  конкретний ECR repository.
- EBS CSI controller має окрему AWS-managed IRSA policy.
- External Secrets service account має read-доступ тільки до трьох
  application secrets.

Перевірка:

```bash
terraform output jenkins_ecr_push_role_arn
terraform output external_secrets_role_arn
kubectl get serviceaccount jenkins -n jenkins -o yaml
kubectl get serviceaccount external-secrets -n external-secrets -o yaml
```

## Jenkins

Створіть Pipeline/Multibranch job із Script Path `Django/Jenkinsfile`.
Додайте один Jenkins credential:

- ID `git-write-credentials`
- тип `Username with password`
- username GitHub username
- password GitHub token із правом запису в репозиторій

AWS static credentials, ECR URL і DB password у Jenkins не потрібні.
Pipeline використовує IRSA, пушить лише commit SHA tag і комітить новий
`image.tag` із `[skip ci]`.

## RDS

`use_aurora=false` створює standalone PostgreSQL, `true` — Aurora
PostgreSQL. Обидва варіанти мають parameter groups. Параметри можна
перевизначити через `db_parameters`; версії, parameter group families та
кількість Aurora instances винесені у variables.

```bash
terraform output -raw rds_endpoint
terraform output rds_port
terraform output rds_master_user_secret_arn
```

## Доступ і перевірка

```bash
aws eks update-kubeconfig --region eu-central-1 --name devops-final-eks
kubectl get nodes
kubectl get pods -A
kubectl get externalsecrets -A
kubectl get application django-app -n argocd

kubectl port-forward svc/jenkins 8080:8080 -n jenkins
kubectl port-forward svc/argocd-server 8081:443 -n argocd
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
kubectl port-forward svc/django-app 8000:80
curl http://localhost:8000/readyz/
```

Grafana credentials отримуються без виведення в репозиторій:

```bash
kubectl get secret grafana-admin -n monitoring \
  -o jsonpath='{.data.admin-password}' | base64 -d
```

## Видалення

```bash
terraform destroy
```

Ця команда не видаляє bootstrap state. Для свідомого видалення S3/DynamoDB
спочатку окремо приберіть `prevent_destroy` у bootstrap stack.

## Докази деплою

Чекліст обов'язкових реальних скриншотів і безпечних команд знаходиться в
`docs/deploy-evidence/README.md`. Скриншоти треба зробити після деплою у
власному AWS account; секрети й account identifiers слід замаскувати.
