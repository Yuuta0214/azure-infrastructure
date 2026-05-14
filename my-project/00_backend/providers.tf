# ==========================================
# 1. Terraform本体およびプロバイダーの定義
# ==========================================
terraform {
  # チーム開発やGitHub Actionsでの動作を保証するため、マイナーバージョンまで固定
  required_version = "~> 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # 最新のセキュリティパッチを含みつつ、破壊的変更を避けるため v3系最終付近に固定
      version = "~> 3.116.0" 
    }
  }

  # 【重要：00_backend 層のState管理ルール】
  # このディレクトリは「Stateを保存するためのAzureリソース」自体を作成する場所です。
  # そのため、ここに backend "azurerm" {} ブロックを記述することは物理的に不可能です。
}

# ==========================================
# 2. Azureプロバイダーの動作設定
# ==========================================
provider "azurerm" {
  # GitHub Actions (OIDC) 連携を想定
  use_oidc = true

  features {
    resource_group {
      # 安全策：リソースが含まれるRGの削除をTerraformから禁止する
      prevent_deletion_if_contains_resources = true
    }

    # ストレージアカウントの物理的な削除ミスを防ぐ「予防」設定
    storage_account {
      cannot_delete_if_contains_blobs = true
    }

    # Key Vaultの「救済」設定
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}