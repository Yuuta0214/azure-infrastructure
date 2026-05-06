# 4. 仮想ネットワーク（VNet）の作成
# ==========================================
resource "azurerm_virtual_network" "vnet" {
    name                = "vnet-${var.project_name}" 
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

# 5. Frontend subnetの作成（ALB用）
# ==========================================
resource "azurerm_subnet" "frontend" {
    name                 = "snet-frontend-${var.project_name}"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.1.0/24"]
}

# 6. Backend Subnetの作成（Docker VM用）
# ==========================================
resource "azurerm_subnet" "backend" {
    name                 = "snet-backend-${var.project_name}"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.2.0/24"]
}

# 7. Bastion Subnetの作成（管理用）
# ==========================================
resource "azurerm_subnet" "bastion" {
    name                 = "AzureBastionSubnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.10.0/26"]
}

# 8. ALB用パブリックIPの作成
# ==========================================
resource "azurerm_public_ip" "lb_pip" {
    name                = "pip-lb-${var.project_name}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method   = "Static"
    sku                 = "Standard"
}

# 9. Azure Load Balancer (ALB) の作成
# ==========================================
resource "azurerm_lb" "alb" {
    name                = "lb-${var.project_name}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku                 = "Standard"

    frontend_ip_configuration {
        name                 = "LoadBalancerFrontEnd"
        public_ip_address_id = azurerm_public_ip.lb_pip.id
    }
}

# 9-1. ALBバックエンドプールの作成
# ==========================================
resource "azurerm_lb_backend_address_pool" "lb_pool" {
    loadbalancer_id = azurerm_lb.alb.id
    name            = "BackEndAddressPool"
}

# 10. ネットワークセキュリティグループ（NSG）の作成とルールの定義
# ==========================================
resource "azurerm_network_security_group" "nsg" {
    name                = "nsg-${var.project_name}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    # SSH (Port 22) の許可設定
    # GitHub Actions からのインバウンド通信を許可するために必須です
    security_rule {
        name                       = "AllowSSHInbound"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# 11. NSGとバックエンドサブネットの関連付け
# これにより、上記で定義したSSH許可ルールがVMの所属するサブネットに適用されます
# ==========================================
resource "azurerm_subnet_network_security_group_association" "backend_nsg_assoc" {
    subnet_id                 = azurerm_subnet.backend.id
    network_security_group_id = azurerm_network_security_group.nsg.id
}