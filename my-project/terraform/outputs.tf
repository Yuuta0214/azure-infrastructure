# ==========================================
# 13. 実行結果の表示（Output）
# 運用・保守、および Ansible 連携のための定義
# ==========================================

# 1. Ansible 連携用（ターゲットホストの特定に必須）
output "ansible_host_ip" {
  description = "Ansible が接続先として使用する ALB のパブリック IP です。"
  value       = azurerm_public_ip.lb_pip.ip_address
}

# 2. WebサイトへのアクセスURL
output "web_url" {
  description = "WebサイトのアクセスURL（ポート 8080）です。"
  value       = "http://${azurerm_public_ip.lb_pip.ip_address}:8080"
}

# 3. インフラ管理情報
output "resource_group_name" {
  description = "作成されたリソースグループ名です。"
  value       = azurerm_resource_group.rg.name
}

output "vm_id" {
  description = "作成された仮想マシンのリソースIDです。"
  value       = azurerm_linux_virtual_machine.vm.id
}

output "vm_private_ip" {
  description = "VMの内部IPアドレス（VNet内）です。"
  value       = azurerm_network_interface.nic.private_ip_address
}

# 4. 運用・保守用 SSH 接続ガイド
# Bastion を使用したセキュアな接続手順を出力します
output "ssh_step_1_tunnel" {
  description = "STEP1: Azure Bastion 経由でトンネルを作成します（別ターミナルで実行）"
  value       = "az network bastion tunnel --name bastion-host --resource-group ${azurerm_resource_group.rg.name} --target-resource-id ${azurerm_linux_virtual_machine.vm.id} --resource-port 22 --port 50022"
}

output "ssh_step_2_connect" {
  description = "STEP2: トンネル経由で VM にログインします（パスワードが要求されます）"
  value       = "ssh ${var.admin_username}@127.0.0.1 -p 50022"
}

# 5. 環境識別
output "environment_info" {
  description = "現在のデプロイ環境"
  value       = {
    env     = var.environment
    project = var.project_name
    region  = var.location
  }
}