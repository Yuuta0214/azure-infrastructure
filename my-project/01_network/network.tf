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
# 7. ロードバランサー用パブリックIP
# ==========================================
resource "azurerm_public_ip" "pip_lb" {
  name                = "pip-lb-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard" # Standard SKU を使用することで高い可用性を確保
  tags                = local.common_tags
}

# ==========================================
# 8. ネットワークセキュリティグループ（NSG）の定義
# ==========================================
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # アプリケーション通信（8080ポート）を許可
  security_rule {
    name                       = "AllowAppInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # ロードバランサーからのヘルスチェック（80ポート）を許可
  security_rule {
    name                       = "AllowLBHealthCheck"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # 【修正：セキュリティのベストプラクティス】
  # 管理用 SSH（22ポート）: インターネット全体(Internet)からの許可は攻撃リスクが非常に高いため、
  # 運用時は特定の「管理者IP」等に限定することを強く推奨。一旦、デフォルト動作は維持しつつ
  # タグを用いた内部通信の制限等を考慮する構成にします。
  security_rule {
    name                       = "AllowSSHInbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet" # 本番運用時は特定の管理拠点IPへの変更を推奨
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# ==========================================
# 9. NSGとサブネットの関連付け
# ==========================================
# サブネット作成とNSG作成が完了した後に実行されるよう、依存関係を整理します
resource "azurerm_subnet_network_security_group_association" "backend_assoc" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.nsg.id

  # 【ベストプラクティス：保守】
  # 関連付けがサブネットの変更中に競合しないよう、明示的な依存関係は記述しませんが
  # Terraformのリソース参照（id）により自動的に制御されます。
}