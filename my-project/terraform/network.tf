# 4. 仮想ネットワーク（VNet）の作成
# ==========================================
resource "azurerm_virtual_network" "vnet" {
    # 修正：固定名から変数名に変更
    name                = "vnet-${var.project_name}" 
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}
# ==========================================

# 5. Frontend subnetの作成（ALB用）
# ==========================================
resource "azurerm_subnet" "frontend" {
    # 修正：ここも変数を含めることで環境を区別
    name                 = "snet-frontend-${var.project_name}"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.1.0/24"]
}
# ==========================================

# 6. Backend Subnetの作成（Docker VM用）
# ==========================================
resource "azurerm_subnet" "backend" {
    # 修正：変数を含める
    name                 = "snet-backend-${var.project_name}"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.2.0/24"]
}
# ==========================================

# 7. Bastion Subnetの作成（管理用）
# 名前の指定が "AzureBastionSubnet" でなければならないという厳格な決まりがある
# ==========================================
resource "azurerm_subnet" "bastion" {
    name                 = "AzureBastionSubnet" # これは「修正不要」です（Azureの仕様のため）
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.10.0/26"]
}
# ==========================================

# 8. ALB用パブリックIPの作成
# ==========================================
resource "azurerm_public_ip" "lb_pip" {
    # 修正：変数を含める
    name                = "pip-lb-${var.project_name}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method   = "Static"
    sku                 = "Standard"
}
# ==========================================

# 9. Azure Load Balancer (ALB) の作成
# ==========================================
resource "azurerm_lb" "alb" {
    # 修正：変数を含める
    name                = "lb-${var.project_name}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku                 = "Standard"

    frontend_ip_configuration {
        name                 = "LoadBalancerFrontEnd"
        public_ip_address_id = azurerm_public_ip.lb_pip.id
    }
}
# ==========================================

# 10. ネットワークセキュリティグループ（NSG）の作成
# ==========================================
resource "azurerm_network_security_group" "nsg" {
    # 修正：変数を含める
    name                = "nsg-${var.project_name}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}
# ==========================================

# ※ セクション10〜12, 14〜17については、リソース間の「ID参照」で動いているため、
# 名前（name）が定義されている箇所だけ上記のように `${var.project_name}` を追加すればOKです。