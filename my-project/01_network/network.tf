# ==========================================
# 5. 仮想ネットワーク（VNet）の作成
# ==========================================
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.resource_prefix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # main.tf の locals で定義した共通タグを適用
  tags = local.common_tags
}

# ==========================================
# 6. サブネットの作成
# ==========================================
# フロントエンド用（将来的な拡張用）
resource "azurerm_subnet" "frontend" {
  name                 = "snet-frontend-${local.resource_prefix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# バックエンド用（Webサーバ/VMを配置）
resource "azurerm_subnet" "backend" {
  name                 = "snet-backend-${local.resource_prefix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Azure Bastion 専用サブネット（名称は固定必須）
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.10.0/26"]
}

# ==========================================
# 7. Azure Load Balancer (ALB) 設定
# ==========================================
# ロードバランサー用パブリックIP
resource "azurerm_public_ip" "lb_pip" {
  name                = "pip-lb-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# ロードバランサー本体
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

# バックエンドアドレスプール（VMが所属するグループ）
resource "azurerm_lb_backend_address_pool" "lb_pool" {
  loadbalancer_id = azurerm_lb.alb.id
  name            = "BackEndAddressPool"
}

# ヘルスプローブ（80番ポートでの生存確認）
resource "azurerm_lb_probe" "http" {
  loadbalancer_id = azurerm_lb.alb.id
  name            = "HTTPProbe"
  port            = 80
  protocol        = "Tcp"
}

# 負荷分散ルール（外部 8080 を内部 80 に転送）
resource "azurerm_lb_rule" "http" {
  loadbalancer_id                = azurerm_lb.alb.id
  name                           = "HTTPRule-8080-to-80"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_pool.id]
  probe_id                       = azurerm_lb_probe.http.id
}

# ==========================================
# 8. ネットワークセキュリティグループ（NSG）
# ==========================================
resource "azurerm_network_security_group" "nsg_backend" {
  name                = "nsg-backend-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # ALB（外部）からのHTTP通信を許可
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

  # 【必須】Ansible デプロイ用：GitHub Actions Runner 等からの SSH 接続を許可
  # 運用に合わせて接続元 IP を制限することを推奨しますが、一旦 Internet を許可
  security_rule {
    name                       = "AllowSSHFromInternet"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Azure Bastion サブネットからの管理用 SSH 接続を許可
  security_rule {
    name                       = "AllowSSHFromBastion"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.10.0/26" # BastionSubnet の範囲
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