# ==========================================
# 02_compute / env-prod.tfvars
# ==========================================

# ==========================================
# 1. 基盤・環境定義
# ==========================================
location     = "japaneast"
environment  = "prod"
project_name = "web"

# 【整合性修正】01_network 層で作成済みのリソースグループ名を指定
resource_group_name = "rg-web-prod"

# ==========================================
# 2. コンピューティング定義 (VMスペック)
# ==========================================
vm_size      = "Standard_D2s_v3"

# ==========================================
# 3. 認証・セキュリティ定義
# ==========================================
admin_username = "azureuser"
# 12文字以上および複雑性の要件を遵守
admin_password = "ComplexPasswordProd2026!"

# ==========================================
# 4. メタデータ定義 (運用管理用)
# ==========================================
# 01_network 側のタグ構成とプロジェクト基準を統一
tags = {
  BusinessUnit = "Production-Ops"
  CostCenter   = "WEB-101"
}

# ==========================================
# 5. ネットワーク参照定義 (01_network層との整合性)
# ==========================================
# 【整合性修正】01_network で作成されたリソース名を正確に反映させた ID
subnet_id          = "/subscriptions/0f273017-b259-421d-894c-ae7906f901c8/resourceGroups/rg-web-prod/providers/Microsoft.Network/virtualNetworks/vnet-web-prod/subnets/snet-backend"
lb_backend_pool_id = "/subscriptions/0f273017-b259-421d-894c-ae7906f901c8/resourceGroups/rg-web-prod/providers/Microsoft.Network/loadBalancers/lb-web-prod/backendAddressPools/be-web-prod"