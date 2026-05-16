# ==========================================================================
# 02_compute / compute.tf
# ==========================================================================

# ==========================================
# 0. 共通定義 (Locals)
# base.tf 削除に伴い、整合性を維持するために必要な定義を移行
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
# 10. ネットワークインターフェース（NIC）の作成
# ==========================================
resource "azurerm_network_interface" "nic" {
  name                = "nic-${local.resource_prefix}"
  # 【整合性修正】01_network 層で作成済みのリソースグループと場所を変数から参照
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

# ==========================================
# 11. NICとALBバックエンドプールの紐付け
# ==========================================
resource "azurerm_network_interface_backend_address_pool_association" "nic_assoc" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = var.lb_backend_pool_id
}

# ==========================================
# 12. Linux 仮想マシン（VM）の作成
# ==========================================
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "vm-${local.resource_prefix}"
  # 【整合性修正】既存のリソースグループ名・場所を参照
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  
  # セキュリティ設計: パスワード認証を有効化
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

  # ------------------------------------------
  # 13. プロビジョニング (カスタムデータ)
  # ------------------------------------------
  # 【整合性修正】提示されたディレクトリ構造 (scripts/bootstrap.sh) に基づきパスを指定
  custom_data = base64encode(templatefile("${path.module}/scripts/bootstrap.sh", {
    hostname       = "vm-${local.resource_prefix}"
    admin_username = var.admin_username
  }))

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
      custom_data, # 運用中のスクリプト変更による意図しない再起動/再作成を防止
    ]
  }
}