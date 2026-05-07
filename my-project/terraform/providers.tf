# ==========================================
# 1. Terraform 本体設定
# ==========================================
terraform {
  # Terraform自身の最低バージョンを指定（最新の機能とセキュリティを確保するため1.5.0以上を推奨）
  required_version = ">= 1.5.0"

  # 使用する外部プログラム（Provider）の定義
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # 3.x系の最新を使用。安定稼働のためマイナーバージョンまで固定するのも推奨されます
    }
  }

  # Remote Backend の導入（Stateファイルの管理）
  backend "azurerm" {
    resource_group_name  = "rg-storage-state" 
    storage_account_name = "sttfstate20260506yuta"
    container_name       = "tfstate"
    
    # 【重要】環境（prod/test）ごとにStateを分けるためのベース名
    # GitHub Actions側で `-backend-config="key=prod.terraform.tfstate"` のように動的に上書きすることを強く推奨します。
    key                  = "terraform.tfstate"
    
    # GitHub Actionsからのデプロイを想定し、OIDC認証を使用する設定（セキュリティベストプラクティス）
    use_oidc             = true
  }
}

# ==========================================
# 2. Azure Providerの動作設定
# ==========================================
provider "azurerm" {
  features {
    # リソースグループ削除時に中のリソースも強制削除するなどの挙動を制御できますが、基本は空でOKです
  }

  # GitHub Actions (OIDC) 経由での認証を明示的に有効化
  use_oidc = true
}