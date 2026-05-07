# ==========================================
# 3. 共通変数の定義 (Locals)
# 命名規則の統一と、運用タグの一括管理
# ==========================================
locals {
  # リソース名のプレフィックス (例: web-test / web-project)
  # variables.tf および tfvars で定義した新しい値に基づき構成します
  resource_prefix = "${var.project_name}-${var.environment}"

  # 運用管理に不可欠な共通タグ
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      CreatedDate = "2026-05-07"
    },
    var.tags # variables.tf で定義した追加タグをマージ
  )
}

# ==========================================
# 4. リソースグループの作成
# Azure基盤の論理的な境界
# ==========================================
resource "azurerm_resource_group" "rg" {
  # 命名規則: rg-web-test または rg-web-project
  # これにより GitHub Actions の terraform import 対象と完全に一致させます
  name     = "rg-${local.resource_prefix}"
  
  # リージョン設定 (tfvars の japanwest / japaneast を反映)
  location = var.location

  # 組織的な資産管理のための共通タグ適用
  tags = local.common_tags

  # 【ベストプラクティス：ライフサイクル管理】
  lifecycle {
    # 不慮の削除を防止（必要に応じて true に変更検討）
    prevent_destroy = false

    # 変更時のダウンタイムを最小限にするための設定
    ignore_changes = [
      tags["CreatedDate"] # 初回作成日を維持するため、更新時は無視
    ]
  }
}

# ==========================================
# 以降、このリソースグループを参照してネットワーク、
# VM、およびAnsible連携用のアウトプットを順次定義します。
# ==========================================