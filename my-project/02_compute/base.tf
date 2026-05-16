# ==========================================
# 3. 共通変数の定義 (Locals)
# ここに全ての共通定義を集約し、他のファイル（compute.tf等）からは削除します
# ==========================================
locals {
  # リソース名のプレフィックス (例: web-test)
  resource_prefix = "${var.project_name}-${var.environment}"

  # 【解決策】実行時の日付を動的に取得。人間が書き換える必要はありません。
  current_date = formatdate("YYYY-MM-DD", timestamp())

  # 運用管理タグの統合
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CreatedDate = local.current_date
  })
}

# ==========================================
# 4. リソースグループの作成
# ==========================================
resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.resource_prefix}"
  location = var.location
  tags     = local.common_tags

  lifecycle {
    prevent_destroy = false

    # 初回作成時の CreatedDate を Azure 側に保持し、
    # 二回目以降の実行（明日以降）で「日付が変わった」という差分を出さないようにします。
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}