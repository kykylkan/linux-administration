#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEPLOY_ENV_FILE="${PROJECT_DIR}/.deploy.env"

handle_error() {
  echo
  echo "Очищення зупинилося на рядку $1."
  echo "Не запускайте видалення backend вручну, доки Terraform infrastructure destroy не завершився."
}

trap 'handle_error $LINENO' ERR

require_command() {
  local command_name="$1"

  if command -v "${command_name}" >/dev/null 2>&1; then
    return
  fi

  echo "Не знайдено ${command_name}. Спочатку встановіть цей інструмент."
  exit 1
}

load_deployment_info() {
  if [[ ! -f "${DEPLOY_ENV_FILE}" ]]; then
    echo "Не знайдено ${DEPLOY_ENV_FILE}."
    echo "Цей файл створюється scripts/deploy.sh і містить назви Terraform backend resources."
    exit 1
  fi

  # shellcheck disable=SC1090
  source "${DEPLOY_ENV_FILE}"

  AWS_REGION="${AWS_REGION:-eu-central-1}"
  export AWS_PROFILE="${AWS_PROFILE:-final-project}"

  if [[ -z "${AWS_ACCOUNT_ID:-}" || -z "${STATE_BUCKET_NAME:-}" || -z "${LOCK_TABLE_NAME:-}" ]]; then
    echo "${DEPLOY_ENV_FILE} не містить усіх необхідних параметрів."
    exit 1
  fi
}

verify_aws_account() {
  local current_account_id

  current_account_id="$(aws sts get-caller-identity --query Account --output text)"
  if [[ "${current_account_id}" == "${AWS_ACCOUNT_ID}" ]]; then
    return
  fi

  echo "Відмова: активний AWS account ${current_account_id}, але deployment належить ${AWS_ACCOUNT_ID}."
  echo "Перевірте AWS_PROFILE і повторіть запуск."
  exit 1
}

confirm_destroy() {
  local confirmation
  local expected_confirmation="destroy ${AWS_ACCOUNT_ID}"

  echo
  echo "УВАГА: буде безповоротно видалено інфраструктуру проєкту:"
  echo "  AWS profile: ${AWS_PROFILE}"
  echo "  AWS account: ${AWS_ACCOUNT_ID}"
  echo "  Region: ${AWS_REGION}"
  echo "  State bucket: ${STATE_BUCKET_NAME}"
  echo "  Lock table: ${LOCK_TABLE_NAME}"
  echo
  read -r -p "Для підтвердження введіть '${expected_confirmation}': " confirmation

  if [[ "${confirmation}" == "${expected_confirmation}" ]]; then
    return
  fi

  echo "Підтвердження не збігається. Нічого не видалено."
  exit 0
}

empty_ecr_repository() {
  local repository_url
  local repository_name
  local image_ids

  repository_url="$(terraform -chdir="${PROJECT_DIR}" output -raw ecr_repository_url 2>/dev/null || true)"
  repository_name="${repository_url##*/}"

  if [[ -z "${repository_name}" ]]; then
    echo "ECR repository output відсутній, пропускаю попереднє очищення images."
    return
  fi

  if ! aws ecr describe-repositories \
    --region "${AWS_REGION}" \
    --repository-names "${repository_name}" >/dev/null 2>&1; then
    return
  fi

  image_ids="$(aws ecr list-images \
    --region "${AWS_REGION}" \
    --repository-name "${repository_name}" \
    --query imageIds \
    --output json)"

  if [[ "${image_ids}" == "[]" ]]; then
    return
  fi

  echo "Видаляю ECR images із ${repository_name}."
  aws ecr batch-delete-image \
    --region "${AWS_REGION}" \
    --repository-name "${repository_name}" \
    --image-ids "${image_ids}" >/dev/null
}

destroy_infrastructure() {
  echo
  echo "Ініціалізую Terraform backend."
  terraform -chdir="${PROJECT_DIR}" init -reconfigure \
    -backend-config="bucket=${STATE_BUCKET_NAME}" \
    -backend-config="dynamodb_table=${LOCK_TABLE_NAME}" \
    -backend-config="region=${AWS_REGION}"

  empty_ecr_repository

  echo
  echo "Видаляю Kubernetes та AWS infrastructure. Це може тривати 20-40 хвилин."
  terraform -chdir="${PROJECT_DIR}" destroy -auto-approve \
    -var="aws_region=${AWS_REGION}" \
    -var="argocd_repo_url=${REPOSITORY_URL}"
}

empty_state_bucket() {
  local versions_json
  local delete_payload
  local attempt

  if ! aws s3api head-bucket --bucket "${STATE_BUCKET_NAME}" >/dev/null 2>&1; then
    return
  fi

  echo "Очищаю всі versions і delete markers у ${STATE_BUCKET_NAME}."
  for ((attempt = 1; attempt <= 100; attempt++)); do
    versions_json="$(aws s3api list-object-versions \
      --bucket "${STATE_BUCKET_NAME}" \
      --max-items 1000 \
      --output json)"

    delete_payload="$(python3 -c '
import json
import sys

data = json.load(sys.stdin)
objects = [
    {"Key": item["Key"], "VersionId": item["VersionId"]}
    for group in ("Versions", "DeleteMarkers")
    for item in (data.get(group) or [])
]

if objects:
    print(json.dumps({"Objects": objects[:1000], "Quiet": True}, separators=(",", ":")))
' <<<"${versions_json}")"

    if [[ -z "${delete_payload}" ]]; then
      return
    fi

    aws s3api delete-objects \
      --bucket "${STATE_BUCKET_NAME}" \
      --delete "${delete_payload}" >/dev/null
  done

  echo "Не вдалося повністю очистити S3 bucket за 100 операцій."
  exit 1
}

destroy_backend() {
  echo
  echo "Основна інфраструктура видалена. Тепер видаляю Terraform backend."

  empty_state_bucket

  if aws s3api head-bucket --bucket "${STATE_BUCKET_NAME}" >/dev/null 2>&1; then
    aws s3api delete-bucket \
      --bucket "${STATE_BUCKET_NAME}" \
      --region "${AWS_REGION}"
    aws s3api wait bucket-not-exists --bucket "${STATE_BUCKET_NAME}"
  fi

  if aws dynamodb describe-table \
    --region "${AWS_REGION}" \
    --table-name "${LOCK_TABLE_NAME}" >/dev/null 2>&1; then
    aws dynamodb delete-table \
      --region "${AWS_REGION}" \
      --table-name "${LOCK_TABLE_NAME}" >/dev/null
    aws dynamodb wait table-not-exists \
      --region "${AWS_REGION}" \
      --table-name "${LOCK_TABLE_NAME}"
  fi

  terraform -chdir="${PROJECT_DIR}/bootstrap" state rm 'module.s3_backend' >/dev/null 2>&1 || true
}

print_result() {
  echo
  echo "Очищення завершено."
  echo "Terraform infrastructure, ECR images, S3 state bucket і DynamoDB lock table видалені."
  echo "Локальні AWS CLI, Terraform, kubectl, Helm і Homebrew не видалялися."
}

main() {
  require_command aws
  require_command terraform
  require_command python3
  load_deployment_info
  verify_aws_account
  confirm_destroy
  destroy_infrastructure
  destroy_backend
  print_result
}

main "$@"
