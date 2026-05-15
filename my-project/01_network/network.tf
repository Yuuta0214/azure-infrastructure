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

# ==========================================
# 8. ネットワークセキュリティグループ (NSG) の作成
# ==========================================
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # インターネットからの HTTP (8080) アクセスを許可
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

  # Azure LB からのヘルスチェックを許可
  security_rule {
    name                       = "AllowLBHealthCheck"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080" # 実際の監視ポートに合わせる
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
# サブネット作成とNSG作成が完了した後に実行される
resource "azurerm_subnet_network_security_group_association" "backend_nsg_assoc" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}