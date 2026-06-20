# Lesson 5 — Terraform Infrastructure on AWS

This project provisions core AWS infrastructure using Terraform with a modular structure.
It covers remote state management, networking, and container registry setup.

---

## Project Structure

```
lesson-5/
├── main.tf          # Root module — wires all submodules together
├── backend.tf       # Remote state configuration (S3 + DynamoDB)
├── variables.tf     # Root-level variables
├── outputs.tf       # Aggregated outputs from all modules
├── README.md
│
└── modules/
    ├── s3-backend/  # S3 bucket + DynamoDB for state storage & locking
    │   ├── s3.tf
    │   ├── dynamodb.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── vpc/         # VPC with public/private subnets, IGW, NAT Gateway
    │   ├── vpc.tf
    │   ├── routes.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── ecr/         # Elastic Container Registry repository
        ├── ecr.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Modules

### `s3-backend`
Creates an S3 bucket for storing Terraform state files and a DynamoDB table for state locking.

| Resource | Description |
|---|---|
| `aws_s3_bucket` | Versioned, encrypted bucket with public access blocked |
| `aws_dynamodb_table` | PAY_PER_REQUEST table with `LockID` hash key |

**Key features:**
- Versioning enabled — full history of state files
- AES256 server-side encryption
- All public access blocked
- `prevent_destroy` lifecycle guard on the bucket

---

### `vpc`
Creates a VPC with 3 public and 3 private subnets spread across 3 Availability Zones.

| Resource | Description |
|---|---|
| `aws_vpc` | Main VPC with DNS support enabled |
| `aws_subnet` (public ×3) | Auto-assign public IP, one per AZ |
| `aws_subnet` (private ×3) | No public IP, one per AZ |
| `aws_internet_gateway` | Provides internet access for public subnets |
| `aws_eip` | Elastic IP for the NAT Gateway |
| `aws_nat_gateway` | Allows private subnets to reach the internet |
| `aws_route_table` (public) | Routes `0.0.0.0/0` → Internet Gateway |
| `aws_route_table` (private) | Routes `0.0.0.0/0` → NAT Gateway |

---

### `ecr`
Creates an Elastic Container Registry repository for storing Docker images.

| Resource | Description |
|---|---|
| `aws_ecr_repository` | Repository with scan-on-push and AES256 encryption |
| `aws_ecr_lifecycle_policy` | Removes untagged images beyond the last 10 |
| `aws_ecr_repository_policy` | Grants the current AWS account full access |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5.0
- AWS CLI configured (`aws configure`)
- IAM permissions for S3, DynamoDB, VPC, ECR

---

## First-time Bootstrap

> **Important:** The S3 bucket and DynamoDB table used by `backend.tf` must exist **before** you can use them as a backend. On the very first run, comment out `backend.tf`, apply to create the resources, then uncomment and run `terraform init -migrate-state`.

---

## Usage

### Initialize

```bash
terraform init
```

### Preview changes

```bash
terraform plan
```

### Apply infrastructure

```bash
terraform apply
```

### Destroy all resources

```bash
terraform destroy
```

> ⚠️ `terraform destroy` will also delete the S3 bucket and DynamoDB table used for state storage. Back up your state file before destroying if you plan to recreate the infrastructure later.

---

## Outputs

| Output | Description |
|---|---|
| `s3_bucket_name` | Name of the Terraform state S3 bucket |
| `s3_bucket_arn` | ARN of the S3 bucket |
| `dynamodb_table_name` | Name of the DynamoDB lock table |
| `vpc_id` | ID of the created VPC |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `internet_gateway_id` | ID of the Internet Gateway |
| `ecr_repository_url` | Full URL of the ECR repository |
| `ecr_repository_arn` | ARN of the ECR repository |
