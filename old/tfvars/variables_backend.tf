# ==========================================
# 1. 基盤・環境定義
# ==========================================
# リソースをデプロイする物理的な場所（例: japaneast）
variable "location" {
  description = "リソースを配置するリージョン" # 「00_backend/main.tf」ファイルから参照
  type        = string
  # 値の強制: 誤設定を防ぐためデフォルト値は持たせず、実行時の指定を必須とする
}

# 本番・開発、またはブランチ名などの識別子
variable "environment" {
  description = "実行環境 (prod, test, またはブランチ名など)" # 「00_backend/main.tf」ファイルから参照
  type        = string
  # 柔軟性重視: バリデーションを解除し、動的な環境名にも対応可能
}

# リソース名の一部に使用するシステム名称
variable "project_name" {
  description = "プロジェクトの基本名称" # 「00_backend/main.tf」ファイルから参照
  type        = string

  # 命名規則の保護: Azureリソース名でエラーにならないよう、使用可能文字を制限
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "プロジェクト名は英小文字、数字、ハイフンのみ使用可能です。" # 「00_backend/main.tf」ファイルから参照
  }
}

# ==========================================
# 4. メタデータ定義 (運用管理用)
# ==========================================
# コスト管理や所有者特定のために全リソースに付与するラベル
variable "tags" {
  description = "すべてのリソースに付与する共通タグ（BusinessUnit, Project等）" # 「00_backend/main.tf」ファイルから参照
  type        = map(string)
  default     = {
    ManagedBy = "Terraform"
  }
}