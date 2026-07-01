# Lesson 8-9: Jenkins + Terraform + Helm + Argo CD — повний CI/CD пайплайн

Проєкт реалізує наскрізний CI/CD-процес для Django-застосунку на AWS EKS:

```
Developer push → GitHub (app repo) → Jenkins (Kaniko build) → Amazon ECR
        → Jenkins оновлює values.yaml у GitOps-репозиторії (git push)
        → Argo CD виявляє зміну → автоматичний sync → Kubernetes (EKS)
```

## Схема CI/CD

```
┌─────────────┐   push   ┌────────────┐   webhook   ┌───────────────────┐
│  App repo    │ ───────▶ │  GitHub    │ ──────────▶ │      Jenkins       │
│ (Dockerfile) │          │            │             │  (Kubernetes agent │
└─────────────┘          └────────────┘             │   Kaniko + Git)    │
                                                       └─────────┬──────────┘
                                                                 │ docker build & push
                                                                 ▼
                                                       ┌───────────────────┐
                                                       │   Amazon ECR       │
                                                       └─────────┬──────────┘
                                                                 │ update image.tag
                                                                 ▼
                                                       ┌───────────────────┐
                                                       │  GitOps repo       │
                                                       │  charts/django-app │
                                                       │  values.yaml       │
                                                       └─────────┬──────────┘
                                                                 │ git sync (auto)
                                                                 ▼
                                                       ┌───────────────────┐
                                                       │     Argo CD        │
                                                       │  Application CR    │
                                                       └─────────┬──────────┘
                                                                 │ helm upgrade
                                                                 ▼
                                                       ┌───────────────────┐
                                                       │   EKS (django-app) │
                                                       └───────────────────┘
```

## Структура проєкту

```
Progect/
├── main.tf, backend.tf, variables.tf, outputs.tf, versions.tf
├── Dockerfile               # приклад Dockerfile Django-застосунку
├── Jenkinsfile               # CI pipeline: build → push ECR → update GitOps repo
├── modules/
│   ├── s3-backend/          # S3 + DynamoDB для стану Terraform
│   ├── vpc/                 # VPC, підмережі, NAT/IGW, роутинг
│   ├── ecr/                 # ECR репозиторій для django-app
│   ├── eks/                 # EKS кластер, node group, OIDC, EBS CSI driver
│   ├── jenkins/              # Helm-реліз Jenkins + Kubernetes-агент (Kaniko)
│   └── argo_cd/              # Helm-реліз Argo CD + Application/Repository chart
└── charts/
    └── django-app/           # Helm chart застосунку, за яким слідкує Argo CD
```

## Передумови

- Terraform >= 1.5, AWS CLI, kubectl, helm
- AWS-акаунт з правами на VPC/EKS/ECR/IAM/S3/DynamoDB
- Git-репозиторій "GitOps" (окремий від репозиторію застосунку), що містить
  каталог `charts/django-app` — саме за ним стежить Argo CD Application
  (`var.git_repo_url` у `variables.tf`, за замовчуванням заглушка
  `https://github.com/<your-account>/lesson-8-9-gitops.git` — замініть на свій)
- Jenkins credential `gitops-repo-credentials` (username + PAT токен) для push
  у GitOps-репозиторій — додається вручну в Jenkins UI (Manage Credentials)
  після першого деплою Jenkins

## Як застосувати Terraform

### 1. Bootstrap стану (S3 + DynamoDB) — один раз

```bash
# Тимчасово закоментуйте блок backend "s3" у backend.tf
terraform init
terraform apply -target=module.s3_backend
```

### 2. Міграція на віддалений backend

```bash
# Розкоментуйте backend "s3" у backend.tf
terraform init -migrate-state
```

### 3. Розгортання решти інфраструктури

```bash
terraform plan
terraform apply
```

Це створить (у порядку залежностей): VPC → ECR → EKS (кластер + node group +
OIDC + EBS CSI addon) → Jenkins (Helm) → Argo CD (Helm) + Argo CD Application.

### 4. Підключення kubectl до кластера

```bash
aws eks update-kubeconfig --name lesson-8-9 --region eu-central-1
kubectl get nodes
```

## Як перевірити Jenkins job

1. Отримати пароль адміністратора Jenkins:

   ```bash
   kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- \
     /bin/cat /run/secrets/additional/chart-admin-password
   ```

2. Прокинути порт і відкрити UI:

   ```bash
   kubectl port-forward svc/jenkins 8080:8080 -n jenkins
   # http://localhost:8080  (user: admin)
   ```

3. Створити Pipeline job, що вказує на репозиторій із застосунком і
   `Jenkinsfile` в корені. Додати credential `gitops-repo-credentials`
   (Manage Jenkins → Credentials) для push у GitOps-репозиторій.

4. Запустити білд і переконатись, що всі стадії пройшли успішно:
   `Checkout` → `Build & Push image (Kaniko)` → `Update GitOps repo`.

5. Перевірити, що в ECR з'явився новий тег образу:

   ```bash
   aws ecr describe-images --repository-name django-app --region eu-central-1
   ```

6. Перевірити, що в GitOps-репозиторії з'явився commit з оновленим
   `image.tag` у `charts/django-app/values.yaml`.

## Як побачити результат в Argo CD

1. Отримати початковий пароль адміністратора:

   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret \
     -o jsonpath='{.data.password}' | base64 -d
   ```

2. Прокинути порт і відкрити UI:

   ```bash
   kubectl port-forward svc/argocd-server 8081:80 -n argocd
   # https://localhost:8081  (user: admin)
   ```

3. У списку Applications знайти `django-app` — Argo CD автоматично виявляє
   комміт від Jenkins (polling кожні ~3 хв, або миттєво через webhook) і
   виконує `Sync` (auto-sync увімкнено: `prune: true`, `selfHeal: true`).

4. Перевірити стан подів застосунку:

   ```bash
   kubectl get pods -n django-app
   kubectl get deployment -n django-app -o wide
   ```

   Образ у деплойменті повинен відповідати останньому тегу, запушеному
   Jenkins-пайплайном.

## ⚠️ Видалення ресурсів після перевірки

```bash
terraform destroy
```

**Порядок відновлення після повного destroy**: оскільки `terraform destroy`
видаляє також S3-бакет і DynamoDB-таблицю зі стейтом, для наступного
розгортання потрібно повторити крок **bootstrap** (п.1) заново.
