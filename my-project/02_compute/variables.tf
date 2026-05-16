# ==========================================
# 02_compute / variables.tf
# ==========================================

# ==========================================
# 1. 基盤・環境定義 (01_network層との整合性)
# ==========================================
variable "location" {
  description = "リソースを配置するリージョン (01_networkと一致させること)"
  type        = string
}

variable "environment" {
  description = "実行環境 (prod または dev)"
  type        = string

  validation {
    condition     = contains(["prod", "dev"], var.environment)
    error_message = "環境名は 'prod' または 'dev' のいずれかを指定してください。"
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

# 【整合性修正】01_network で作成済みのリソースグループ名を受け取るために定義
# compute.tf 内の azurerm_network_interface 等で参照されます
variable "resource_group_name" {
  description = "01_network層で作成された既存のリソースグループ名"
  type        = string
}

# ==========================================
# 2. コンピューティング定義 (VMスペック)
# ==========================================
variable "vm_size" {
  description = "VMのサイズ（SKU）"
  type        = string
}

# ==========================================
# 3. ネットワーク参照定義 (01_network層との整合性)
# ==========================================
# network層の outputs.tf (backend_subnet_id) から渡される値を受け取ります
variable "subnet_id" {
  description = "VMを配置するサブネットのリソースID"
  type        = string
}

# network層の outputs.tf (lb_backend_pool_id) から渡される値を受け取ります
variable "lb_backend_pool_id" {
  description = "Load BalancerのバックエンドプールID"
  type        = string
}

# ==========================================
# 4. 認証・セキュリティ定義
# ==========================================
variable "admin_username" {
  description = "VMの管理者ユーザー名"
  type        = string

  # セキュリティ・ベストプラクティス：推測されやすい名前を禁止
  validation {
    condition     = !contains(["admin", "root", "dev", "user", "azure", "administrator"], var.admin_username)
    error_message = "セキュリティおよびAzureの制限により、これら特定の名称はユーザー名に使用できません。"
  }
}

variable "admin_password" {
  description = "VMの管理者パスワード"
  type        = string
  sensitive   = true # ログ出力防止

  # セキュリティ・ベストプラクティス：Azureの複雑性要件および12文字以上の長さを強制
  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "Azureのポリシーにより、パスワードは12文字以上である必要があります。"
  }
}

# ==========================================
# 5. メタデータ定義 (運用管理用)
# ==========================================
variable "tags" {
  description = "リソースに付与する追加のカスタムタグ"
  type        = map(string)
  default     = {}
}