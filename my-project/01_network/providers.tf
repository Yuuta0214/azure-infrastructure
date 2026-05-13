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
    # 管理用リソースグループ名（00_backend の実行結果と一致させる必要があります）
    resource_group_name  = "rg-web-dev-mgmt"
    
    # 管理用ストレージアカウント名
    storage_account_name = "stwebdevbackend"
    
    # State ファイルを格納するコンテナ名
    container_name       = "tfstate"
    
    # このレイヤー（01_network）専用の識別キー
    # これにより、他のレイヤー（00 や 02）の State と干渉しません
    key                  = "network.tfstate"
    
    # GitHub Actions との連携用に OIDC 認証を有効化（セキュリティベストプラクティス）
    use_oidc             = true 
  }
}

# ==========================================
# 3. プロバイダーの動作設定
# ==========================================
provider "azurerm" {
  # AzureRM プロバイダーに必須の定義
  features {
    resource_group {
      # リソースグループ内にリソースが残っている場合の削除動作を制御（標準設定）
      prevent_deletion_if_contains_resources = true
    }
  }

  # CI/CD 環境（GitHub Actions）での実行を想定し、OIDC を使用
  use_oidc = true
}