# providers.tf
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.116.0" 
    }
  }

  backend "azurerm" {
    # 00_backendで作成したリソース名を指定
    resource_group_name  = "rg-storage-state"
    storage_account_name = "sttfstate20260506yuta"
    container_name       = "tfstate"
    # 01_network フォルダ専用のステートファイル名に変更
    key                  = "network.tfstate"
    use_oidc             = true 
  }
}

provider "azurerm" {
  use_oidc = true

  features {
  }
}