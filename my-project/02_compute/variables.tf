# ==========================================
# 1. 基盤・環境定義
# ==========================================
variable "location" {
  description = "リソースを配置するリージョン"
  type        = string
  # 【整合性確認】01_network側のリソースグループ等の配置場所と一致させる必要があります
}

variable "environment" {
  description = "実行環境 (prod または dev)"
  type        = string

  # 【バリデーション】env-dev.tfvars / env-prod.tfvars の構成と一致させています
  validation {
    condition     = contains(["prod", "dev"], var.environment)
    error_message = "環境名は 'prod' または 'dev' のいずれかを指定してください。"
  }
}

variable "project_name" {
  description = "プロジェクトの基本名称"
  type        = string
  default     = "web"

  # 【命名規則】Azureリソース名の制限（英小文字・数字・ハイフン）に準拠させています
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "プロジェクト名は英小文字、数字、ハイフンのみ使用可能です。
  }
}

# ==========================================
# 2. コンピューティング定義 (VMスペック)
# ==========================================
variable "vm_size" {
  description = "VMのサイズ（SKU）"
  type        = string
}

# ==========================================
# 3. 認証・セキュリティ定義
# ==========================================
variable "admin_username" {
  description = "VMの管理者ユーザー名"
  type        = string

  # 【セキュリティ】Azure Linux VM で予約されている、または推測されやすい名称を排除しています
  validation {
    condition     = !contains(["admin", "root", "dev", "user", "azure", "administrator"], var.admin_username)
    error_message = "セキュリティおよびAzureの制限により、これら特定の名称はユーザー名に使用できません。"
  }
}

variable "admin_password" {
  description = "VMの管理者パスワード"
  type        = string
  sensitive   = true # 【秘匿情報】実行ログにパスワードが表示されないよう保護しています

  # 【セキュリティ】Azureの最小要件（12文字以上）を満たすよう制限しています
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
}

# ==========================================
# 5. ネットワーク参照用変数 (不整合修正)
# ==========================================
# 【整合性】01_network層で作成されたリソースをcompute層で利用するための変数定義
variable "subnet_id" {
  description = "01_networkで作成されたサブネットのリソースID"
  type        = string
}

variable "lb_backend_pool_id" {
  description = "01_networkで作成されたLoad BalancerバックエンドプールのリソースID"
  type        = string
}