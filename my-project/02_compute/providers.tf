# ==========================================
# 02_compute / providers.tf
# ==========================================
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.116.0"
    }
  }

  # ------------------------------------------
  # バックエンド設定（Stateファイルの保存先）
  # ------------------------------------------
  # 環境（dev/prod）による値の差異は、02_compute.yml 実行時に
  # -backend-config 引数で動的に注入します。
  backend "azurerm" {
    resource_group_name  = "" # 02_compute.yml より注入
    storage_account_name = "" # 02_compute.yml より注入
    container_name       = "tfstate"
    key                  = "compute.tfstate"
    use_oidc             = true
  }
}

provider "azurerm" {
  use_oidc = true
  features {
    virtual_machine {
      # 運用保守: VM削除時にOSディスクを自動削除しない（安全設計）
      delete_os_disk_on_deletion = false
    }
  }
}