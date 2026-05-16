# ==========================================
# 02_compute / providers.tf
# ==========================================
terraform {
  # チーム開発およびCI/CD環境での一貫性を保つためバージョンを固定
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # 00_backend, 01_network と同一の安定版バージョンを使用
      version = "3.116.0"
    }
  }

  # ------------------------------------------
  # バックエンド設定（Stateファイルの保存先）
  # ------------------------------------------
  # 00_backend で作成された管理用ストレージを指定します。
  # 実行環境（dev/prod）による値の差異は、GitHub Actions 実行時に
  # -backend-config 引数で注入することを前提とした標準構成にします。
  backend "azurerm" {
    # 【整合性修正】00_backend で定義されたリソース名に準拠
    resource_group_name  = "rg-web-dev-mgmt" 
    storage_account_name = "stwebdevbackend"
    container_name       = "tfstate"
    
    # 【最重要】ネットワーク層（network.tfstate）を破壊しないよう独立したキーを指定
    key                  = "compute.tfstate"
    
    # GitHub Actions からの OIDC 認証を有効化
    use_oidc             = true
  }
}

# ==========================================
# Azure プロバイダーの動作・安全設定
# ==========================================
provider "azurerm" {
  # GitHub Actions (OIDC) 連携を有効化
  use_oidc = true

  features {
    # ---------------------------------------------------------
    # 運用保守・セキュリティ設計
    # ---------------------------------------------------------
    resource_group {
      # 安全策：リソース（VM等）が含まれるRGの削除をTerraformから禁止する
      # これにより、一括削除コマンド（destroy）による事故を防止します。
      prevent_deletion_if_contains_resources = true
    }

    virtual_machine {
      # 削除時にOSディスクを自動削除する（コスト管理のベストプラクティス）
      delete_os_disk_on_deletion = true
    }
  }
}