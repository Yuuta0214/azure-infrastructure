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
# ==========================================

# Frontend subnet (ALB用)
resource "azurerm_subnet" "frontend" {
  name                 = "snet-frontend-${local.resource_prefix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Backend Subnet (Docker VM用)
resource "azurerm_subnet" "backend" {
  name                 = "snet-backend-${local.resource_prefix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Bastion Subnet (管理用)
resource "azurerm_subnet" "bastion" {
  # 固定名称：AzureBastionSubnet
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.10.0/26"]
}

# ==========================================
# 7. Azure Load Balancer (ALB) 設定
# ==========================================

resource "azurerm_public_ip" "lb_pip" {
  name                = "pip-lb-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
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
}

resource "azurerm_lb_backend_address_pool" "lb_pool" {
  loadbalancer_id = azurerm_lb.alb.id
  name            = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "http" {
  loadbalancer_id = azurerm_lb.alb.id
  name            = "HTTPProbe"
  port            = 80 # コンテナが待受けているポート
  protocol        = "Tcp"
}

# 【修正】構成図に基づき、外部ポート 8080 を 内部ポート 80 へ変換
resource "azurerm_lb_rule" "http" {
  loadbalancer_id                = azurerm_lb.alb.id
  name                           = "HTTPRule-8080-to-80"
  protocol                       = "Tcp"
  frontend_port                  = 8080 # 構成図：8080
  backend_port                   = 80   # 構成図：80 (nginx/container)
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_pool.id]
  probe_id                       = azurerm_lb_probe.http.id
}

# ==========================================
# 8. ネットワークセキュリティグループ（NSG）
# 構成図の「Frontend用」と「Backend用」を分離して定義します
# ==========================================

# --- Backend用NSG (Dockerホストを保護) ---
resource "azurerm_network_security_group" "nsg_backend" {
  name                = "nsg-backend-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # ALBからのトラフィックのみ Port 80 を許可
  security_rule {
    name                       = "AllowHTTPFromALB"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # 【修正】SSHは「Bastionサブネット」からのみ許可（セキュリティ強化）
  security_rule {
    name                       = "AllowSSHFromBastion"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.10.0/26" # Bastionサブネット範囲
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# ==========================================
# 9. NSGとサブネットの関連付け
# ==========================================

resource "azurerm_subnet_network_security_group_association" "backend_assoc" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.nsg_backend.id
}