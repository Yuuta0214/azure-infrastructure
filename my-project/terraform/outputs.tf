# 14. 実行結果の表示（Output）
# デプロイ完了後、アクセス先のIPアドレスや情報をターミナルに表示
# ==========================================

# ALBのパブリックIP（Webサイトへのアクセス先）
output "alb_public_ip" {
  description = "ALBのパブリックIPアドレスです。ブラウザからこのIPにアクセスしてください。"
  value       = azurerm_public_ip.lb_pip.ip_address
}

# VMのプライベートIP（Ansibleでの管理やトラブルシューティング用）
output "vm_private_ip" {
  description = "VMの内部IPアドレスです。"
  value       = azurerm_network_interface.nic.private_ip_address
}

# リソースグループ名（Azure CLIでの確認用）
output "resource_group_name" {
  description = "作成されたリソースグループ名です。"
  value       = azurerm_resource_group.rg.name
}
# ==========================================