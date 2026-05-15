# ==========================================
# 01_network: 実行結果の表示（Output）
# ==========================================
# このファイルでは、ネットワーク基盤レイヤーが作成したリソース情報を出力します。

# ------------------------------------------
# 1. 外部接続・エンドポイント情報
# ------------------------------------------

output "load_balancer_public_ip" {
  description = "ロードバランサーに割り当てられたパブリックIPアドレス"
  # network.tf のリソース名 "pip_lb" と整合性を取っています
  value       = azurerm_public_ip.pip_lb.ip_address
}

output "web_url_preview" {
  description = "WebサイトへのアクセスURL（ポート 8080）のプレビュー"
  value       = "http://${azurerm_public_ip.pip_lb.ip_address}:8080"
}

# ------------------------------------------
# 2. インフラ管理情報（後続の 02_compute 等で使用）
# ------------------------------------------

output "resource_group_name" {
  description = "ネットワークリソースが配置されているリソースグループ名"
  value       = azurerm_resource_group.rg.name
}

output "virtual_network_name" {
  description = "作成された仮想ネットワーク（VNet）の名称"
  value       = azurerm_virtual_network.vnet.name
}

output "backend_subnet_id" {
  description = "VMを配置するために用意されたバックエンドサブネットのID"
  # 02_compute で NIC を作成する際にこの ID が必要になります
  value       = azurerm_subnet.backend.id
}

output "network_security_group_id" {
  description = "適用されているネットワークセキュリティグループ（NSG）のID"
  # セキュリティ監査や後続のサブネット追加時に参照します
  value       = azurerm_network_security_group.nsg.id
}

# ------------------------------------------
# 3. 運用・保守用メタデータ
# ------------------------------------------

output "location" {
  description = "リソースがデプロイされているリージョン"
  value       = azurerm_resource_group.rg.location
}