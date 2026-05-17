# ==========================================
# 0. 共通定義 (Locals)
# ==========================================
locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  
  # ネットワークが存在するRG名
  network_rg      = "rg-web-${var.environment}"
  
  # エディタの赤表示（参照エラー）を解決するために再定義
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })

  # 名前検索（dataブロック）による失敗を回避するため、リソースIDを直接構築
  # 画像から確定した「default」と「be-web-dev-mgmt」を埋め込み
  target_subnet_id = "/subscriptions/${var.subscription_id}/resourceGroups/${local.network_rg}/providers/Microsoft.Network/virtualNetworks/vnet-web-${var.environment}/subnets/default"
  target_be_pool_id = "/subscriptions/${var.subscription_id}/resourceGroups/${local.network_rg}/providers/Microsoft.Network/loadBalancers/lb-web-${var.environment}/backendAddressPools/be-web-${var.environment}-mgmt"
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

  # スクリプトディレクトリがない場合のエラーを防ぐため、存在を確認してください
  custom_data = base64encode(templatefile("${path.module}/scripts/bootstrap.sh", {
    hostname       = "vm-${local.resource_prefix}"
    admin_username = var.admin_username
  }))

  tags = local.common_tags
}