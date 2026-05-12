# ==========================================
# 1. 共通変数の定義 (Locals)
# ==========================================
locals {
  # 命名規則: プロジェクト名-環境名-役割 (mgmt)
  mgmt_prefix = "${var.project_name}-${var.environment}-mgmt"

  # 運用管理用の標準タグ
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Layer       = "00_Backend_Storage"
  })
}

# ==========================================
# 2. 管理用リソースグループ (RG)
# ==========================================
resource "azurerm_resource_group" "mgmt_rg" {
  name     = "rg-${local.mgmt_prefix}" # 変数 mgmt_prefix を使う
  location = var.location
  tags     = local.common_tags
}

# ==========================================
# リソースロック
# ==========================================
resource "azurerm_management_lock" "rg_lock" {
   name       = "resourcelock-backend-rg"
   scope      = azurerm_resource_group.mgmt_rg.id
   lock_level = "CanNotDelete"
   notes      = "このリソースグループを削除すると全インフラの管理図(State)が消失するため、削除を禁止しています。"
 }

# ==========================================
# 3. State保存用ストレージアカウント
# ==========================================
resource "azurerm_storage_account" "tfstate_sa" {
  # 名前制約: 英小文字と数字のみ（ハイフン不可）
  name                     = "st${var.project_name}${var.environment}backend"
  resource_group_name      = azurerm_resource_group.mgmt_rg.name
  location                 = azurerm_resource_group.mgmt_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # コスト効率重視（必要に応じて ZRS 等を検討）

  # セキュリティ・運用設定（v3.116.0 整合）
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false # コンテナ内の公開アクセスを物理的に禁止
  
  # 【保守のベストプラクティス：バージョニング】
  # 万が一 State ファイルが破損・誤削除された場合でも、過去のバージョンから復旧可能にします。
  blob_properties {
    versioning_enabled = true
  }

  tags = local.common_tags
}

# ==========================================
# 4. ストレージコンテナ (tfstate用)
# ==========================================
resource "azurerm_storage_container" "tfstate_container" {
  name                  = "tfstate"
  # 「.name」ではなく「.id」を使い、引数名も「storage_account_id」に変更
  storage_account_id    = azurerm_storage_account.tfstate_sa.id
  container_access_type = "private"
}

# ==========================================
# 5. ストレージアカウント用リソースロック (追加)
# ==========================================
resource "azurerm_management_lock" "sa_lock" {
  name       = "resourcelock-tfstate-sa"
  scope      = azurerm_storage_account.tfstate_sa.id
  lock_level = "CanNotDelete"
  notes      = "このストレージアカウントにはTerraformのStateファイルが保存されているため、削除を禁止しています。"
}