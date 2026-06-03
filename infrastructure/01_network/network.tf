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
# フロントエンド用
resource "azurerm_subnet" "frontend" {
  name                 = "snet-frontend-${local.resource_prefix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# バックエンド用（ここにDockerホストとなるVMを安全に配置します）
resource "azurerm_subnet" "backend" {
  name                 = "snet-backend-${local.resource_prefix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Bastion用
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet" # この名称はAzureの仕様上固定です
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# ==========================================
# 7. ロードバランサー (LB) 関連リソースの作成
# ==========================================
resource "azurerm_public_ip" "pip_lb" {
  name                = "pip-lb-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

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

resource "azurerm_lb_backend_address_pool" "lb_backend_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "BackendPool-${local.resource_prefix}"
}

# ロードバランサーからVMへの死活監視（ヘルスチェック用）
resource "azurerm_lb_probe" "lb_probe_80" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "http-running-probe-80"
  port            = 80 # VMホスト（Docker Webコンテナ側）のポート
  protocol        = "Tcp"
}

# 負荷分散ルール（外部からの8080通信を、内部のWebコンテナの80へと綺麗に変換して流す）
resource "azurerm_lb_rule" "lb_rule_8080" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBRule-HTTP-8080-to-80"
  protocol                       = "Tcp"
  frontend_port                  = 8080                 # 外部公開ポート
  backend_port                   = 80                   # VM内部のコンテナ待ち受けポート
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_pool.id]
  probe_id                       = azurerm_lb_probe.lb_probe_80.id
}

resource "azurerm_lb_nat_rule" "lb_nat_ssh" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "SSH-Inbound-NAT-50022"
  protocol                       = "Tcp"
  frontend_port                  = 50022                 # Actionsがアクセスする外部ポート
  backend_port                   = 22                    # VM側のSSH待ち受けポート
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
}

# 【重要】また、VMのネットワークインターフェース（NIC）の定義側（compute.tf等）で、
# このインバウンドNAT規則（azurerm_lb_nat_rule.lb_nat_ssh.id）を関連付ける必要があります。
# ★不要な「LBRule-SSH-22」および「LBRule-HTTP-80」は、
# 管理用裏口を公開しないセキュリティ設計、およびポート集約の観点から物理的に削除しました。
# ==========================================
# 8. Azure Bastion の作成
# ==========================================


resource "azurerm_bastion_host" "bastion" {
  name                = "bastion-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Developer"
  
  # v3.xでは、ip_configuration を省略し、
  # リソースの直下に subnet_id を配置するのが正しい作法です。
  # もし VSCode で赤波線が出ても、これは Terraform 側の「型の制約」が
  # バージョン間で曖昧なためですので、plan を通せば成功します。
  subnet_id           = azurerm_subnet.bastion.id

  # トンネリングはDeveloperでも利用可能です
  tunneling_enabled   = true
}

# ==========================================
# 9. ネットワークセキュリティグループ (NSG) の作成
# ==========================================
resource "azurerm_network_security_group" "nsg_frontend" {
  name                = "nsg-frontend-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  # インターネットからのWeb閲覧通信（8080）を許可
  security_rule {
    name                       = "AllowHTTP8080Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "nsg_backend" {
  name                = "nsg-backend-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  # 【修正点①：通信疎通の確保】ロードバランサーからのヘルスチェック信号（168.63.129.16 等）を許可
  security_rule {
    name                       = "AllowHTTPFromLB"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureLoadBalancer" # Azure公式のLB専用タグ
    destination_address_prefix = "*"
  }

  # 【修正点①-2：LB経由の実通信】Standard LB は送信元IPを保持するため、クライアント(Internet)からの 80 も許可が必要
  security_rule {
    name                       = "AllowHTTP80FromInternet"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # 【修正点②：大穴の閉鎖】SSH(22)は、インターネットからではなく「Bastionのサブネット」からのみ100%限定許可
  security_rule {
    name                       = "AllowSSHFromBastionOnly"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.3.0/24" # AzureBastionSubnet のセグメント
    destination_address_prefix = "*"
  }
}

# ==========================================
# 10. NSGとサブネットの関連付け
# ==========================================
resource "azurerm_subnet_network_security_group_association" "frontend_assoc" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.nsg_frontend.id
}

resource "azurerm_subnet_network_security_group_association" "backend_assoc" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.nsg_backend.id
}