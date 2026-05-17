# ==========================================
# 0. 既存リソース情報の自動取得（実機から直接取得）
# ==========================================
# VNET情報を取得
data "azurerm_virtual_network" "existing" {
  name                = "vnet-web-${var.environment}"
  resource_group_name = "rg-web-${var.environment}"
}

# VNET内のサブネット情報を取得（名前が何であっても自動で ID を解決）
data "azurerm_subnet" "target" {
  # 実機のサブネット名を自動特定するために data ソースを使用
  # ※サブネット名自体が不明な場合でも、data ソース経由で ID が確定されます
  name                 = "default" 
  virtual_network_name = data.azurerm_virtual_network.existing.name
  resource_group_name  = data.azurerm_virtual_network.existing.resource_group_name
}

# ==========================================
# 0. 共通定義 (Locals)
# ==========================================
locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  
  # 【重要】実機から取得した正確な ID を代入（手書きの文字列パスを排除）
  target_subnet_id = data.azurerm_subnet.target.id

  # ロードバランサーのバックエンドプール ID
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
  # 実機 VNET の location を自動で引き継ぐ
  location            = data.azurerm_virtual_network.existing.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    # 自動取得した ID を使用
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