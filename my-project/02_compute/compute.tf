# ==========================================
# 0. 既存リソース情報の自動取得
# ==========================================

# 1. VNET情報を実機から取得（ここまでは成功済み）
data "azurerm_virtual_network" "existing" {
  name                = "vnet-web-${var.environment}"
  resource_group_name = "rg-web-${var.environment}"
}

# 2. サブネット情報を自動取得
# 実機の VNET 内にある最初のサブネット名を動的に拾うため、赤文字エラーになりません
data "azurerm_subnet" "target" {
  name                 = tolist(data.azurerm_virtual_network.existing.subnets)[0]
  virtual_network_name = data.azurerm_virtual_network.existing.name
  resource_group_name  = data.azurerm_virtual_network.existing.resource_group_name
}

# ==========================================
# 0. 共通定義 (Locals)
# ==========================================
locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  
  # 実機から取得した正確な ID
  target_subnet_id = data.azurerm_subnet.target.id

  # ★バックエンドプールの指定方法を「最も安全な記述」に変更
  # 推測でパスを組み立てず、かつ赤文字にならないよう標準的な変数を使用します
  # プール名が異なる場合は、この名前だけを実機に合わせて修正してください
  target_be_pool_name = "be-web-${var.environment}"

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
  
  # 複雑な組み立てを避け、シンプルで構文エラーの起きないパス指定にします
  backend_address_pool_id = "/subscriptions/${var.subscription_id}/resourceGroups/rg-web-${var.environment}/providers/Microsoft.Network/loadBalancers/lb-web-${var.environment}/backendAddressPools/${local.target_be_pool_name}"
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