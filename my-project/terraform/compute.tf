# 18. ネットワークインターフェース（NIC）の作成
# VMがネットワークと通信するための「接点」
# ==========================================
resource "azurerm_network_interface" "nic" {
  name                = "nic-docker-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id # Backend Subnetに接続
    private_ip_address_allocation = "Dynamic"
  }
}

# 19. NICとALBバックエンドプールの紐付け
# ALBに届いたパケットをこのVMのNICに流すための設定
# ==========================================
resource "azurerm_network_interface_backend_address_pool_association" "nic_lb_assoc" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_pool.id
}

# 20. Linux 仮想マシン（VM）の作成
# 外部ファイル scripts/bootstrap.sh を読み込んで初期セットアップを自動化
# ==========================================
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "vm-docker-host"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_B1s"
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

  # 【修正ポイント】templatefile関数を使用して外部スクリプトを読み込み
  # 1. scripts/bootstrap.sh を参照
  # 2. 変数 (hostname, admin_username) をスクリプト内に注入
  # 3. Azureが解釈できる base64 形式に変換
  custom_data = base64encode(templatefile("${path.module}/scripts/bootstrap.sh", {
    hostname       = "vm-docker-host"
    admin_username = var.admin_username
  }))
}
# ==========================================