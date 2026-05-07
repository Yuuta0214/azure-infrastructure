# ==========================================
# 4. 仮想ネットワーク（VNet）の作成
# ==========================================
resource "azurerm_virtual_network" "vnet" {
  # 【修正】環境ごとに名前を分離
  name                = "vnet-${var.project_name}-${var.env}" 
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Environment = var.env
    Project     = var.project_name
  }
}

# ==========================================
# 5. Frontend subnetの作成（ALB用）
# ==========================================
resource "azurerm_subnet" "frontend" {
  name                 = "snet-frontend-${var.project_name}-${var.env}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     =["10.0.1.0/24"]
}

# ==========================================
# 6. Backend Subnetの作成（Docker VM用）
# ==========================================
resource "azurerm_subnet" "backend" {
  name                 = "snet-backend-${var.project_name}-${var.env}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     =["10.0.2.0/24"]
}

# ==========================================
# 7. Bastion Subnetの作成（管理用）
# ==========================================
resource "azurerm_subnet" "bastion" {
  # 【重要】Azure Bastion用のサブネットは「AzureBastionSubnet」という完全固定名である必要があります。
  # 環境名（-prodなど）を付けるとデプロイエラーになります。
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.10.0/26"] # /26以上のサイズが必須（要件クリア）
}

# ==========================================
# 8. ALB用パブリックIPの作成
# ==========================================
resource "azurerm_public_ip" "lb_pip" {
  name                = "pip-lb-${var.project_name}-${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = { Environment = var.env }
}

# ==========================================
# 9. Azure Load Balancer (ALB) の作成
# ==========================================
resource "azurerm_lb" "alb" {
  name                = "lb-${var.project_name}-${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }

  tags = { Environment = var.env }
}

# ==========================================
# 9-1. ALBバックエンドプールの作成
# ==========================================
resource "azurerm_lb_backend_address_pool" "lb_pool" {
  loadbalancer_id = azurerm_lb.alb.id
  name            = "BackEndAddressPool"
}

# ==========================================
# 9-2. ALBヘルスプローブ（死活監視）の作成【新規追加】
# Standard ALBでトラフィックを振り分けるには必須です
# ==========================================
resource "azurerm_lb_probe" "http" {
  loadbalancer_id = azurerm_lb.alb.id
  name            = "HTTPProbe"
  port            = 80
  protocol        = "Tcp"
}

# ==========================================
# 9-3. ALB負荷分散ルール（HTTP用）【新規追加】
# これがないとWebサイトにアクセスできません
# ==========================================
resource "azurerm_lb_rule" "http" {
  loadbalancer_id                = azurerm_lb.alb.id
  name                           = "HTTPRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_pool.id]
  probe_id                       = azurerm_lb_probe.http.id
}

# ==========================================
# 9-4. ALBインバウンドNATルール（SSH用）
# ==========================================
resource "azurerm_lb_nat_rule" "ssh" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.alb.id
  name                           = "SSHInbound"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
}

# ==========================================
# 10. ネットワークセキュリティグループ（NSG）の作成
# ==========================================
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.project_name}-${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # 【追加】Webトラフィック（HTTP）の許可
  security_rule {
    name                       = "AllowHTTPInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # SSHの許可（※警告: 本来は送信元IPを絞るべきです）
  security_rule {
    name                       = "AllowSSHInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*" # 可能であればGitHub ActionsのIP等に制限してください
    destination_address_prefix = "*"
  }

  tags = { Environment = var.env }
}

# ==========================================
# 11. NSGとバックエンドサブネットの関連付け
# ==========================================
resource "azurerm_subnet_network_security_group_association" "backend_nsg_assoc" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}