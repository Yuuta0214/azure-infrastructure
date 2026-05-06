# ==========================================
# 1. Terraform 本体設定
# ==========================================
terraform {
    # 使用する外部プログラム（Provider）の定義
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~> 3.0"
        }
    }

    # 【恒久修正】Remote Backend の導入
    backend "azurerm" {
        # 【修正箇所】"tfstate-rg" から変更
        resource_group_name  = "rg-storage-state" 
        storage_account_name = "sttfstate20260506yuta"
        container_name       = "tfstate"
        key                  = "terraform.tfstate"
    }

    # Terraform自身の最低バージョンを指定
    required_version = ">= 1.1.0"
}

# 2. Azure Providerの動作設定
provider "azurerm" {
    features {}
}
# ==========================================