# 11. ネットワークインターフェース（NIC）の作成
# VMがネットワークと通信するための「接点」
# ==========================================
resource "azurerm_network_interface" "nic" {
  # 修正：変数を使用して環境ごとに名前を分ける
  name                = "nic-${var.project_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id # Backend Subnetに接続
    private_ip_address_allocation = "Dynamic"
  }
}
# ==========================================

# 12. NICとALBバックエンドプールの紐付け
# ALBに届いたパケットをこのVMのNICに流すための設定
# ==========================================
resource "azurerm_network_interface_backend_address_pool_association" "nic_lb_assoc" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_pool.id
}
# ==========================================

# 13. Linux 仮想マシン（VM）の作成
# 外部ファイル scripts/bootstrap.sh を読み込んで初期セットアップを自動化
# ==========================================
resource "azurerm_linux_virtual_machine" "vm" {
  # 修正：変数を使用して環境ごとに名前を分ける
  name                            = "vm-${var.project_name}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  
  # 【重要修正】サイズを変数化。env-test.tfvars 等で Standard_B2s に変更して対応します
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

  # 【修正ポイント】templatefile関数を使用して外部スクリプトを読み込み
  custom_data = base64encode(templatefile("${path.module}/scripts/bootstrap.sh", {
    # 修正：ホスト名も環境に応じて変わるように変更
    hostname       = "vm-${var.project_name}"
    admin_username = var.admin_username
  }))
}
# ==========================================