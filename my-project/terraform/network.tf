# ==========================================
# 5. 仮想ネットワーク（VNet）の作成
# ==========================================
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.resource_prefix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = local.common_tags
}

# ==========================================
# 6. サブネットの作成
# 役割ごとにセグメントを分離し、トラフィック制御を容易にします
# ==========================================

# Frontend subnet (ALB / Application Gateway用)
resource "azurerm_subnet" "frontend" {
  name                 = "snet-frontend-${local.resource_prefix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Backend Subnet (Dockerホスト VM用)
resource "azurerm_subnet" "backend" {
  name                 = "snet-backend-${local.resource_prefix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Bastion Subnet (運用管理用)
# 名称は「AzureBastionSubnet」固定である必要があります
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.10.0/26"]
}

# ==========================================
# 7. Azure Load Balancer (ALB) 設定
# 外部からのトラフィックを分散・中継します
# ==========================================

resource "azurerm_public_ip" "lb_pip" {
  name                = "pip-lb-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard" # ALB Standard SKUにはStatic PIPが必要
  tags                = local.common_tags
}

resource "azurerm_lb" "alb" {
  name                = "lb-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }

  tags = local.common_tags
}

resource "azurerm_lb_backend_address_pool" "lb_pool" {
  loadbalancer_id = azurerm_lb.alb.id
  name            = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "http" {
  loadbalancer_id = azurerm_lb.alb.id
  name            = "HTTPProbe"
  port            = 80 # バックエンドのNginxコンテナ待受ポート
  protocol        = "Tcp"
  interval_in_seconds = 15
  number_of_probes    = 2
}

# 【修正】構成図に基づき、外部ポート 8080 を 内部ポート 80 へ変換
resource "azurerm_lb_rule" "http" {
  loadbalancer_id                = azurerm_lb.alb.id
  name                           = "HTTPRule-8080-to-80"
  protocol                       = "Tcp"
  frontend_port                  = 8080 # 外部受付ポート
  backend_port                   = 80   # 内部転送ポート
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_pool.id]
  probe_id                       = azurerm_lb_probe.http.id
}

# ==========================================
# 8. ネットワークセキュリティグループ（NSG）
# ホワイトリスト方式で必要最小限の通信のみ許可
# ==========================================

resource "azurerm_network_security_group" "nsg_backend" {
  name                = "nsg-backend-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # ALB (Standard) からのヘ