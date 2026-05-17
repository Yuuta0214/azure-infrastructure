# ==========================================
# 1. 基盤・環境定義
# ==========================================
# リソースをデプロイする物理的な場所（例: japaneast）
variable "location" {
  description = "リソースを配置するリージョン"
  type        = string
}

# 本番・開発を識別し、リソース名やバリデーションに使用
variable "environment" {
  description = "実行環境 (prod または dev)"
  type        = string

  # 許容値の制限: 01_network と整合
  validation {
    condition     = contains(["prod", "dev"], var.environment)
    error_message = "環境名は 'prod' または 'dev' のいずれかを指定してください。"
  }
}

# リソース名（Prefix）の一部に使用するシステム名称
variable "project_name" {
  description = "プロジェクトの基本名称"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$+", var.project_name))
    error_message = "プロジェクト名は英小文字、数字、ハイフンのみ使用可能です。"
  }
}

# 【整合性修正】compute.tf で使用されるリソースグループ名の定義
variable "resource_group_name" {
  description = "01_network層で作成された既存のリソースグループ名"
  type        = string
}

# ==========================================
# 2. コンピューティング定義 (02層固有)
# ==========================================
# VMのスペックを決定する変数
variable "vm_size" {
  description = "仮想マシンのサイズ (SKU)"
  type        = string
}

# ==========================================
# 3. 認証・セキュリティ定義 (02層固有 / GitHub Secretsより注入)
# ==========================================
variable "admin_username" {
  description = "VMの管理者ユーザー名"
  type        = string

  validation {
    condition     = !contains(["admin", "root", "user", "administrator"], var.admin_username)
    error_message = "セキュリティ上の理由により、一般的な名称は使用できません。"
  }
}

variable "admin_password" {
  description = "VMの管理者パスワード"
  type        = string
  sensitive   = true # ログ出力防止
}

# ==========================================
# 4. メタデータ定義 (運用管理用)
# ==========================================
# 01_network 側の構成に合わせ、実値指定を必須とする（デフォルト値を削除）
variable "tags" {
  description = "すべてのリソースに付与する共通タグ"
  type        = map(string)
}

# ==========================================
# 5. 動的ID取得用定義
# ==========================================
variable "subscription_id" {
  type        = string
}