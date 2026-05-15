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
  name     = "rg-${local.mgmt_prefix}"
  location = var.location
  tags     = local.common_tags
}

# ==========================================
# 3. State保存用ストレージアカウント
# ==========================================
resource "azurerm_storage_account" "tfstate_sa" {
  # 名称ルール: 
  # 英小文字と数字のみ（ハイフン不可）
  name                     = "st${var.project_name}${var.environment}backend"
  resource_group_name      = azurerm_resource_group.mgmt_rg.name
  location                 = azurerm_resource_group.mgmt_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # コスト効率重視

  # セキュリティ・運用設定
  min_tls_version                 = "TLS1_2"
  
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false # 公開アクセスを物理的に禁止
  
  # 【保守のベストプラクティス：データ保護】
  # バージョニングを有効にし、Stateファイルの破損・誤削除からの復旧を可能にします
  blob_properties {
    versioning_enabled = true
    # 削除されたStateを一定期間保持する設定（追加推奨）
    delete_retention_policy {
      days = 7
    }
  }

  tags = local.common_tags

  # 【重複実行・上書き防止設定】
  # 同名のリソースが既に存在する場合、既存の設定を上書きせずにエラーを出して停止させます。
  lifecycle {
    prevent_destroy = true
  }
}

# ==========================================
# 4. ストレージコンテナ (tfstate用)
# ==========================================
resource "azurerm_storage_container" "tfstate_container" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate_sa.name
  container_access_type = "private"
}

# ==========================================
# 5. 【追加】運用・保守のベストプラクティス：削除ロック
# ==========================================
# terraform destroy 等の操作ミスによる、State基盤自体の物理削除を防止します。

# リソースグループ（RG）単位でのロック
resource "azurerm_management_lock" "rg_lock" {
  name       = "resourcelock-backend-rg"
  scope      = azurerm_resource_group.mgmt_rg.id
  lock_level = "CanNotDelete"
  notes      = "基盤リソースグループ全体の削除を防止します。"
}

# ストレージアカウント（SA）単位でのロック
resource "azurerm_management_lock" "sa_lock" {
  name       = "resourcelock-tfstate-sa"
  scope      = azurerm_storage_account.tfstate_sa.id
  lock_level = "CanNotDelete"
  notes      = "Stateファイルを保持する重要なストレージのため、手動解除なしの削除を禁止します。"
}