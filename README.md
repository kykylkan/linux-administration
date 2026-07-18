# DevOps Final Project — AWS, EKS і GitOps

Навчальний production-like проєкт, у якому Terraform створює інфраструктуру
AWS, Jenkins збирає Django image, а Argo CD розгортає застосунок у Kubernetes
за GitOps-моделлю.

Регіон за замовчуванням — `eu-central-1`. Інфраструктура містить VPC, EKS,
ECR, PostgreSQL RDS або Aurora PostgreSQL, Jenkins, Argo CD, External Secrets
Operator, Prometheus, Grafana, metrics-server та HPA.

> EKS, NAT Gateway і RDS є платними сервісами. Після перевірки проєкту
> обов’язково виконайте повне видалення через `scripts/destroy.sh`.

## Архітектура

```text
Developer pushes code to GitHub
              |
              v
Jenkins: check + tests + Docker build
              |
              v
Amazon ECR: immutable image with Git SHA tag
              |
              v
Jenkins updates charts/django-app/values.yaml in main
              |
              v
Argo CD automated sync + selfHeal
              |
              v
Django in EKS + RDS + External Secrets + HPA
              |
              v
Prometheus metrics + Grafana dashboards
```

Jenkins не виконує `helm upgrade`. Він тестує код, збирає image, пушить його
в ECR і комітить новий `image.tag` у Git. Argo CD відстежує гілку `main` та
автоматично синхронізує Helm chart. Це усуває конфлікт між CI і GitOps.

## Реалізовані вимоги

- **Infrastructure as Code:** усі AWS та Kubernetes resources описані в
  Terraform і Helm.
- **AWS networking:** окремий VPC, public/private subnets, Internet Gateway,
  NAT Gateway та route tables.
- **Kubernetes:** EKS `1.33`, managed node group із двох `t3.medium`,
  EBS CSI driver і default encrypted `gp3` StorageClass.
- **Database:** PostgreSQL `16.14` або Aurora PostgreSQL `15.17`,
  private networking, encryption, parameter groups і credentials у Secrets
  Manager.
- **Container registry:** ECR з immutable tags, image scanning та lifecycle
  policy для останніх десяти images.
- **CI/CD:** Jenkins pipeline і Argo CD App-of-Apps.
- **Security:** IAM least privilege, Security Groups, OIDC та IRSA без static
  AWS keys у Kubernetes pods.
- **Secrets:** AWS Secrets Manager + External Secrets Operator; passwords не
  зберігаються в Git, Helm values або Jenkinsfile.
- **Monitoring:** Prometheus, Grafana, metrics-server та HPA для Django
  від 2 до 6 replicas за CPU 70%.

## Структура репозиторію

```text
.
├── backend.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── bootstrap/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── modules/
│   ├── s3-backend/        # versioned S3 state + DynamoDB lock
│   ├── vpc/               # VPC, subnets, NAT, routes
│   ├── ecr/               # immutable Django image repository
│   ├── eks/               # cluster, nodes, OIDC, EBS CSI, access entry
│   ├── rds/               # PostgreSQL або Aurora + parameter groups
│   ├── secrets/           # Django і Grafana Secrets Manager secrets
│   ├── external_secrets/  # operator, IRSA, ClusterSecretStore
│   ├── jenkins/           # Helm release, JCasC, ECR push IRSA
│   ├── argo_cd/           # Argo CD та App-of-Apps chart
│   └── monitoring/        # Prometheus, Grafana, metrics-server
├── charts/
│   └── django-app/        # Deployment, Service, ExternalSecret, HPA
├── Django/
│   ├── app/
│   ├── Dockerfile
│   ├── Jenkinsfile
│   └── docker-compose.yaml
└── scripts/
    ├── deploy.sh
    └── destroy.sh
```

`bootstrap/` використовує обов’язковий модуль `modules/s3-backend`.
State bucket і DynamoDB table створюються окремо до ініціалізації root
Terraform backend.

## Передумови

- macOS із Homebrew для автоматичного скрипта;
- AWS account з дозволами на VPC, EC2, EKS, IAM, RDS, ECR, S3, DynamoDB,
  Secrets Manager і CloudWatch;
- публічний GitHub repository з гілкою `main`;
- GitHub Personal Access Token із `Contents: Read and write`;
- локально: `git`, `aws`, Terraform `>= 1.5`, `kubectl`, `helm`, `python3`.

Не комітьте `.env`, `.deploy.env`, `terraform.tfvars`, Terraform state,
AWS credentials або GitHub token.

## Найпростіший деплой

Використовуйте один AWS profile для створення і видалення ресурсів:

```bash
export AWS_PROFILE=final-project
AWS_PROFILE=final-project ./scripts/deploy.sh
```

Якщо profile ще не налаштований, скрипт запустить `aws configure`. Для AWS
Academy він додатково запропонує ввести session token. Скрипт:

1. перевірить або встановить потрібні CLI через Homebrew;
2. перевірить AWS credentials;
3. попросить HTTPS URL публічного GitHub repository;
4. створить унікальні S3/DynamoDB backend names з AWS account ID;
5. створить EKS access entry для поточного IAM principal;
6. розгорне повний stack за 25–45 хвилин;
7. налаштує kubeconfig;
8. збереже параметри deployment у gitignored `.deploy.env`.

Під час першого запуску введіть URL repository, у якому вже є цей проєкт:

```text
https://github.com/OWNER/REPOSITORY.git
```

Порожній repository не підходить. Гілка `main` обов’язкова, оскільки Jenkins
пушить GitOps commit у `main`, а Argo CD відстежує `main`.

## Ручний Terraform workflow

Автоматичний скрипт рекомендований. Для ручного запуску:

```bash
export AWS_PROFILE=final-project
export AWS_REGION=eu-central-1

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
STATE_BUCKET="devops-final-${ACCOUNT_ID}-tfstate"
LOCK_TABLE="devops-final-${ACCOUNT_ID}-tf-lock"
REPO_URL="https://github.com/OWNER/REPOSITORY.git"

terraform -chdir=bootstrap init
terraform -chdir=bootstrap apply \
  -var="aws_region=${AWS_REGION}" \
  -var="state_bucket_name=${STATE_BUCKET}" \
  -var="lock_table_name=${LOCK_TABLE}"

terraform init -reconfigure \
  -backend-config="bucket=${STATE_BUCKET}" \
  -backend-config="dynamodb_table=${LOCK_TABLE}" \
  -backend-config="region=${AWS_REGION}"

terraform apply -auto-approve \
  -target="module.eks.aws_eks_access_policy_association.terraform_admin" \
  -var="aws_region=${AWS_REGION}" \
  -var="argocd_repo_url=${REPO_URL}"

terraform apply -auto-approve \
  -var="aws_region=${AWS_REGION}" \
  -var="argocd_repo_url=${REPO_URL}"

cat >.deploy.env <<EOF
AWS_REGION=${AWS_REGION}
AWS_ACCOUNT_ID=${ACCOUNT_ID}
STATE_BUCKET_NAME=${STATE_BUCKET}
LOCK_TABLE_NAME=${LOCK_TABLE}
REPOSITORY_URL=${REPO_URL}
EOF
```

Targeted apply потрібен один раз, щоб Terraform отримав Kubernetes API
access до створення Helm releases. `.deploy.env` потрібен `destroy.sh`; він
gitignored і не повинен потрапляти в repository.

Замість CLI variables можна скопіювати приклад:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Замініть repository URL. `terraform.tfvars` ігнорується Git.

Для Aurora:

```hcl
use_aurora = true
```

## Secrets та IRSA

- EKS node role має ECR read-only policy лише для image pull.
- Jenkins service account використовує окрему IRSA role для push у
  конкретний ECR repository.
- EBS CSI controller використовує окрему AWS-managed IRSA policy.
- External Secrets service account може читати лише RDS, Django і Grafana
  secrets.
- RDS керує master password через Secrets Manager.
- External Secrets створює Kubernetes Secrets без запису значень у Git.

Перевірка:

```bash
terraform output jenkins_ecr_push_role_arn
terraform output external_secrets_role_arn
kubectl get serviceaccount jenkins -n jenkins -o yaml
kubectl get serviceaccount external-secrets -n external-secrets -o yaml
kubectl get clustersecretstore
kubectl get externalsecrets -A
```

## Налаштування Jenkins

Після deploy відкрийте Jenkins:

```bash
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
```

Адреса: `http://localhost:8080`.

Логін — `admin`. Initial password отримуйте лише локально:

```bash
kubectl exec -n jenkins -it svc/jenkins -c jenkins -- \
  /bin/cat /run/secrets/additional/chart-admin-password
```

Створіть Pipeline або Multibranch Pipeline:

- repository URL — URL цього GitHub repository;
- branch — `main`;
- Script Path — `Django/Jenkinsfile`;
- credential ID — `git-write-credentials`;
- credential type — `Username with password`;
- username — GitHub username;
- password — GitHub PAT із правом `Contents: Read and write`.

Pipeline виконує:

1. Checkout і визначення Git SHA.
2. Django system check та unit tests.
3. Docker build.
4. ECR login через окремий AWS CLI container та IRSA.
5. Push immutable image `ECR_REPO:GIT_SHA`.
6. Оновлення `charts/django-app/values.yaml`.
7. Git commit із `[skip ci]` та push у `main`.

AWS Access Key, Secret Key, ECR URL і DB password у Jenkins credentials не
потрібні. ECR URL передається через Terraform/JCasC.

## GitOps та Django

Terraform передає Argo CD:

- ECR repository URL;
- RDS endpoint і port;
- RDS master secret ARN;
- Django secret ARN.

Argo CD створює application `django-app` у namespace `default`, застосовує
`charts/django-app` і підтримує `automated sync`, `prune` та `selfHeal`.
Django отримує DB credentials і `SECRET_KEY` через `ExternalSecret`.

Перевірка:

```bash
kubectl get application django-app -n argocd
kubectl get deployment,pods,hpa -n default
kubectl get externalsecret django-app -n default
```

Одразу після Terraform deploy Django може мати `ImagePullBackOff`, оскільки
ECR ще не містить application image. Після налаштування Jenkins і першого
успішного pipeline очікуваний стан: Argo CD `Synced/Healthy`, Django
`2/2 Ready`, ExternalSecret `SecretSynced`.

## Доступ до сервісів

Кожну команду port-forward запускайте в окремому терміналі й не закривайте
його, поки користуєтесь сервісом.

### Jenkins

```bash
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
```

Відкрити `http://localhost:8080`.

### Argo CD

```bash
kubectl port-forward svc/argocd-server 8081:443 -n argocd
```

Відкрити `https://localhost:8081`. Для self-signed certificate підтвердьте
перехід у браузері.

Логін — `admin`. Пароль отримуйте лише локально:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

### Grafana

```bash
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
```

Відкрити `http://localhost:3000`. Якщо порт зайнятий, використайте
`3001:80` та відкрийте `http://localhost:3001`.

Credentials отримуйте лише локально:

```bash
kubectl get secret grafana-admin -n monitoring \
  -o jsonpath='{.data.admin-user}' | base64 -d; echo
kubectl get secret grafana-admin -n monitoring \
  -o jsonpath='{.data.admin-password}' | base64 -d; echo
```

### Django readiness

```bash
kubectl port-forward svc/django-app 8000:80 -n default
```

В іншому терміналі:

```bash
curl -i http://localhost:8000/readyz/
```

Очікувана відповідь — `HTTP/1.1 200 OK`.

Не додавайте команди з decoded passwords до скриншотів.

## Перевірка deployment

```bash
aws sts get-caller-identity
aws eks update-kubeconfig --region eu-central-1 --name devops-final-eks

kubectl get nodes
kubectl get pods -A
kubectl get all -n jenkins
kubectl get all -n argocd
kubectl get all -n monitoring
kubectl get application django-app -n argocd
kubectl get clustersecretstore
kubectl get externalsecrets -A
kubectl get hpa -n default
```

Корисні Terraform outputs:

```bash
terraform output vpc_id
terraform output -raw eks_cluster_name
terraform output -raw ecr_repository_url
terraform output rds_port
terraform output rds_master_user_secret_arn
terraform output jenkins_ecr_push_role_arn
terraform output external_secrets_role_arn
terraform output -raw kubeconfig_command
```

`rds_endpoint` і `rds_reader_endpoint` позначені sensitive. Не публікуйте
їх у screenshots або README.

## Локальний запуск Django

Локальний Docker Compose не пов’язаний з EKS deployment:

```bash
cp .env.example .env
```

Замініть `SECRET_KEY` і `DB_PASSWORD`, потім:

```bash
cd Django
docker compose --env-file ../.env up --build
```

Файл `.env` не комітьте.

## Докази для здачі

Рекомендований набір реальних screenshots, що покриває сервіси й модулі:

1. Terraform bootstrap S3/DynamoDB та root `terraform apply` із
   `Apply complete`.
2. AWS VPC із public/private subnets, NAT Gateway і route tables.
3. EKS у стані `Active`, managed node group та `kubectl get nodes/pods`.
4. RDS/Aurora у стані `Available` і Security Group із port `5432` лише від
   EKS Security Group.
5. ECR repository з immutable image, tag якого дорівнює Git SHA.
6. Jenkins pipeline зі stages та статусом `SUCCESS`.
7. Argo CD application `django-app` зі статусом `Synced/Healthy`.
8. IAM/IRSA roles і service accounts для Jenkins, EBS CSI та External
   Secrets без показу credentials.
9. `ClusterSecretStore` та `ExternalSecret` у стані Ready без secret values.
10. Prometheus pod/targets у стані Running/Up.
11. Grafana dashboard із CPU/memory Kubernetes workloads.
12. metrics-server, `kubectl top pods` і HPA через `kubectl get hpa`.
13. Django `2/2 Ready` та readiness endpoint із `HTTP 200`.

Перед публікацією замаскуйте AWS account ID, tokens, passwords, secret
values і private endpoints. Не додавайте Terraform state, `.env`,
`.deploy.env`, Jenkins credentials або decoded Kubernetes Secrets.

Формат здачі:

- посилання на GitHub repository, гілка `final-project`; перед здачею
  переконайтесь, що вона містить усі актуальні commits із `main`;
- ZIP-архів із назвою `final_DevOps_ПІБ`;
- screenshots deployment без конфіденційних значень.

## Повне видалення AWS resources

Використовуйте той самий AWS profile, що й під час deploy:

```bash
AWS_PROFILE=final-project ./scripts/destroy.sh
```

Скрипт читає `.deploy.env`, перевіряє AWS account і просить ввести:

```text
destroy ACCOUNT_ID
```

Порядок очищення:

1. Terraform backend init.
2. Видалення images з ECR.
3. `terraform destroy` основної інфраструктури.
4. Очищення всіх versions і delete markers у S3 state bucket.
5. Видалення S3 bucket і DynamoDB lock table.

Очищення триває приблизно 20–40 хвилин. Не переривайте процес під час
видалення RDS, EKS, NAT Gateway або VPC. Локальні Homebrew, AWS CLI,
Terraform, kubectl, Helm і Git не видаляються.

Після успішного cleanup перевірте AWS Console, щоб не залишилися платні EKS,
RDS, NAT Gateway або Load Balancer resources.
