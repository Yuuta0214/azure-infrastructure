# ==========================================
# 1. Terraform本体およびプロバイダーの定義
# ==========================================
terraform {
  # 安定性を考慮したバージョン指定 
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # プロバイダー v3.116.0 との整合性を維持 [cite: 6, 12]
      version = "3.116.0" 
    }
  }

  # 【重要：ベストプラクティス】
  # 00_backend フォルダでは、絶対に「backend "azurerm" {}」を記述しないでください。
  # 自身の保存場所（Storage Account）を作る工程であるため、この層の管理図（State）は
  # 実行環境のローカル（またはリポジトリ管理）に保持する必要があります。
}

# ==========================================
# 2. Azureプロバイダーの動作設定
# ==========================================
provider "azurerm" {
  # GitHub Actions経由のデプロイを想定したOIDC認証を有効化 
  use_oidc = true

  features {
    resource_group {
      # 削除防止の安全策を継承 
      prevent_deletion_if_contains_resources = true
    }
    
    # State基盤リソースの誤削除防止設定（任意で追加可能）
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}