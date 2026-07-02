# Terraform-модуль `rds`

Універсальний, багаторазовий Terraform-модуль для створення бази даних у AWS:
залежно від прапора `use_aurora` він піднімає **Aurora Cluster** (writer +
опційні readers) або звичайну **RDS instance** (PostgreSQL / MySQL). В обох
випадках модуль автоматично створює `DB Subnet Group`, `Security Group` і
відповідний `Parameter Group`.

## Структура модуля

```
modules/rds/
├── rds.tf          # standalone aws_db_instance + aws_db_parameter_group (use_aurora = false)
├── aurora.tf       # aws_rds_cluster + aws_rds_cluster_instance + aws_rds_cluster_parameter_group (use_aurora = true)
├── shared.tf        # aws_db_subnet_group, aws_security_group (+ rules), спільні локальні параметри
├── variables.tf      # усі вхідні змінні модуля
└── outputs.tf        # endpoint, reader_endpoint, security_group_id, secret_arn тощо
```

Кореневі файли (`main.tf`, `variables.tf`, `outputs.tf`, `backend.tf`)
демонструють використання модуля одразу у двох варіантах — standalone RDS і
Aurora — в одному стейті, щоб показати перемикання прапора `use_aurora`.

## Приклад використання

```hcl
module "rds_postgres" {
  source = "./modules/rds"

  name       = "cashoomo-rds"
  use_aurora = false                 # -> звичайна RDS instance

  engine                 = "postgres"
  engine_version         = "15.4"
  parameter_group_family = "postgres15"
  instance_class          = "db.t3.medium"
  multi_az                = false

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  allowed_cidr_blocks        = ["10.0.0.0/16"]
  allowed_security_group_ids = [module.eks.node_security_group_id]

  db_port         = 5432
  db_name         = "app_db"
  master_username = "app_admin"
  # master_password не задаємо -> пароль згенерує та керуватиме AWS Secrets Manager

  allocated_storage     = 20
  max_allocated_storage = 100

  db_parameters = {
    max_connections = "200"
  }

  tags = {
    Environment = "dev"
    Project     = "cashoomo"
  }
}
```

Той самий модуль для **Aurora**-кластера — просто інший набір значень:

```hcl
module "rds_aurora" {
  source = "./modules/rds"

  name       = "cashoomo-aurora"
  use_aurora = true                  # -> Aurora Cluster

  engine                  = "aurora-postgresql"
  engine_version          = "15.4"
  parameter_group_family  = "aurora-postgresql15"
  instance_class           = "db.r6g.large"
  aurora_instance_count    = 2        # 1 writer + 1 reader

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  db_name         = "app_db"
  master_username = "app_admin"

  tags = { Environment = "dev" }
}
```

## Як запустити

```bash
cp terraform.tfvars.example terraform.tfvars
# відредагувати vpc_id / subnet_ids / allowed_cidr_blocks під ваше середовище

terraform init
terraform plan
terraform apply
```

⚠️ Після перевірки обов'язково виконайте `terraform destroy`, щоб уникнути
зайвих витрат. Якщо стан (`backend.tf`) вказує на S3 + DynamoDB, видаляйте
інфраструктуру проєкту **до** видалення бакета/таблиці стейту — інакше
втратите доступ до стейту раніше, ніж встигнете прибрати решту ресурсів.

## Як змінити тип БД / engine / клас інстансу

Усі ці параметри — звичайні змінні модуля, нічого правити в `.tf`-файлах не
потрібно:

| Що змінити | Яку змінну задати | Приклад |
|---|---|---|
| RDS ⇄ Aurora | `use_aurora` | `true` / `false` |
| СУБД | `engine` | `postgres`, `mysql`, `aurora-postgresql`, `aurora-mysql` |
| Версія СУБД | `engine_version` | `"15.4"`, `"8.0"` |
| Родина параметр-групи (має відповідати engine/engine_version) | `parameter_group_family` | `"postgres15"`, `"aurora-mysql8.0"` |
| Клас інстансу | `instance_class` | `"db.t3.medium"`, `"db.r6g.large"` |
| Кількість інстансів в Aurora-кластері | `aurora_instance_count` | `2` (1 writer + 1 reader) |
| Multi-AZ (лише для звичайної RDS) | `multi_az` | `true` / `false` |
| Розмір диска (лише RDS) | `allocated_storage`, `max_allocated_storage` | `20`, `100` |
| Порт | `db_port` | `5432` / `3306` |
| Додаткові параметри БД | `db_parameters` | `{ max_connections = "200" }` |
| Доступ до БД | `allowed_cidr_blocks`, `allowed_security_group_ids` | — |
| Захист від видалення / фінальний снепшот | `deletion_protection`, `skip_final_snapshot` | `true`/`false` |

## Опис усіх змінних

| Змінна | Тип | За замовч. | Опис |
|---|---|---|---|
| `name` | `string` | — | Базове ім'я для всіх ресурсів модуля |
| `use_aurora` | `bool` | `false` | `true` → Aurora Cluster, `false` → standalone RDS |
| `engine` | `string` | `"postgres"` | СУБД |
| `engine_version` | `string` | `null` | Версія СУБД |
| `parameter_group_family` | `string` | — | Family для parameter group |
| `instance_class` | `string` | `"db.t3.medium"` | Клас інстансу |
| `multi_az` | `bool` | `false` | Multi-AZ (тільки RDS) |
| `vpc_id` | `string` | — | VPC для security group |
| `subnet_ids` | `list(string)` | — | Підмережі для subnet group |
| `allowed_cidr_blocks` | `list(string)` | `[]` | CIDR з доступом до БД |
| `allowed_security_group_ids` | `list(string)` | `[]` | SG з доступом до БД |
| `db_port` | `number` | `5432` | Порт БД |
| `db_name` | `string` | — | Назва бази даних за замовчуванням |
| `master_username` | `string` | `"app_admin"` | Master-користувач |
| `master_password` | `string` | `null` | Master-пароль (якщо `null` — керує Secrets Manager) |
| `manage_master_user_password` | `bool` | `true` | Автогенерація пароля через Secrets Manager |
| `allocated_storage` | `number` | `20` | Розмір диска, GB (тільки RDS) |
| `max_allocated_storage` | `number` | `100` | Ліміт автомасштабування диска (тільки RDS) |
| `storage_type` | `string` | `"gp3"` | Тип диска (тільки RDS) |
| `aurora_instance_count` | `number` | `1` | Кількість інстансів в Aurora-кластері |
| `backup_retention_period` | `number` | `7` | Днів зберігання бекапів |
| `backup_window` | `string` | `"03:00-04:00"` | Вікно бекапів (UTC) |
| `maintenance_window` | `string` | `"mon:04:30-mon:05:30"` | Вікно обслуговування (UTC) |
| `deletion_protection` | `bool` | `false` | Захист від випадкового видалення |
| `skip_final_snapshot` | `bool` | `true` | Пропустити фінальний снепшот при знищенні |
| `publicly_accessible` | `bool` | `false` | Публічний доступ до БД |
| `db_parameters` | `map(string)` | `{}` | Додаткові параметри поверх дефолтних (`max_connections`, `log_statement`, `work_mem`) |
| `tags` | `map(string)` | `{}` | Спільні теги |

## Outputs модуля

| Output | Опис |
|---|---|
| `endpoint` | Writer endpoint (Aurora) / адреса інстансу (RDS) |
| `reader_endpoint` | Reader endpoint (тільки Aurora, інакше `null`) |
| `port` | Порт БД |
| `security_group_id` | ID security group |
| `db_subnet_group_name` | Ім'я subnet group |
| `database_name` / `master_username` | Назва БД / master-юзер |
| `master_user_secret_arn` | ARN секрету в Secrets Manager (якщо пароль генерується автоматично) |
| `cluster_id` | ID Aurora-кластера (`null` для RDS) |
| `cluster_instance_ids` | Список ID інстансів Aurora-кластера |
| `instance_id` | ID RDS instance (`null` для Aurora) |
