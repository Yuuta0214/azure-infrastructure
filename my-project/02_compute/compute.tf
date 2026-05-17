# ==========================================
# 0. 共通定義 (Locals)
# ==========================================
locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })
}

# ==========================================
# 0.5 既存リソースの動的取得 (Data Sources)
# ==========================================
# NICを作成するのと同じリソースグループ内からリソースを特定します
data "azurerm_subnet" "existing" {
  name                 = "snet-web-${var.environment}"
  virtual_network_name = "vnet-web-${var.environment}"
  # NIC作成場所（var.resource_group_name）から探すように修正
  resource_group_name  = var.resource_group_name 
}

data "azurerm_lb_backend_address_pool" "existing" {
  name            = "be-web-${var.environment}"
  # ロードバランサーのID組み立てにも var.resource_group_name を使用
  loadbalancer_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/loadBalancers/lb-web-${var.environment}"
}

# ==========================================
# 10. ネットワークインターフェース（NIC）の作成
# ==========================================
resource "azurerm_network_interface" "nic" {
  name                = "nic-${local.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    # data ブロックで動的に取得した正確な ID を適用
    subnet_id                     = data.azurerm_subnet.existing.id
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
  # data ブロックで動的に取得した正確な ID を適用
  backend_address_pool_id = data.azurerm_lb_backend_address_pool.existing.id
}

# ==========================================
# 12. Linux 仮想マシン（VM）の作成
# ==========================================
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-${local.resource_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
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