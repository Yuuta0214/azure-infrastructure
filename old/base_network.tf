# ==========================================
# 3. 共通変数の定義 (Locals)
# ==========================================
locals {
  # リソース名のプレフィックス (例: web-dev)
  # 他のファイル（network.tf等）で広く参照される重要な定義です
  resource_prefix = "${var.project_name}-${var.environment}"

  # 運用管理タグの統合
  # システム側で自動付与するタグと、tfvarsで指定した固有タグをマージします
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Layer       = "01_Network" # このレイヤーを明示
  })
}

# ==========================================
# 4. リソースグループの作成
# ==========================================
# このレイヤー（01_network）のリソースを収めるためのグループです。
resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.resource_prefix}"
  location = var.location
  tags     = local.common_tags

  # 【運用・保守のベストプラクティス】
  # ネットワーク基盤は頻繁に削除すべきではないため、
  # 意図しない destroy から保護する設定を追加することを推奨します。
  lifecycle {
    prevent_destroy = true
  }
}