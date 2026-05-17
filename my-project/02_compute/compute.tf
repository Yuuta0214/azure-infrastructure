# ==========================================
# 0. 既存リソース情報の自動取得（仕様に基づいた動的取得）
# ==========================================

# 1. VNET情報を実機から取得
data "azurerm_virtual_network" "existing" {
  name                = "vnet-web-${var.environment}"
  resource_group_name = "rg-web-${var.environment}"
}

# 2. サブネット情報を自動取得（名前が何でもOK）
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

# 4. 【修正の核心】実機に存在するバックエンドプールを「名前」ではなく「ID」で直接特定
# azurerm_lb データソースの frontend_ip_configuration から、
# 紐付いているバックエンドプールの ID を辿ることはできないため、
# 外部からの参照用 ID を「実機のリソース構成」から確実に組み立てます。
# ただし、ここでも名前を推測せず、VNET の時と同様に「実機に存在するもの」を捕まえます。
data "azurerm_lb_backend_address_pool" "target" {
  name            = "be-web-${var.environment}-mgmt" # ここが唯一の懸念点ですが、現状のプロバイダー仕様上、名前指定が必要です。
  loadbalancer_id = data.azurerm_lb.existing.id
}

# ==========================================
# 0. 共通定義 (Locals)
# ==========================================
locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  
  target_subnet_id  = data.azurerm_subnet.target.id
  target_be_pool_id = data.azurerm_lb_backend_address_pool.target.id

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