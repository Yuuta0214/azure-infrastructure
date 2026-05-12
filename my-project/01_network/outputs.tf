# ==========================================
# 実行結果の表示（Output）
# ==========================================

# ------------------------------------------
# 1. Ansible 連携・アクセス用
# ------------------------------------------
output "ansible_host_ip" {
  description = "Ansible や外部接続で使用するロードバランサーのパブリックIP"
  # network.tf 等で定義されているパブリックIPリソースを参照
  value       = azurerm_public_ip.lb_pip.ip_address
}

output "web_url" {
  description = "WebサイトへのアクセスURL（ポート 8080）"
  value       = "http://${azurerm_public_ip.lb_pip.ip_address}:8080"
}

# ------------------------------------------
# 2. インフラ管理情報（後続工程やデバッグ用）
# ------------------------------------------
output "resource_group_name" {
  description = "作成されたリソースグループ名"
  # main.tf の定義と連動
  value       = azurerm_resource_group.rg.name
}

# ------------------------------------------
# 3. 環境識別情報
# ------------------------------------------
output "environment_summary" {
  description = "デプロイされた環境のサマリー"
  value = {
    env      = var.environment
    project  = var.project_name
    location = var.location
  }
}