# ==========================================
# 02_compute / providers.tf
# ==========================================
terraform {
  # 使用するTerraformの最小バージョンを規定
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # 他のディレクトリ（00_backend, 01_network）と一貫性を保つため、3.x系の最終安定版に固定
      version = "3.116.0" 
    }
  }

  # ------------------------------------------
  # バックエンド設定（Stateファイルの保存先）
  # ------------------------------------------
  backend "azurerm" {
    # 00_backend で作成済みの管理用ストレージを指定
    resource_group_name  = "rg-storage-state"
    storage_account_name = "sttfstate20260506yuta"
    container_name       = "tfstate"
    
    # 【最重要】「01_network」のStateを上書きしないよう、compute専用のファイル名に修正
    key                  = "compute.tfstate"
    
    # GitHub Actions等からの実行を想定し、OIDC認証を有効化
    use_oidc             = true 
  }
}

# ==========================================
# Azureプロバイダーの動作設定
# ==========================================
provider "azurerm" {
  # 実行環境からの認証（OIDC等）を許可
  use_oidc = true

  features {
    # 01_network 側の providers.tf と方針を合わせ、
    # リソースグループの削除制限（prevent_deletion_if_contains_resources）を解除。
    # これにより、開発時のスクラップ＆ビルドを容易にします。

    # VMに関する詳細設定
    virtual_machine {
      # VM削除時に、OSディスクも自動的に削除されるように設定（ゴミが残るのを防ぐ）
      delete_os_disk_on_deletion = true
    }
  }
}