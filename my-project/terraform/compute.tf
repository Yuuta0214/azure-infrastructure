# ==========================================
# 11. ネットワークインターフェース（NIC）の作成
# ==========================================
resource "azurerm_network_interface" "nic" {
  # 【修正】環境ごとに名前を分離
  name                = "nic-${var.project_name}-${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = { Environment = var.env }
}

# ==========================================
# 12. NICとALBバックエンドプールの紐付け（Web通信用）
# ==========================================
resource "azurerm_network_interface_backend_address_pool_association" "nic_lb_assoc" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_pool.id
}

# ==========================================
# 12-1. NICとALB NATルールの紐付け（SSH接続用）
# ==========================================
resource "azurerm_network_interface_nat_rule_association" "nic_nat_assoc" {
  network_interface_id  = azurerm_network_interface.nic.id
  ip_configuration_name = "internal"
  nat_rule_id           = azurerm_lb_nat_rule.ssh.id
}

# ==========================================
# 13. Linux 仮想マシン（VM）の作成
# ==========================================
resource "azurerm_linux_virtual_machine" "vm" {
  # 【修正】環境ごとに名前を分離
  name                            = "vm-${var.project_name}-${var.env}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  
  # パスワード設定
  admin_password                  = var.admin_password
  
  # 【重要】SSHキーが指定されている場合は、セキュリティ向上のためパスワード認証を無効化する
  disable_password_authentication = var.ssh_public_key != "" ? true : false

  # 【追加】SSH公開鍵認証の設定（OSセキュリティベストプラクティス）
  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_key != "" ? [1] :[]
    content {
      username   = var.admin_username
      public_key = var.ssh_public_key
    }
  }

  network_interface_ids =[
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    # 【修正】Standard_LRS（HDD）は非推奨。StandardSSD_LRS（SSD）に変更
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "debian"
    offer     = "debian-12"
    sku       = "12-gen2"
    version   = "latest"
  }

  # 【修正】OS内部のホスト名にも環境名を付与
  custom_data = base64encode(templatefile("${path.module}/scripts/bootstrap.sh", {
    hostname       = "vm-${var.project_name}-${var.env}"
    admin_username = var.admin_username
  }))

  # 冪等性を担保するため、再起動などで設定が飛ばないよう考慮
  provision_vm_agent = true

  tags = {
    Environment = var.env
    Project     = var.project_name
  }
}