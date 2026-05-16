# ==========================================
# 1. Terraform 構成・プロバイダー定義
# ==========================================
# ネットワーク基盤（01_network）レイヤーの基本構成を定義します。
terraform {
  # 安定性と機能性のバランスが取れたバージョンを指定
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # バージョン固定により、予期せぬアップデートによるデプロイ失敗を防止
      version = "3.116.0" 
    }
  }

  # ==========================================
  # 2. バックエンド設定 (Stateファイルの保存先)
  # ==========================================
  # 00_backend で作成した管理用ストレージアカウントに、
  # ネットワークレイヤー専用の State ファイル（network.tfstate）を保存します。
  backend "azurerm" {
    # 【修正】00_backend で作成したリソース名と完全に一致させます
    resource_group_name  = "rg-web-dev-mgmt" # 開発環境用。本番実行時は -backend-config で上書き
    
    # 【修正】00_backend で確定した命名規則に基づき修正
    storage_account_name = "stwebdevbackend"
    
    # State ファイルを格納するコンテナ名
    container_name       = "tfstate"
    
    # このレイヤー（01_network）専用の識別キー
    # これにより、他のレイヤー（00 や 02）の State ファイルと分離します。
    key                  = "network.tfstate"

    # 【ベストプラクティス：セキュリティ】
    # OIDC認証を使用するため、ここでは認証情報をハードコードせず、GitHub Actions 経由で渡します。
    use_oidc = true
  }
}

# ==========================================
# 3. プロバイダーの動作設定
# ==========================================
provider "azurerm" {
  features {
    # 【ベストプラクティス：保守】
    # リソースグループ内にリソースが残っている場合の意図しない削除を防止
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}