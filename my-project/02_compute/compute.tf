# ==========================================================================
# 0. ネットワーク情報の定義
# 他フォルダとの通信を行わず、変数を介してIDを直接指定する形に修正します。
# ※実際に使用するIDは variables.tf または tfvars で管理します。
# ==========================================================================

# ==========================================
# 10. ネットワークインターフェース（NIC）の作成
# ==========================================
resource "azurerm_network_interface" "nic" {
  name                = "nic-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    # 【整合性確認】variables.tf の var.subnet_id を参照
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  # main.tf (base.tf) で定義された local.common_tags を参照
  tags = local.common_tags

  # 運用保守: 日付タグが毎回更新されないよう、作成時のみの付与とする
  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

# ==========================================
# 11. NICとALBバックエンドプールの紐付け
# ==========================================
resource "azurerm_network_interface_backend_address_pool_association" "nic_alb_assoc" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = "internal"
  # 【整合性修正】variables.tf で定義した変数名 (lb_backend_pool_id) に修正
  backend_address_pool_id = var.lb_backend_pool_id
}

# ==========================================
# 12. Linux 仮想マシン（VM）の作成
# ==========================================
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "vm-${local.resource_prefix}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  
  # セキュリティ設計: パスワード認証を有効化 (variables.tfのバリデーションに準拠)
  disable_password_authentication = false
  admin_password                  = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

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

  # 13. プロビジョニング（Cloud-init）
  # 運用保守: path.module を使用して相対パスの不整合を防止
  custom_data = base64encode(templatefile("${path.module}/bootstrap.sh", {
    hostname       = "vm-${local.resource_prefix}"
    admin_username = var.admin_username
  }))

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}