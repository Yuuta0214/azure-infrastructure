# ==========================================
# 0. 既存リソース情報の自動取得 (Data Sources)
# ==========================================

# 1. VNET情報を実機から取得
data "azurerm_virtual_network" "existing" {
  name                = "vnet-web-${var.environment}"
  resource_group_name = "rg-web-${var.environment}"
}

# 2. サブネット情報を自動取得 (リストの0番目)
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

# 4. 【重要】方法A：実機のバックエンドプール名を指定して情報を取得
# ※変数を介して「BackendPool-web-dev」を渡すことで、存在しない属性エラーを回避します
data "azurerm_lb_backend_address_pool" "target" {
  name            = var.lb_backend_pool_name
  loadbalancer_id = data.azurerm_lb.existing.id
}

# ==========================================
# 0. 共通定義 (Locals)
# ==========================================
locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  
  target_subnet_id = data.azurerm_subnet.target.id

  # データソースから取得した「本物のID」をセットします
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
  
  # dataブロックで解決した正確なIDを使用
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