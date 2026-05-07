# ==========================================
# 3. 共通変数の定義 (Locals)
# 複数のリソースで使い回す値や、命名規則をここで集約管理します
# ==========================================
locals {
  # プロジェクト全体のプレフィックス
  resource_prefix = "${var.project_name}-${var.env}"

  # 全リソース共通で付与するタグ
  common_tags = {
    Environment = var.env
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CreatedDate = "2026-05-07" # 運用管理上、作成日があると便利です
  }
}

# ==========================================
# 4. リソースグループの作成
# Azure上のすべてのリソースをまとめる「箱」
# ==========================================
resource "azurerm_resource_group" "rg" {
  # 命名規則を local で一貫させることで、タイポを防ぎます
  name     = "rg-${local.resource_prefix}"
  
  # variables.tf で定義された場所（japaneast等）を使用
  location = var.location

  # 共通タグを適用。必要に応じてここだけの個別タグを追加することも可能です
  tags = local.common_tags

  # 【アーキテクトの視点】
  # 重要なリソースグループには、誤削除防止のライフサイクル設定を追加することも検討します
  lifecycle {
    # 誤って名前を変更（破壊を伴う変更）しようとした際に警告が出るようにします
    prevent_destroy = false # 本番環境(prod)ではここを true に切り替える運用も推奨
  }
}