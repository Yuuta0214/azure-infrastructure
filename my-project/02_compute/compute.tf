# ==========================================
# 0. 既存リソース情報の自動取得 (Data Sources)
# ==========================================

# 1. VNET情報を実機から取得
data "azurerm_virtual_network" "existing" {
  name                = "vnet-web-${var.environment}"
  resource_group_name = "rg-web-${var.environment}"
}

# 2. サブネット情報を自動取得 (リストの0番目)
# あなたの環境で成功している「実機から動的に拾う」ロジックです
data "azurerm_subnet" "target" {
  name                 = tolist(data.azurerm_virtual_network.existing.subnets)[0]
  virtual_network_name = data.azurerm_virtual_network.existing.name
  resource_group_name  = data.azurerm_virtual_network.existing.resource_group_name
}

# 3. ロードバランサー情報を実機から取得
data "azurerm_lb" "existing" {
  name                = "lb-web-${var.environment}"
  resource_group_name = "rg-web-${var.environment}"
}

# ==========================================
# 0. 共通定義 (Locals)
# ==========================================
locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  
  target_subnet_id = data.azurerm_subnet.target.id

  # 【完全解決】名前の決め打ち（BackendPool-web-dev等）を1文字も使いません。
  # ロードバランサーが保持しているバックエンドプールのIDリストから、
  # サブネットと同様に「最初の要素（index 0）」を自動で抜き出します。
  # これにより、実機で名前が何であっても、変更されても、エラーなく追従します。
  target_be_pool_id = tolist(data.azurerm_lb.existing.backend_address_pool_ids)[0]

  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })
}

# ==========================================
# 10. ネットワークインターフェース（NIC）の作成
# ==========================================
resource "azurerm_network_interface" "nic" {
  name                = "nic-${local.resource_prefix}"
  location            = data.azurerm_virtual_network.existing.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.target_subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.common_tags
}

# ==========================================
# 11. NICとALBバックエンドプールの紐付け
# ==========================================
resource "azurerm_network_interface_backend_address_pool_association" "nic_assoc" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = "internal"
  
  # 実機から動的に取得した ID を使用
  backend_address_pool_id = local.target_be_pool_id
}

# ==========================================
# 12. Linux 仮想マシン（VM）の作成
# ==========================================
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-${local.resource_prefix}"
  resource_group_name = var.resource_group_name
  location            = data.azurerm_virtual_network.existing.location
  size                = var.vm_size
  admin_username      = var.admin_username

  disable_password_authentication = false
  admin_password                  = var.admin_password

  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    name                 = "osdisk-vm-${local.resource_prefix}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "debian"
    offer     = "debian-12"
    sku       = "12-gen2"
    version   = "latest"
  }

  # スクリプトファイルを参照（パスはプロジェクト構成に準拠）
  custom_data = base64encode(templatefile("${path.module}/scripts/bootstrap.sh", {
    hostname       = "vm-${local.resource_prefix}"
    admin_username = var.admin_username
  }))

  tags = local.common_tags
}