# ==========================================
# 1. 基盤・環境定義
# ==========================================
# リソースをデプロイする物理的な場所（例: japaneast）
variable "location" {
  description = "リソースを配置するリージョン" # 「01_network/main.tf」等から参照
  type        = string
  # 値の強制: 誤設定を防ぐためデフォルト値は持たせず、tfvarsでの指定を必須とする
}

# 本番・開発を識別し、リソース名やバリデーションに使用
variable "environment" {
  description = "実行環境 (prod または dev)" # 「01_network/main.tf」のLocals等で使用
  type        = string

  # 許容値の制限: 意図しない環境名によるデプロイを防止
  validation {
    condition     = contains(["prod", "dev"], var.environment)
    error_message = "環境名は 'prod' または 'dev' のいずれかを指定してください。"
  }
}

# リソース名（Prefix）の一部に使用するシステム名称
variable "project_name" {
  description = "プロジェクトの基本名称" # 「01_network/main.tf」のLocals等で使用
  type        = string

  # 命名規則の保護: Azureリソース名でエラーにならないよう、使用可能文字を制限
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "プロジェクト名は英小文字、数字、ハイフンのみ使用可能です。"
  }
}

# ==========================================
# 2. メタデータ定義 (運用管理用)
# ==========================================
# 組織特有の管理情報（部署名やコストセンター等）を格納
variable "tags" {
  description = "すべてのリソースに付与する共通タグ（BusinessUnit, Project等）" # 「01_network/main.tf」で共通タグとマージ
  type        = map(string)
  # 補足: EnvironmentやProjectなどの基本タグは main.tf の locals で自動合成される
}