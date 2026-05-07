# ==========================================
# 13. 実行結果の表示（Output）
# デプロイ完了後、アクセス情報や管理情報を出力
# ==========================================

# デプロイされた環境名
output "environment" {
  description = "デプロイされた環境（prod / test）"
  value       = var.env
}

# リソースグループ名（Azure CLIでの確認用）
output "resource_group_name" {
  description = "作成されたリソースグループ名です。Azure CLIの --resource-group 引数に使用します。"
  value       = azurerm_resource_group.rg.name
}

# WebサイトへのアクセスURL
# 【修正】構成図に合わせてポートを 8080 に指定
output "web_url" {
  description = "WebサイトのアクセスURLです。ブラウザで開いてください。"
  value       = "http://${azurerm_public_ip.lb_pip.ip_address}:8080"
}

# ALBのパブリックIP
output "alb_public_ip" {
  description = "ALBのパブリックIPアドレスです。"
  value       = azurerm_public_ip.lb_pip.ip_address
}

# VMのプライベートIP
# 【重要】Bastion経由のSSHや、内部ネットワーク間通信で使用します
output "vm_private_ip" {
  description = "VMの内部IPアドレスです。"
  value       = azurerm_network_interface.nic.private_ip_address
}

# SSH接続コマンド（Bastion トンネル経由）
# 【修正】設計図の「bastion tunnel」を利用したセキュアな接続コマンドを生成
output "ssh_command_via_bastion" {
  description = "Azure Bastionを経由してVMにSSH接続するためのトンネル作成コマンドです。"
  value       = "az network bastion tunnel --name bastion-host --resource-group ${azurerm_resource_group.rg.name} --target-resource-id ${azurerm_linux_virtual_machine.vm.id} --resource-port 22 --port 50022"
}

output "ssh_connect_local" {
  description = "トンネル作成後、別ターミナルで実行する接続コマンドです。"
  value       = "ssh ${var.admin_username}@127.0.0.1 -p 50022"
}