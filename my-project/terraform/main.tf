# ==========================================
# 3. 共通変数の定義 (Locals)
# 命名規則の統一と、運用タグの一括管理
# ==========================================
locals {
  # リソース名のプレフィックス (例: projectA-prod)
  resource_prefix = "${var.project_name}-${var.env}"

  # 運用管理に不可欠な共通タグ
  # ManagedBy を入れることで、ポータル経由の変更を抑止する視覚的効果も持たせます
  common_tags = {
    Environment = var.env
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CreatedDate = "2026-05-07"
  }
}

# ==========================================
# 4. リソースグループの作成
# Azure基盤の論理的な境界
# ==========================================
resource "azurerm_resource_group" "rg" {
  # 命名規則: rg-[プロジェクト名]-[環境名]
  name     = "rg-${local.resource_prefix}"
  
  # リージョン設定 (japaneast / japanwest 等)
  location = var.location

  # 組織的な資産管理のための共通タグ適用
  tags = local.common_tags

  # 【ベストプラクティス：ライフサイクル管理】
  lifecycle {
    # 本番環境(prod)の場合は、別の overrides ファイル等で 
    # prevent_destroy = true にすることを前提とし、
    # ここではベースラインとして false を設定
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