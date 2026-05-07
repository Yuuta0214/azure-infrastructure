# providers.tf
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # バージョンを 3.x 系の最終安定版に固定してエラーを回避
      version = "3.116.0" 
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-storage-state"
    storage_account_name = "sttfstate20260506yuta"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_oidc             = true 
  }
}

provider "azurerm" {
  use_oidc = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }

    # 一旦、エラーの出やすい詳細オプションを最小限に絞ります
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
  }
}