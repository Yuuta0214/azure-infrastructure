# ==========================================
# 1. 共通変数の定義 (Locals)
# ==========================================
locals {
  # 管理用リソースとしての名前を固定
  # 例: myproject-prod-mgmt-rg
  mgmt_prefix = "${var.project_name}-${var.environment}-mgmt"

  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Layer       = "00_Backend_Storage"
  })
}

# ==========================================
# 2. 管理用リソースグループの作成
# ==========================================
resource "azurerm_resource_group" "mgmt_rg" {
  # ここが「器」そのものを入れる箱になります
  name      = "rg-${local.mgmt_prefix}"
  location = var.location
  tags     = local.common_tags

  lifecycle {
    # 誤ってこのリソースグループを消すと、全てのState（設計図）が消えるため、
    # 本番運用時は true にすることを推奨しますが、今は開発中なので false で設定します。
    prevent_destroy = false
  }
}

# ==========================================
# 3. State保存用ストレージアカウントの作成
# ==========================================
# ※ここに、前回 az コマンドで作ろうとしていた 
# ストレージアカウントとコンテナの定義を続けて書くことになります。

# ------------------------------------------
# 3-1. ストレージアカウント (物理的な器)
# ------------------------------------------
resource "azurerm_storage_account" "tfstate_sa" {
  # ストレージアカウント名は「英小文字と数字のみ」で一意にする必要があるため、ハイフンなしで連結
  name                     = "st${var.project_name}${var.environment}backend"
  resource_group_name      = azurerm_resource_group.mgmt_rg.name
  location                 = azurerm_resource_group.mgmt_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # ローカル冗長（コスト抑止のため）

  # セキュリティ設定
  min_tls_version          = "TLS1_2"
  https_traffic_only_enabled = true # プロバイダー v3.116.0 との整合性：HTTPS通信を強制する設定項目名
  tags = local.common_tags
}

# ------------------------------------------
# 3-2. ストレージコンテナ (Stateファイルを置く場所)
# ------------------------------------------
resource "azurerm_storage_container" "tfstate_container" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate_sa.id
  container_access_type = "private" # 外部非公開
}
