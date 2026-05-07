# ==========================================
# 3. 共通変数の定義 (Locals)
# 命名規則の統一と、運用タグの動的生成
# ==========================================
locals {
  # リソース名のプレフィックス (例: web-test / web-prod)
  resource_prefix = "${var.project_name}-${var.environment}"

  # 実行時の日付を自動取得 (例: 2026-05-07)
  # これにより .tfvars への手書きが不要になります
  current_date = formatdate("YYYY-MM-DD", timestamp())

  # 共通タグの統合管理
  # tfvars で定義した tags と、システムで自動付与するタグをマージします
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CreatedDate = local.current_date
  })
}

# ==========================================
# 4. リソースグループの作成
# Azure基盤の論理的な境界
# ==========================================
resource "azurerm_resource_group" "rg" {
  # 命名規則: rg-web-test または rg-web-prod
  name     = "rg-${local.resource_prefix}"
  
  # リージョン設定 (tfvars の値を反映)
  location = var.location

  # 共通タグの適用
  tags = local.common_tags

  # 【ベストプラクティス：ライフサイクル管理】
  lifecycle {
    # 運用上のノイズ（日付更新による差分）を完全に排除します
    # 初回作成時のタグを維持し、翌日以降の apply で CreatedDate が上書きされるのを防ぎます
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}