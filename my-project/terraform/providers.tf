# ==========================================
# 1. Terraform 本体設定
# ==========================================
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0" # v4.x 系の最新機能を利用
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-storage-state"
    storage_account_name = "sttfstate20260506yuta"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_oidc             = true # セキュアな認証
  }
}

# ==========================================
# 2. Azure Providerの動作設定
# ==========================================
provider "azurerm" {
  use_oidc = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
  }
}