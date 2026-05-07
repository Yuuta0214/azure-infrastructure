# ==========================================
# 14. 実行結果の表示（Output）
# デプロイ完了後、アクセス先のIPアドレスや情報をターミナルに表示
# ==========================================

# デプロイされた環境名
output "environment" {
  description = "デプロイされた環境（prod / test）"
  value       = var.env
}

# リソースグループ名（Azure CLIでの確認用）
output "resource_group_name" {
  description = "作成されたリソースグループ名です。"
  value       = azurerm_resource_group.rg.name
}

# WebサイトへのアクセスURL（新規追加）
output "web_url" {
  description = "WebサイトのアクセスURLです。ブラウザで開いてください。"
  value       = "http://${azurerm_public_ip.lb_pip.ip_address}"
}

# ALBのパブリックIP（Ansibleのインベントリ生成用）
output "alb_public_ip" {
  description = "ALBのパブリックIPアドレスです（Ansibleの接続先として使用）。"
  value       = azurerm_public_ip.lb_pip.ip_address
}

# VMのプライベートIP（トラブルシューティング用）
output "vm_private_ip" {
  description = "VMの内部IPアドレスです。"
  value       = azurerm_network_interface.nic.private_ip_address
}

# SSH接続コマンド例（新規追加）
output "ssh_command_example" {
  description = "VMへのSSH接続コマンド例です。"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.lb_pip.ip_address}"
}