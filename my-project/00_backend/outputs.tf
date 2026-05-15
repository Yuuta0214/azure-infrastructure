# ==========================================
# 1. State基盤 接続情報（後続工程での設定用）
# ==========================================
# これらの出力値は、01_network 以降の providers.tf 内にある 
# backend "azurerm" {} ブロックに記述する値として使用します。

output "backend_resource_group_name" {
  description = "Stateファイルを保存するストレージアカウントが属するリソースグループ名"
  value       = azurerm_resource_group.mgmt_rg.name # main.tf の定義と整合 [cite: 5]
}

output "backend_storage_account_name" {
  description = "Stateファイルを保存するストレージアカウント名"
  value       = azurerm_storage_account.tfstate_sa.name # main.tf の定義と整合 [cite: 7]
}

output "backend_container_name" {
  description = "Stateファイルを保存するBlobコンテナ名"
  value       = azurerm_storage_container.tfstate_container.name # main.tf の定義と整合 [cite: 8]
}

# ==========================================
# 2. 環境識別情報
# ==========================================
output "deployment_summary" {
  description = "この基盤がどのプロジェクト・環境・リージョン向けのものかのサマリー"
  value = {
    project     = var.project_name # variables.tf の定義を使用 [cite: 3]
    environment = var.environment  # variables.tf の定義を使用 [cite: 3]
    location    = var.location     # variables.tf の定義を使用 [cite: 3]
  }
}