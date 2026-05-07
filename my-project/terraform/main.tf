# ==========================================
# リソースグループの作成
# Azure上のすべてのリソースをまとめる「箱」を定義
# ==========================================
resource "azurerm_resource_group" "rg" {
  # 【重要】環境ごとにリソースグループを完全に分離する
  # 例: 本番環境 = rg-web-project-prod
  #     検証環境 = rg-web-project-test
  name     = "rg-${var.project_name}-${var.env}"
  
  # variables.tf / tfvars で定義したリージョン（japaneast / japanwest）を参照
  location = var.location

  # 【追加】Azureベストプラクティス: リソース管理のためのタグを付与
  tags = {
    Environment = var.env
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}