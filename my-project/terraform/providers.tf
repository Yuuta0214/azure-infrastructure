# ==========================================
# 1. Terraform 本体設定
# ==========================================
terraform {
  # 最新の機能（removedブロック等）とセキュリティのため、1.7.0以上を推奨
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # 【修正】最新の v4.x 系を指定。
      # v4では一部のリソースプロパティが整理され、パフォーマンスが向上しています。
      version = "~> 4.0"
    }
  }

  # Remote Backend (Stateファイルの管理)
  backend "azurerm" {
    # ここに記載する値は「State管理用」の既存リソースです
    resource_group_name  = "rg-storage-state"
    storage_account_name = "sttfstate20260506yuta"
    container_name       = "tfstate"
    
    # 環境（prod/test）ごとにキーを分ける運用は非常に重要です
    # GitHub Actions側で -backend-config="key=..." を指定する前提でベース名を定義
    key                  = "terraform.tfstate"

    # OIDC認証の有効化
    use_oidc             = true
  }
}

# ==========================================
# 2. Azure Providerの動作設定
# ==========================================
provider "azurerm" {
  # OIDC経由の認証を明示
  use_oidc = true

  features {
    # 【ベストプラクティス】
    # リソースグループにリソースが含まれている場合の意図しない削除を防止
    resource_group {
      prevent_deletion_if_contains_resources = true
    }

    # 今後 Key Vault を導入した際、誤削除しても復元可能にする設定（セキュリティ上推奨）
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    
    # VM削除時にOSディスクを自動削除するかどうかの制御
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
  }
}