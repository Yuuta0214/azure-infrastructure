# ==========================================
# 1. リージョンの定義
# ==========================================
variable "location" {
  description = "リソースを配置するリージョン"
  type        = string
  default     = "japaneast" # Azureの内部名（スペースなし小文字）を使用するのがベストプラクティスです
}

# ==========================================
# 2. プロジェクト名の定義（リソース名のベース）
# ==========================================
variable "project_name" {
  description = "プロジェクトの基本名称（英小文字、数字、ハイフンのみ）"
  type        = string
  default     = "web-project"

  # 【追加】Azureの命名規則エラーを未然に防ぐためのチェック
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "プロジェクト名は英小文字、数字、ハイフンのみ使用可能です。"
  }
}

# ==========================================
# 3. 実行環境の定義（本番：prod / 検証：test）
# ==========================================
variable "env" {
  description = "実行環境 (prod または test)"
  type        = string
  default     = "test"

  # 【追加】タイポによる意図しない環境の作成を防ぐ
  validation {
    condition     = contains(["prod", "test"], var.env)
    error_message = "環境名は 'prod' または 'test' のいずれかを指定してください。"
  }
}

# ==========================================
# 4. VMサイズの定義
# ==========================================
variable "vm_size" {
  description = "VMのサイズ（SKU）"
  type        = string
  default     = "Standard_B2s"
}

# ==========================================
# 5. 管理ユーザー名の定義
# ==========================================
variable "admin_username" {
  description = "VMの管理者ユーザー名"
  type        = string
  default     = "azureuser"

  # 【追加】Azureで禁止されているユーザー名を事前に弾く
  validation {
    condition     = var.admin_username != "admin" && var.admin_username != "root"
    error_message = "Azureの仕様上、'admin' や 'root' はユーザー名として使用できません。"
  }
}

# ==========================================
# 6. パスワードの定義（機密情報）
# ==========================================
variable "admin_password" {
  description = "VMの管理者パスワード（※12文字以上、大文字・小文字・数字・特殊文字のうち3種類を含むこと）"
  type        = string
  sensitive   = true
  # ※注意: Azureのパスワード複雑性要件を満たしていないとデプロイに失敗します。
}

# ==========================================
# 7. SSH公開鍵の定義（OSベストプラクティスとして追加）
# ==========================================
variable "ssh_public_key" {
  description = "VMに接続するためのSSH公開鍵（パスワード認証の代わりに使用を強く推奨）"
  type        = string
  default     = "" 
}