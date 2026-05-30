# ==========================================
# 共有: Terraform / Provider バージョン定義
# ==========================================
# 01_network / 02_compute の providers.tf と同一内容（参照用・将来の共通化用）
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.116.0"
    }
  }
}
