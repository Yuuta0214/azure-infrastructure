# ==========================================
# 13. 実行結果の表示（Output）
# デプロイ完了後、アクセス情報や管理情報を出力
# ==========================================

# デプロイされた環境名
output "environment" {
  description = "デプロイされた環境（prod / test）"
  # 【修正】var.env から var.environment に変更
  value       = var.environment
}

# リソースグループ名
# Azure CLIの各コマンド (--resource-group) で頻繁に使用するため出力します
output "resource_group_name" {
  description = "作成されたリソースグループ名です。"
  value       = azurerm_resource_group.rg.name
}

# WebサイトへのアクセスURL
# 【修正】構成図の設計に基づき、ALBが受付けを行う 8080 ポートを明示
output "web_url" {
  description = "WebサイトのアクセスURL（ALB経由）です。"
  value       = "http://${azurerm_public_ip.lb_pip.ip_address}:8080"
}

# ALBのパブリックIP
# GitHub ActionsのAnsible実行ステップで、ターゲットIPとして動的に取得される値です
output "alb_public_ip" {
  description = "ALBのパブリックIPアドレスです。"
  value       = azurerm_public_ip.lb_pip.ip_address
}

# VMのプライベートIP
# Bastion経由での接続や、VNet内での内部通信に使用します
output "vm_private_ip" {
  description = "VMの内部IPアドレスです。"
  value       = azurerm_network_interface.nic.private_ip_address
}

# SSH接続コマンド（Bastion トンネル経由）
# 【設計準拠】インターネットから隔離されたVMに対し、Bastionをトンネルにしてセキュアに接続します
output "ssh_command_via_bastion" {
  description = "Azure Bastionを経由してVMにSSH接続するためのトンネル作成コマンドです。"
  # ポート 50022 をローカル待受けとして、VMの22番へ転送します
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