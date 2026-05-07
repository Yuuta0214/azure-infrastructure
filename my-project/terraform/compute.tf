# ==========================================
# 0. 共通ローカル変数の定義 (運用・保守用)
# ==========================================
locals {
  # リソース名の接頭辞 (例: web-test)
  resource_prefix = "${var.project_name}-${var.environment}"

  # 動的なタグ生成: 実行時の日付を取得
  current_date = formatdate("YYYY-MM-DD", timestamp())

  # tfvarsのタグに動的な CreatedDate を結合
  common_tags = merge(var.tags, {
    CreatedDate = local.current_date
  })
}

# ==========================================
# 10. ネットワークインターフェース（NIC）の作成
# ==========================================
resource "azurerm_network_interface" "nic" {
  name                = "nic-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.common_tags

  # 日付タグが毎回更新されないよう、作成時のみの付与とする
  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

# ==========================================
# 11. NICとALBバックエンドプールの紐付け
# ==========================================
resource "azurerm_network_interface_backend_address_pool_association" "nic_lb_assoc" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_pool.id
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
  
  # パスワード認証を有効化
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
  custom_data = base64encode(templatefile("${path.module}/scripts/bootstrap.sh", {
    hostname       = "vm-${local.resource_prefix}"
    admin_username = var.admin_username
  }))

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      admin_password,    # パスワード変更による再起動防止
      tags["CreatedDate"], # 翌日以降のデプロイで日付が更新されるのを防止
    ]
  }
}