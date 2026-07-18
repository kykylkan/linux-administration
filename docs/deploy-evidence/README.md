# Deployment evidence checklist

Додайте сюди реальні скриншоти після `terraform apply`. Перед публікацією
замаскуйте AWS account ID, токени, паролі, secret values і приватні URL.

1. `01-terraform-apply.png` — завершений `terraform apply` без помилок.
2. `02-vpc-subnets.png` — VPC, public/private subnets, NAT і route tables.
3. `03-eks-cluster.png` — EKS cluster у стані Active та managed node group.
4. `04-kubectl-workloads.png` — результат:
   ```bash
   kubectl get nodes
   kubectl get pods -A
   ```
5. `05-rds.png` — RDS/Aurora Available, private access, encryption і
   parameter group.
6. `06-rds-security-group.png` — ingress 5432 тільки з EKS cluster/node SG.
7. `07-ecr-images.png` — ECR repository з immutable commit SHA image tag.
8. `08-irsa.png` — IAM roles для Jenkins ECR push, EBS CSI та External
   Secrets; trust policy має відповідні Kubernetes service accounts.
9. `09-external-secrets.png` — синхронізація без показу значень:
   ```bash
   kubectl get clustersecretstore
   kubectl get externalsecrets -A
   kubectl get secret django-app-secret -o jsonpath='{.metadata.name}'
   ```
10. `10-jenkins-success.png` — stages Test, Build, Push і GitOps update зі
    статусом Success.
11. `11-argocd.png` — application `django-app` у стані Synced/Healthy.
12. `12-django-readiness.png` — відповідь readiness endpoint:
    ```bash
    kubectl port-forward svc/django-app 8000:80
    curl -i http://localhost:8000/readyz/
    ```
13. `13-grafana.png` — Grafana dashboard із CPU/memory для pod-ів.
14. `14-hpa.png` — HPA і масштабування:
    ```bash
    kubectl get hpa
    kubectl get deployment,pods
    ```

Не додавайте скриншоти `terraform.tfstate`, decoded Kubernetes Secrets,
Jenkins credential values або AWS Secrets Manager secret values.
