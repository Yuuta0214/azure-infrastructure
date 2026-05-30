# ==========================================
# 共有: Azure Provider 動作設定
# ==========================================
# 01_network / 02_compute の providers.tf と同一内容（参照用・将来の共通化用）
provider "azurerm" {
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}
