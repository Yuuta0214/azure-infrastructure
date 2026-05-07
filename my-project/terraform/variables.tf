# ==========================================
# 14. リージョンの定義
# ==========================================
variable "location" {
  description = "リソースを配置するリージョン"
  type        = string
  default     = "japanwest" # ログの japanwest に合わせます
}

# ==========================================
# 15. プロジェクト名の定義
# ==========================================
variable "project_name" {
  description = "プロジェクトの基本名称"
  type        = string
  default     = "web" # ログの「rg-web-test」に合わせて「web-project」から「web」に変更

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "プロジェクト名は英小文字、数字、ハイフンのみ使用可能です。"
  }
}

# ==========================================
# 16. 実行環境の定義
# ==========================================
variable "environment" { # 変数名を env から environment に修正し、Actions側と統一
  description = "実行環境 (prod または test)"
  type        = string
  default     = "test"

  validation {
    condition     = contains(["prod", "test"], var.environment)
    error_message = "環境名は 'prod' または 'test' のいずれかを指定してください。"
  }
}

# ==========================================
# 17. VMサイズの定義
# ==========================================
variable "vm_size" {
  description = "VMのサイズ（SKU）"
  type        = string
  default     = "Standard_B2s"
}

# ==========================================
# 18. 管理ユーザー名の定義
# ==========================================
variable "admin_username" {
  description = "VMの管理者ユーザー名"
  type        = string
  default     = "azureuser"

  validation {
    condition     = !contains(["admin", "root", "test", "user", "azure", "administrator"], var.admin_username)
    error_message = "セキュリティおよびAzureの制限により 'admin', 'root', 'test', 'user', 'azure' 等はユーザー名に使用できません。"
  }
}

# ==========================================
# 19. パスワードの定義
# ==========================================
variable "admin_password" {
  description = "VMの管理者パスワード"
  type        = string
  sensitive   = true
  default     = null 
}

# ==========================================
# 20. SSH公開鍵の定義
# ==========================================
variable "ssh_public_key" {
  description = "VMに接続するためのSSH公開鍵"
  type        = string
  default     = ""
}

# ==========================================
# 21. 追加タグ
# ==========================================
variable "tags" {
  description = "すべてのリソースに付与する追加のタグ"
  type        = map(string)
  default     = {}
}