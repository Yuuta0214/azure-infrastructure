# ==========================================
# 02_compute / env-dev.tfvars
# ==========================================

# ==========================================
# 1. 基盤・環境定義
# ==========================================
# 【整合性修正】01_network 側の env-dev.tfvars と完全に一致させる
location     = "japanwest"
environment  = "dev"
project_name = "web"

# 【整合性修正】01_network 層で作成済みのリソースグループを指定
resource_group_name = "rg-web-dev"

# ==========================================
# 2. コンピューティング定義 (VMスペック)
# ==========================================
vm_size      = "Standard_D2s_v3"

# ==========================================
# 3. 認証・セキュリティ定義
# ==========================================
admin_username = "azureuser"
# 12文字以上および複雑性の要件を遵守
admin_password = "ComplexPasswordDev2026!"

# ==========================================
# 4. メタデータ定義 (運用管理用)
# ==========================================
# 【整合性修正】01_network 側のタグ構成（Production-Dev / WEB-201）を継承
tags = {
  BusinessUnit = "Production-Dev"
  CostCenter   = "WEB-201"
}

# ==========================================
# 5. ネットワーク参照定義 (01_network層との整合性)
# ==========================================
# 【整合性修正】01_network で作成されたリソース名を正確に反映させた ID
subnet_id          = "/subscriptions/0f273017-b259-421d-894c-ae7906f901c8/resourceGroups/rg-web-dev/providers/Microsoft.Network/virtualNetworks/vnet-web-dev/subnets/snet-backend"
lb_backend_pool_id = "/subscriptions/0f273017-b259-421d-894c-ae7906f901c8/resourceGroups/rg-web-dev/providers/Microsoft.Network/loadBalancers/lb-web-dev/backendAddressPools/be-web-dev"