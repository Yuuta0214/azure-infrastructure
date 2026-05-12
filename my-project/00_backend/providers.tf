# ==========================================
# Terraform本体およびプロバイダーの定義
# ==========================================
terraform {
  # 使用するTerraformの最小バージョンを規定
  required_version = ">= 1.7.0"

  required_providers {
    # Azureリソースを操作するためのプロバイダーを指定
    azurerm = {
      source  = "hashicorp/azurerm"
      # 互換性と安定性を考慮し、3.x系の最終版に固定
      version = "3.116.0" 
    }
  }
}

# ==========================================
# Azureプロバイダーの動作設定
# ==========================================
provider "azurerm" {
  # GitHub Actions等の外部認証（OIDC）を使用してAzureへ接続
  use_oidc = true

  features {
    # リソースグループに関するセキュリティ設定
    resource_group {
      # 中にリソースが残っている場合に、誤ってリソースグループが削除されるのを防ぐ
      prevent_deletion_if_contains_resources = true
    }
  }
}