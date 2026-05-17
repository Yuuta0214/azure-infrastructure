# ==========================================
# 0. 共通定義 (Locals)
# ==========================================
locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  network_rg      = "rg-web-${var.environment}"
  
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })

  target_subnet_id = "/subscriptions/${var.subscription_id}/resourceGroups/${local.network_rg}/providers/Microsoft.Network/virtualNetworks/vnet-web-${var.environment}/subnets/default"
  target_be_pool_id = "/subscriptions/${var.subscription_id}/resourceGroups/${local.network_rg}/providers/Microsoft.Network/loadBalancers/lb-web-${var.environment}/backendAddressPools/be-web-${var.environment}-mgmt"
}

# ==========================================
# 0.5 リージョン不整合を防ぐためのVNET参照
# ==========================================
# VNETの「正確な場所(location)」をAPIから直接取得します
data "azurerm_virtual_network" "existing" {
  name                = "vnet-web-${var.environment}"
  resource_group_name = local.network_rg
}

# ==========================================
# 10. ネットワークインターフェース（NIC）の作成
# ==========================================
resource "azurerm_network_interface" "nic" {
  name                = "nic-${local.resource_prefix}"
  # var.location ではなく、VNETが存在するリージョンを強制指定して不整合を解消
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

# (12. VMリソースも同様に location = data.azurerm_virtual_network.existing.location に修正してください)