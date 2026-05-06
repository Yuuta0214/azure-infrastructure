# 11. ネットワークインターフェース（NIC）の作成
# ==========================================
resource "azurerm_network_interface" "nic" {
  name                = "nic-${var.project_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

# 12. NICとALBバックエンドプールの紐付け（Web通信用）
# ==========================================
resource "azurerm_network_interface_backend_address_pool_association" "nic_lb_assoc" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_pool.id
}

# 【追加】12-1. NICとALB NATルールの紐付け（SSH接続用）
# これがないと、ALBに届いたSSHパケットがVMのNICまで転送されません
# ==========================================
resource "azurerm_network_interface_nat_rule_association" "nic_nat_assoc" {
  network_interface_id  = azurerm_network_interface.nic.id
  ip_configuration_name = "internal"
  nat_rule_id           = azurerm_lb_nat_rule.ssh.id # network.tfで定義したNATルールのID
}

# 13. Linux 仮想マシン（VM）の作成
# ==========================================
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "vm-${var.project_name}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "debian"
    offer     = "debian-12"
    sku       = "12-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/scripts/bootstrap.sh", {
    hostname       = "vm-${var.project_name}"
    admin_username = var.admin_username
  }))
}