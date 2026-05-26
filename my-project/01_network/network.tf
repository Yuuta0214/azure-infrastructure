# ==========================================
# 5. 仮想ネットワーク（VNet）の作成
# ==========================================
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.resource_prefix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags
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

# バックエンド用（Webサーバ/VMを配置するメイン区画）
resource "azurerm_subnet" "backend" {
  name                 = "snet-backend-${local.resource_prefix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# ==========================================
# 7. ロードバランサー (LB) 関連リソースの作成
# ==========================================
# LB用パブリックIP (outputs.tf で参照される pip_lb)
resource "azurerm_public_ip" "pip_lb" {
  name                = "pip-lb-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard" # セキュリティと機能性のための Standard SKU
  tags                = local.common_tags

  lifecycle {
    prevent_destroy = true # 運用中のIP変更・削除を防止
  }
}

# Load Balancer 本体
resource "azurerm_lb" "lb" {
  name                = "lb-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = local.common_tags

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.pip_lb.id
  }
}

# バックエンドアドレスプール
resource "azurerm_lb_backend_address_pool" "lb_backend_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "BackendPool-${local.resource_prefix}"
}

# ヘルスプローブ (ポート 8080 の監視)
resource "azurerm_lb_probe" "lb_probe" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "http-running-probe"
  port            = 8080
  protocol        = "Tcp" # 8080ポートの疎通を確認
}

# 80用 ヘルスプローブを追加
resource "azurerm_lb_probe" "lb_probe_80" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "http-running-probe-80"
  port            = 80
  protocol        = "Tcp"
}

# 負荷分散ルール (TCP/8080)
resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBRule-HTTP-8080"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_pool.id]
  probe_id                       = azurerm_lb_probe.lb_probe.id
}

# 追加：# 負荷分散ルール (TCP/22)
resource "azurerm_lb_rule" "lb_rule_ssh" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBRule-SSH-22"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_pool.id]
}

# 80用 負荷分散ルールを追加
resource "azurerm_lb_rule" "lb_rule_80" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBRule-HTTP-80"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_pool.id]
  probe_id                       = azurerm_lb_probe.lb_probe_80.id
}

# ==========================================
# 8. ネットワークセキュリティグループ (NSG) の作成
# ==========================================

# 8-1. Frontend用 NSG (DMZ用)
resource "azurerm_network_security_group" "nsg_frontend" {
  name                = "nsg-frontend-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # HTTP(80) 許可
  security_rule {
    name                       = "AllowHTTP80Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # HTTPS(443) 許可
  security_rule {
    name                       = "AllowHTTPS443Inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  tags = local.common_tags
}

# 8-2. Backend用 NSG (内部サーバー保護用)
resource "azurerm_network_security_group" "nsg_backend" {
  name                = "nsg-backend-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowAppFromFrontend"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "10.0.1.0/24" # Frontendサブネットのみ許可
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowSSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet" # 本来はここを管理者IPに限定推奨
    destination_address_prefix = "*"
  }
  tags = local.common_tags
}

# ==========================================
# 9. NSGとサブネットの関連付け
# ==========================================
# フロントエンドサブネットに nsg_frontend を紐付け
resource "azurerm_subnet_network_security_group_association" "frontend_assoc" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.nsg_frontend.id
}

# バックエンドサブネットに nsg_backend を紐付け (★ここを修正！)
resource "azurerm_subnet_network_security_group_association" "backend_assoc" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.nsg_backend.id
}
