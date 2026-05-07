# ==========================================
# 1. 基盤・環境定義
# ==========================================
variable "location" {
  description = "リソースを配置するリージョン"
  type        = string
  # defaultは設定せず、tfvarsでの指定を必須にします
}

variable "environment" {
  description = "実行環境 (prod または test)"
  type        = string

  validation {
    condition     = contains(["prod", "test"], var.environment)
    error_message = "環境名は 'prod' または 'test' のいずれかを指定してください。"
  }
}

variable "project_name" {
  description = "プロジェクトの基本名称"
  type        = string
  default     = "web"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "プロジェクト名は英小文字、数字、ハイフンのみ使用可能です。"
  }
}

# ==========================================
# 2. コンピューティング定義 (VMスペック)
# ==========================================
variable "vm_size" {
  description = "VMのサイズ（SKU）"
  type        = string
  # リージョンごとの在庫（SkuNotAvailable）に柔軟に対応するため、tfvarsで明示させます
}

# ==========================================
# 3. 認証・セキュリティ定義
# ==========================================
variable "admin_username" {
  description = "VMの管理者ユーザー名"
  type        = string

  validation {
    condition     = !contains(["admin", "root", "test", "user", "azure", "administrator"], var.admin_username)
    error_message = "セキュリティおよびAzureの制限により、これら特定の名称はユーザー名に使用できません。"
  }
}

variable "admin_password" {
  description = "VMの管理者パスワード"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "Azureのポリシーにより、パスワードは12文字以上である必要があります。"
  }
}

variable "ssh_public_key" {
  description = "VMに接続するためのSSH公開鍵（パスワード認証使用時は空文字を指定可能）"
  type        = string
  default     = ""
}

# ==========================================
# 4. メタデータ定義 (運用管理用)
# ==========================================
variable "tags" {
  description = "すべてのリソースに付与する共通タグ（BusinessUnit, Project等）"
  type        = map(string)
  default     = {
    ManagedBy = "Terraform"
  }
}