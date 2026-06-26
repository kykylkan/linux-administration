# Lesson 7 — Kubernetes (EKS) + ECR + Helm

Розгортання Django-застосунку на AWS EKS за допомогою Terraform та Helm.

## Структура проєкту

```
lesson-7/
├── main.tf
├── backend.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── modules/
│   ├── s3-backend/      # S3 bucket + DynamoDB для стейтів
│   ├── vpc/             # VPC, підмережі, IGW, NAT
│   ├── ecr/             # Elastic Container Registry
│   └── eks/             # EKS кластер + Node Group
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── configmap.yaml
            ├── deployment.yaml
            ├── service.yaml
            ├── hpa.yaml
            └── ingress.yaml  # бонус
```

---

## Передумови

- AWS CLI налаштований (`aws configure`)
- Terraform >= 1.5.0
- kubectl
- Helm >= 3.x
- Docker

---

## Крок 1 — Ініціалізація S3 backend (перший запуск)

> Перший раз backend ще не існує, тому запускаємо без нього:

```bash
cd lesson-7

# Тимчасово закоментувати блок terraform { backend "s3" ... } у backend.tf
terraform init
terraform apply -target=module.s3_backend

# Розкоментувати backend.tf і перенести стейт
terraform init -migrate-state
```

---

## Крок 2 — Розгортання всієї інфраструктури

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

Після успішного apply отримаємо:
- ID нашого VPC
- URL ECR репозиторію
- Назву та endpoint EKS кластера

```bash
terraform output
```

---

## Крок 3 — Налаштування kubectl

```bash
aws eks update-kubeconfig \
  --region eu-central-1 \
  --name django-cluster

# Перевірка
kubectl get nodes
```

---

## Крок 4 — Завантаження Docker-образу до ECR

```bash
# Змінні
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="eu-central-1"
ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/django-app"

# Авторизація
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${ECR_URL}

# Збірка та push образу
docker build -t django-app .
docker tag django-app:latest ${ECR_URL}:latest
docker push ${ECR_URL}:latest
```

---

## Крок 5 — Розгортання через Helm

```bash
# Підставити URL свого ECR репозиторію
ECR_URL=$(terraform output -raw ecr_repository_url)

helm upgrade --install django-app ./charts/django-app \
  --namespace production \
  --create-namespace \
  --set image.repository=${ECR_URL} \
  --set image.tag=latest \
  --wait
```

### Перевірка розгортання

```bash
# Pods
kubectl get pods -n production

# Service (зовнішній IP)
kubectl get svc -n production

# HPA
kubectl get hpa -n production

# ConfigMap
kubectl get configmap -n production
kubectl describe configmap django-app-config -n production

# Логи
kubectl logs -l app=django-app -n production --tail=50
```

---

## Крок 6 — Перевірка застосунку

```bash
# Отримати зовнішній IP LoadBalancer
EXTERNAL_IP=$(kubectl get svc django-app-service -n production \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "App URL: http://${EXTERNAL_IP}"
curl -I http://${EXTERNAL_IP}/health/
```

---

## Бонус — Ingress + TLS (cert-manager)

### Встановлення cert-manager

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

### ClusterIssuer для Let's Encrypt

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your@email.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
EOF
```

### Встановлення NGINX Ingress Controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
```

### Helm з увімкненим Ingress

```bash
helm upgrade --install django-app ./charts/django-app \
  --namespace production \
  --set image.repository=${ECR_URL} \
  --set image.tag=latest \
  --set ingress.enabled=true \
  --set ingress.host=yourdomain.com \
  --set ingress.tls=true \
  --wait
```

---

## Корисні команди

```bash
# Helm статус
helm status django-app -n production

# Helm список релізів
helm list -n production

# Перегляд rendered templates (без деплою)
helm template django-app ./charts/django-app --set image.repository=test

# Видалення релізу
helm uninstall django-app -n production

# Знищення всієї інфраструктури
terraform destroy
```

---

## Змінні середовища (ConfigMap)

Усі env-змінні передаються через `values.yaml` → `ConfigMap` → Deployment (`envFrom`).

| Змінна | Опис |
|--------|------|
| `DEBUG` | Режим відлагодження Django |
| `DJANGO_SETTINGS_MODULE` | Модуль налаштувань |
| `ALLOWED_HOSTS` | Дозволені хости |
| `DATABASE_HOST` | Хост PostgreSQL |
| `DATABASE_PORT` | Порт PostgreSQL |
| `DATABASE_NAME` | Назва БД |
| `DATABASE_USER` | Користувач БД |
| `REDIS_URL` | URL Redis (кеш) |
| `CELERY_BROKER_URL` | URL брокера Celery |

> **Увага:** Секретні значення (паролі, ключі) передавайте через Kubernetes Secret або AWS Secrets Manager, а не через ConfigMap.

---

## HPA — Автомасштабування

HPA налаштований на масштабування від **2 до 6 подів** при навантаженні CPU **> 70%**.

```bash
# Симуляція навантаження для тесту HPA
kubectl run load-test --image=busybox -n production -- \
  sh -c "while true; do wget -q -O- http://django-app-service/; done"

# Спостереження за масштабуванням
kubectl get hpa -n production -w
```
