# ==========================================
# 3. 共通変数の定義 (Locals)
# ==========================================
locals {
  # リソース名のプレフィックス (例: web-dev)
  resource_prefix = "${var.project_name}-${var.environment}"

  # 運用管理タグの統合
  # システム側で自動付与するタグと、tfvarsで指定した固有タグをマージします
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })
}

# ==========================================
# 4. リソースグループの作成
# ==========================================
resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.resource_prefix}"
  location = var.location
  tags     = local.common_tags

  # 補足: 00_backendと同様、不要なlifecycleブロックや
  # 動的なCreatedDateタグは削除し、差分が出にくい構成にしています
}