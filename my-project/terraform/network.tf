# 4. 仮想ネットワーク（VNet）の作成
# 設計図の「10.0.0.0/16」という大きなネットワーク空間を定義
# azurerm_virtual_network は、Azure用プラグイン（azurerm）が「VNetを作成する」専用のキーワード
# ==========================================
resource "azurerm_virtual_network" "vnet" {
    name                = "vnet-main"    # Azureポータル（管理画面）上で表示される、実際のネットワーク名
    address_space      = ["10.0.0.0/16"] # 構成図通りのセグメント
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}
# ==========================================


# 5. Frontend subnetの作成（ALB用）
# VNet（10.0.0.0/16）という敷地の中に 10.0.1.0/24という特定の区画を切り出す
# ==========================================
resource "azurerm_subnet" "frontend" {
    name                 = "snet-frontend"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.1.0/24"]
}
# ==========================================


# 6. Backend Subnetの作成（Docker VM用）
# VNet（10.0.0.0/16）という敷地の中に 10.0.2.0/24としてVMを配置するための区画を切り出す
# ==========================================
resource "azurerm_subnet" "backend" {
    name                 = "snet-backend"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.2.0/24"]
}
# ==========================================


# 7. Bastion Subnetの作成（管理用）
# Azure Bastionという管理機能を使いための専用サブネット
# 名前の指定が "AzureBastionSubnet" でなければならないという厳格な決まりがある
# ==========================================
resource "azurerm_subnet" "bastion" {
    name                 = "AzureBastionSubnet" #これは「決まり文句」
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.10.0/26"] # 構成図の通り管理セグメント
}
# ==========================================


# 8. ALB用パブリックIPの作成
# ==========================================
resource "azurerm_public_ip" "lb_pip" {
    name                = "pip-lb"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method   = "Static"
    sku                 = "Standard"
}
# ==========================================


# 9. Azure Load Balancer (ALB) の作成
# 外部からの通信をバックエンドへ振り分ける司令塔
# ==========================================
resource "azurerm_lb" "alb" {
    name                = "lb-main"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku                 = "Standard"

    frontend_ip_configuration {
        name                 = "LoadBalancerFrontEnd"
        public_ip_address_id = azurerm_public_ip.lb_pip.id
    }
}
# ==========================================


# 10. ALB バックエンドアドレスプールの作成
# 通信の転送先となるサーバーを登録するためのグループ
# ==========================================
resource "azurerm_lb_backend_address_pool" "lb_pool" {
    loadbalancer_id = azurerm_lb.alb.id
    name            = "BackEndAddressPool"
}
# ==========================================


# 11. ALB ヘルスプローブの作成
# VMが正常に動作しているか（80番ポート）を監視する仕組み
# ==========================================
resource "azurerm_lb_probe" "hp" {
    loadbalancer_id = azurerm_lb.alb.id
    name            = "http-running-probe"
    port            = 80
    protocol        = "Tcp"
}
# ==========================================


# 12. ALB 負荷分散ルールの作成
# 80番ポートで受け取った通信をバックエンドへ流すためのルール
# ==========================================
resource "azurerm_lb_rule" "lb_rule" {
    loadbalancer_id                = azurerm_lb.alb.id
    name                           = "LBRule-HTTP"
    protocol                       = "Tcp"
    frontend_port                  = 80
    backend_port                   = 80
    frontend_ip_configuration_name = "LoadBalancerFrontEnd"
    backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_pool.id]
    probe_id                       = azurerm_lb_probe.hp.id
}
# ==========================================


# 13. ネットワークセキュリティグループ（NSG）の作成
# 各サブネットの「門番」の役割を果たす箱を作成
# azurerm_network_security_group: ネットワークの門番（NSG）を作るための「決まり文句」
# ==========================================
resource "azurerm_network_security_group" "nsg" {
    name                = "nsg-main"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}
# ==========================================


# 14. NSGルールの作成（HTTP許可）
# 優先度100で、外から80番ポートへの通信を許可
# ==========================================
resource "azurerm_network_security_rule" "http" {
    name                        = "allow-http"
    priority                    = 100        # 数字が小さいほど優先度が高い
    direction                   = "Inbound"  # 「内向き」の通信（外から入ってくる）
    access                      = "Allow"    # 通信を「許可」する
    protocol                    = "Tcp"      # 通信方式
    source_port_range           = "*"        # 送信元のポート番号（制限なし）
    destination_port_range      = "80"       # 宛先のポート番号（HTTPの80番）
    source_address_prefix       = "*"        # 送信元のIP（世界中から許可）
    destination_address_prefix  = "*"        # 宛先のIP（このNSGがつく場所ならどこでも）
    resource_group_name         = azurerm_resource_group.rg.name
    network_security_group_name = azurerm_network_security_group.nsg.name # 8番で作ったNSGを指定
}
# ==========================================

# 15. NSGルールの作成（SSH許可）
# Bastionサブネット（10.0.10.0/26）からの管理通信のみを許可
# ==========================================
resource "azurerm_network_security_rule" "ssh" {
    name                        = "allow-ssh-from-bastion"
    priority                    = 110
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "10.0.10.0/26"
    destination_address_prefix  = "10.0.2.0/24"
    resource_group_name         = azurerm_resource_group.rg.name
    network_security_group_name = azurerm_network_security_group.nsg.name
}
# ==========================================


# 16. Frontend SubnetへのNSG紐付け
# ==========================================
resource "azurerm_subnet_network_security_group_association" "frontend" {
    subnet_id                 = azurerm_subnet.frontend.id
    network_security_group_id = azurerm_network_security_group.nsg.id
}
# ==========================================


# 17. Backend SubnetへのNSG紐付け
# ==========================================
resource "azurerm_subnet_network_security_group_association" "backend" {
    subnet_id                 = azurerm_subnet.backend.id
    network_security_group_id = azurerm_network_security_group.nsg.id
}
# ==========================================