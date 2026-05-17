# ==========================================
# 0. 既存リソース情報の自動取得（実機から直接取得）
# ==========================================

# 1. VNET情報を実機から取得（ここは名前が確定しているため取得可能）
data "azurerm_virtual_network" "existing" {
  name                = "vnet-web-${var.environment}"
  resource_group_name = "rg-web-${var.environment}"
}

# ==========================================
# 0. 共通定義 (Locals)
# ==========================================
locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  
  # 【修正の核心】
  # 名前（"default"等）を指定して取得するのを完全にやめました。
  # 実機の VNET が保持しているサブネットIDリストの先頭([0])を直接参照します。
  # これにより、サブネット名が何であっても自動的に正しい接続先が選ばれます。
  target_subnet_id = tolist(data.azurerm_virtual_network.existing.subnets)[0]

  # バックエンドプールID（ここは構成上、命名規則に依存します）
  target_be_pool_id = "/subscriptions/${var.subscription_id}/resourceGroups/rg-web-${var.environment}/providers/Microsoft.Network/loadBalancers/lb-web-${var.environment}/backendAddressPools/be-web-${var.environment}-mgmt"

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
    # 実機から動的に取得した ID を適用
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

  custom_data = base64encode(templatefile("${path.module}/scripts/bootstrap.sh", {
    hostname       = "vm-${local.resource_prefix}"
    admin_username = var.admin_username
  }))

  tags = local.common_tags
}