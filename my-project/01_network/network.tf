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
  
  # 【重要】VNetの作成完了を明示的に待機させ、参照エラーを防止
  depends_on = [azurerm_virtual_network.vnet]
}

# 【ベストプラクティス：追加】
# Subnet作成完了後、Azure内部のAPIに情報が完全に伝搬されるまで30秒待機
# これにより、compute.tf 側での NIC 作成時の参照エラー（400 Bad Request）を確実に防ぎます
resource "time_sleep" "wait_for_subnet" {
  depends_on      = [azurerm_subnet.backend]
  create_duration = "30s"
}

# ==========================================
# 7. パブリックIP（ロードバランサー用）
# ==========================================
resource "azurerm_public_ip" "lb_pip" {
  name                = "pip-lb-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# ==========================================
# 8. ネットワークセキュリティグループ（NSG）の定義
# ==========================================
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # HTTP (8080) 接続を許可（Web アプリ用）
  security_rule {
    name                       = "AllowHTTP8080"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # ロードバランサーからのヘルスチェックを許可
  security_rule {
    name                       = "AllowLBAccess"
    priority                   = 101
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
  network_security_group_id = azurerm_network_security_group.nsg.id
}