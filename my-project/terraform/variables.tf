# ==========================================
# 14. リージョンの定義
# ==========================================
variable "location" {
  description = "リソースを配置するリージョン"
  type        = string
  default     = "japaneast" # 東日本
}

# ==========================================
# 15. プロジェクト名の定義
# ==========================================
variable "project_name" {
  description = "プロジェクトの基本名称（英小文字、数字、ハイフンのみ）"
  type        = string
  default     = "web-project"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "プロジェクト名は英小文字、数字、ハイフンのみ使用可能です。"
  }
}

# ==========================================
# 16. 実行環境の定義（prod / test）
# ==========================================
variable "env" {
  description = "実行環境 (prod または test)"
  type        = string
  default     = "test"

  validation {
    condition     = contains(["prod", "test"], var.env)
    error_message = "環境名は 'prod' または 'test' のいずれかを指定してください。"
  }
}

# ==========================================
# 17. VMサイズの定義
# ==========================================
variable "vm_size" {
  description = "VMのサイズ（SKU）"
  type        = string
  default     = "Standard_B2s" # コスト効率の良いバースト対応インスタンス
}

# ==========================================
# 18. 管理ユーザー名の定義
# ==========================================
variable "admin_username" {
  description = "VMの管理者ユーザー名"
  type        = string
  default     = "azureuser"

  validation {
    condition     = !contains(["admin", "root", "test", "user"], var.admin_username)
    error_message = "Azureの制限により 'admin', 'root', 'test', 'user' 等はユーザー名に使用できません。"
  }
}

# ==========================================
# 19. パスワードの定義（機密情報）
# ==========================================
variable "admin_password" {
  description = "VMの管理者パスワード（12文字以上、複雑性要件必須）"
  type        = string
  sensitive   = true
  default     = null # tfvars または 環境変数からの入力を推奨
}

# ==========================================
# 20. SSH公開鍵の定義
# ==========================================
variable "ssh_public_key" {
  description = "VMに接続するためのSSH公開鍵（パスワードより優先されます）"
  type        = string
  default     = ""
}

# ==========================================
# 21. 追加タグ（任意）
# ==========================================
variable "tags" {
  description = "すべてのリソースに付与する追加のタグ（main.tfのlocal.common_tagsとマージ用）"
  type        = map(string)
  default     = {}
}