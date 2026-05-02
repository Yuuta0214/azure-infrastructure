# 1. Terraform 本体設定
# azurerm：Azure Resource Manager（Azureの管理システム）を操作するための「専用プラグイン（Provider）」
# source = "hashicorp/azurerm": 「このプラグインは公式（HashiCorp社）を使用する」というダウンロード元の指定です。
# ==========================================
terraform {
    # 使用する外部プログラム（Provider）の定義
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = "~> 3.0" # バージョン3.0系の最新（3.x）を使用する
        }
    }
    # Terraform自身の最低バージョンを指定（推奨）
    required_version = ">= 1.1.0"
}



# 2. Azure Providerの動作設定
provider "azurerm" {
    features {
        # ここでAzureの各種機能（features）の挙動をカスタマイズできるが
        # 基本は空のブロックで標準設定として動作させる
    }
}
# ==========================================