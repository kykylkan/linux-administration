#!/usr/bin/env bash

set -Eeuo pipefail

AWS_REGION="${AWS_REGION:-eu-central-1}"
PROJECT_NAME="${PROJECT_NAME:-devops-final}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

handle_error() {
  echo
  echo "Помилка на рядку $1. Деплой зупинено."
  echo "Скопіюйте останні 20-30 рядків термінала, якщо потрібна допомога."
}

trap 'handle_error $LINENO' ERR

prompt_yes_no() {
  local prompt="$1"
  local answer

  read -r -p "${prompt} [y/N]: " answer
  [[ "${answer}" =~ ^[Yy]$ ]]
}

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  echo "Homebrew не знайдено."
  if ! prompt_yes_no "Встановити Homebrew з офіційного install-скрипта?"; then
    echo "Встановіть Homebrew: https://brew.sh"
    exit 1
  fi

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_tools() {
  local packages=()

  command -v aws >/dev/null 2>&1 || packages+=("awscli")
  command -v kubectl >/dev/null 2>&1 || packages+=("kubectl")
  command -v helm >/dev/null 2>&1 || packages+=("helm")

  if ((${#packages[@]} > 0)); then
    echo "Встановлюю: ${packages[*]}"
    brew install "${packages[@]}"
  fi

  if ! command -v terraform >/dev/null 2>&1; then
    echo "Встановлюю Terraform."
    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform
  fi
}

configure_aws() {
  local session_token

  if aws sts get-caller-identity >/dev/null 2>&1; then
    return
  fi

  echo
  echo "AWS credentials не налаштовані."
  echo "Зараз AWS CLI попросить:"
  echo "  1. AWS Access Key ID"
  echo "  2. AWS Secret Access Key"
  echo "  3. Default region: ${AWS_REGION}"
  echo "  4. Output format: json"
  echo
  aws configure
  echo
  read -r -s -p "AWS Session Token (для AWS Academy; Enter якщо його немає): " session_token
  echo
  if [[ -n "${session_token}" ]]; then
    aws configure set aws_session_token "${session_token}"
  fi

  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "AWS не прийняв credentials. Перевірте ключі та повторіть запуск."
    exit 1
  fi
}

detect_repository_url() {
  local remote_url

  remote_url="$(git -C "${PROJECT_DIR}" remote get-url origin 2>/dev/null || true)"
  if [[ "${remote_url}" =~ ^git@github.com:(.+)$ ]]; then
    remote_url="https://github.com/${BASH_REMATCH[1]}"
  fi

  read -r -p "URL публічного GitHub repository [${remote_url}]: " REPOSITORY_URL
  REPOSITORY_URL="${REPOSITORY_URL:-${remote_url}}"

  if [[ ! "${REPOSITORY_URL}" =~ ^https://github\.com/[^/]+/[^/]+(\.git)?$ ]]; then
    echo "Очікується URL виду https://github.com/USERNAME/REPOSITORY.git"
    exit 1
  fi
}

deploy_backend() {
  echo
  echo "Створюю S3 backend: ${STATE_BUCKET_NAME}"
  terraform -chdir="${PROJECT_DIR}/bootstrap" init
  terraform -chdir="${PROJECT_DIR}/bootstrap" apply -auto-approve \
    -var="aws_region=${AWS_REGION}" \
    -var="state_bucket_name=${STATE_BUCKET_NAME}" \
    -var="lock_table_name=${LOCK_TABLE_NAME}"
}

deploy_infrastructure() {
  echo
  echo "Ініціалізую основний Terraform state."
  terraform -chdir="${PROJECT_DIR}" init -reconfigure \
    -backend-config="bucket=${STATE_BUCKET_NAME}" \
    -backend-config="dynamodb_table=${LOCK_TABLE_NAME}" \
    -backend-config="region=${AWS_REGION}"

  echo
  echo "Створюю EKS access entry для поточного AWS-користувача."
  terraform -chdir="${PROJECT_DIR}" apply -auto-approve \
    -target="module.eks.aws_eks_access_policy_association.terraform_admin" \
    -var="aws_region=${AWS_REGION}" \
    -var="argocd_repo_url=${REPOSITORY_URL}"

  echo
  echo "Створюю AWS інфраструктуру. Це може тривати 25-45 хвилин."
  terraform -chdir="${PROJECT_DIR}" apply -auto-approve \
    -var="aws_region=${AWS_REGION}" \
    -var="argocd_repo_url=${REPOSITORY_URL}"
}

configure_kubectl() {
  local cluster_name

  cluster_name="$(terraform -chdir="${PROJECT_DIR}" output -raw eks_cluster_name)"
  aws eks update-kubeconfig --region "${AWS_REGION}" --name "${cluster_name}"

  echo
  echo "Очікую готовність EKS nodes."
  kubectl wait --for=condition=Ready nodes --all --timeout=10m
}

save_deployment_info() {
  cat >"${PROJECT_DIR}/.deploy.env" <<EOF
AWS_REGION=${AWS_REGION}
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}
STATE_BUCKET_NAME=${STATE_BUCKET_NAME}
LOCK_TABLE_NAME=${LOCK_TABLE_NAME}
REPOSITORY_URL=${REPOSITORY_URL}
EOF
}

print_result() {
  echo
  echo "Деплой завершено."
  echo
  kubectl get nodes
  kubectl get pods -A
  echo
  echo "Наступний ручний крок: налаштувати Jenkins."
  echo "Інструкція є в README.md у розділі Jenkins."
  echo
  echo "Jenkins:"
  echo "  kubectl port-forward svc/jenkins 8080:8080 -n jenkins"
  echo
  echo "Argo CD:"
  echo "  kubectl port-forward svc/argocd-server 8081:443 -n argocd"
  echo
  echo "Grafana:"
  echo "  kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring"
  echo
  echo "Перелік скриншотів: docs/deploy-evidence/README.md"
}

main() {
  cd "${PROJECT_DIR}"

  echo "Автоматичний деплой DevOps Final Project"
  echo "Увага: EKS, NAT Gateway і RDS створюють платні AWS-ресурси."
  if ! prompt_yes_no "Продовжити?"; then
    exit 0
  fi

  install_homebrew
  install_tools
  configure_aws
  detect_repository_url

  AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
  STATE_BUCKET_NAME="${PROJECT_NAME}-${AWS_ACCOUNT_ID}-tfstate"
  LOCK_TABLE_NAME="${PROJECT_NAME}-${AWS_ACCOUNT_ID}-tf-lock"

  echo
  echo "AWS account: ${AWS_ACCOUNT_ID}"
  echo "Region: ${AWS_REGION}"
  echo "GitHub: ${REPOSITORY_URL}"
  echo "State bucket: ${STATE_BUCKET_NAME}"
  echo
  if ! prompt_yes_no "Створити інфраструктуру з цими параметрами?"; then
    exit 0
  fi

  deploy_backend
  deploy_infrastructure
  configure_kubectl
  save_deployment_info
  print_result
}

main "$@"
