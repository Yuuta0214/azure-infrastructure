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
}

# ==========================================
# 11. NICとALBバックエンドプールの紐付け
# ==========================================
resource "azurerm_network_interface_backend_address_pool_association" "nic_lb_assoc" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_pool.id
}

# ※【セキュリティ設計】
# インターネットからの直接的なSSH攻撃を防ぐため、LB経由のSSH用NATルールは一切定義しません。
# メンテナンス時は、別途構築するAzure Bastion経由でのアクセスを想定します。

# ==========================================
# 12. Linux 仮想マシン（VM）の作成
# ==========================================
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "vm-${local.resource_prefix}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  
  # 【修正ポイント】GitHub Secretsのパスワードを使用するためパスワード認証を有効化
  # これにより、公開鍵(SSH_PUBLIC_KEY)がなくても構築が成功します
  disable_password_authentication = false
  admin_password                  = var.admin_password

  # SSH公開鍵ブロックは、Secretsに鍵が存在しないため削除しました
  # 今後は admin_password を使用してBastion経由でログインします

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  # ストレージ設定
  os_disk {
    name                 = "osdisk-vm-${local.resource_prefix}"
    caching               = "ReadWrite"
    storage_account_type = "StandardSSD_LRS" # 性能とコストの最適解
  }

  # OSイメージ（最新の安定版Debian 12を指定）
  source_image_reference {
    publisher = "debian"
    offer     = "debian-12"
    sku       = "12-gen2"
    version   = "latest"
  }

  # 13. プロビジョニング（Cloud-init）の設定
  # 外部スクリプトを読み込み、Ansibleが動作可能な状態（Python導入等）まで自動化します
  custom_data = base64encode(templatefile("${path.module}/scripts/bootstrap.sh", {
    hostname       = "vm-${local.resource_prefix}"
    admin_username = var.admin_username
  }))

  # 【ベストプラクティス】マネージド ID (SystemAssigned) の有効化
  # インスタンス自体に権限を持たせ、将来的にシークレットなしで各種Azureサービスへ接続可能にします
  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags

  # インフラ変更時の挙動制御
  lifecycle {
    ignore_changes = [
      admin_password, # パスワード変更による意図しない再起動を防止
    ]
  }
}