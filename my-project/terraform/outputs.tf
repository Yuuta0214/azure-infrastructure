# ==========================================
# 13. 実行結果の表示（Output）
# デプロイ完了後、アクセス情報や管理情報を出力
# ==========================================

# デプロイされた環境名
output "environment" {
  description = "デプロイされた環境（prod / test）"
  value       = var.environment
}

# リソースグループ名
output "resource_group_name" {
  description = "作成されたリソースグループ名です。"
  value       = azurerm_resource_group.rg.name
}

# WebサイトへのアクセスURL
# 【修正】Plan時の値未確定によるエラーを回避するため try() を使用
output "web_url" {
  description = "WebサイトのアクセスURL（ALB経由）です。"
  value       = "http://${try(azurerm_public_ip.lb_pip.ip_address, "pending")}:8080"
}

# ALBのパブリックIP
# 【修正】Plan時のエラーを回避
output "alb_public_ip" {
  description = "ALBのパブリックIPアドレスです。"
  value       = try(azurerm_public_ip.lb_pip.ip_address, "pending")
}

# VMのプライベートIP
# 【修正】NICが新規作成の場合に備え、安全な参照に変更
output "vm_private_ip" {
  description = "VMの内部IPアドレスです。"
  value       = try(azurerm_network_interface.nic.private_ip_address, "pending")
}

# SSH接続コマンド（Bastion トンネル経由）
output "ssh_command_via_bastion" {
  description = "Azure Bastionを経由してVMにSSH接続するためのトンネル作成コマンドです。"
  value       = "az network bastion tunnel --name bastion-host --resource-group ${azurerm_resource_group.rg.name} --target-resource-id ${azurerm_linux_virtual_machine.vm.id} --resource-port 22 --port 50022"
}

output "ssh_connect_local" {
  description = "トンネル作成後、ローカルの別ターミナルから実行する接続コマンドです。"
  value       = "ssh -i ~/.ssh/id_rsa ${var.admin_username}@127.0.0.1 -p 50022"
}

# VM ID (運用・監視用)
output "vm_id" {
  description = "作成された仮想マシンのリソースIDです。"
  value       = azurerm_linux_virtual_machine.vm.id
}