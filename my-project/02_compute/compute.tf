# ==========================================
# 0. 既存リソース情報の自動取得 (Data Sources)
# ==========================================

# 1. VNET情報を実機から取得（命名規則を01_networkと完全一致化）
data "azurerm_virtual_network" "existing" {
  name                = "vnet-${var.project_name}-${var.environment}" # vnet-web-dev
  resource_group_name = var.resource_group_name                      # 変数から安全に取得
}

# 2. サブネット情報を自動取得
data "azurerm_subnet" "target" {
  name                 = "snet-backend-${var.project_name}-${var.environment}" # snet-backend-web-dev
  virtual_network_name = data.azurerm_virtual_network.existing.name
  resource_group_name  = var.resource_group_name
}

# 3. ロードバランサー情報を実機から取得
data "azurerm_lb" "existing" {
  name                = "lb-${var.project_name}-${var.environment}" # lb-web-dev
  resource_group_name = var.resource_group_name
}

# 4. 実機のバックエンドプール情報を取得
data "azurerm_lb_backend_address_pool" "target" {
  name            = var.lb_backend_pool_name # BackendPool-web-dev
  loadbalancer_id = data.azurerm_lb.existing.id
}

# ==========================================
# 0. 共通定義 (Locals)
# ==========================================
locals {
  resource_prefix = "${var.project_name}-${var.environment}"

  # 01_network/network.tf の azurerm_lb_nat_rule.lb_nat_ssh.name と一致
  lb_nat_rule_name = "SSH-Inbound-NAT-50022"

  target_subnet_id  = data.azurerm_subnet.target.id
  target_be_pool_id = data.azurerm_lb_backend_address_pool.target.id
  # azurerm 3.x には lb_nat_rule の data source がないため、LB ID から ARM 形式で組み立てる
  target_nat_rule_id = "${data.azurerm_lb.existing.id}/inboundNatRules/${local.lb_nat_rule_name}"

  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Layer       = "02_Compute"
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
  backend_address_pool_id = local.target_be_pool_id
}

# ==========================================
# 11-2. NICとLBインバウンドNAT規則（SSH）の紐付け
# ==========================================
resource "azurerm_network_interface_nat_rule_association" "ssh_nat" {
  network_interface_id  = azurerm_network_interface.nic.id
  ip_configuration_name = "internal"
  nat_rule_id           = local.target_nat_rule_id
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

  # パスワード認証およびSSH公開鍵の併用
  disable_password_authentication = true
  admin_password                  = var.admin_password

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

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

# ==========================================
# 13. 外部連携・CI/CDパイプライン用の情報参照 & 出力 (Outputs)
# ==========================================

# ネットワーク層（01_network）で作成済みのロードバランサー用パブリックIPを参照
data "azurerm_public_ip" "lb_pip" {
  name                = "pip-lb-${local.resource_prefix}" # pip-lb-web-dev
  resource_group_name = var.resource_group_name
}

# Webサイトのアクセス確認URL用にLBのパブリックIPを出力
output "lb_public_ip" {
  value       = data.azurerm_public_ip.lb_pip.ip_address
  description = "ロードバランサーのパブリックIP（Webサイト閲覧用）"
}

# 【最重要】GitHub ActionsがAzure Bastion経由でSSHトンネルを掘るために使用するID
output "vm_resource_id" {
  value       = azurerm_linux_virtual_machine.vm.id
  description = "Azure Bastionトンネル確立ターゲットとなるVMのリソースID"
}

# 保守・トラブルシューティング用のプライベートIP出力
output "vm_private_ip" {
  value       = azurerm_linux_virtual_machine.vm.private_ip_address
  description = "VMの内部プライベートIP"
}