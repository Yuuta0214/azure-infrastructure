# ==========================================
# 1. 基盤・環境定義
# ==========================================
location     = "japanwest"
environment  = "dev"
project_name = "web"

# ==========================================
# 2. コンピューティング定義 (VMスペック)
# ==========================================
vm_size      = "Standard_D2s_v3"

# ==========================================
# 3. 認証・セキュリティ定義
# ==========================================
admin_username = "azureuser"
ssh_public_key = ""

# ==========================================
# 4. メタデータ定義 (運用管理用)
# ==========================================
tags = {
  BusinessUnit = "Production-dev"
  CostCenter   = "WEB-201"
}

# ==========================================
# 5. ネットワーク参照定義
# ==========================================
# 【修正】エラーの原因：リソースグループ名が重複（rg-web-dev/rg-web-dev）していたパスを修正
# 正しい形式：/subscriptions/{sub_id}/resourceGroups/{rg_name}/providers/Microsoft.Network/virtualNetworks/{vnet_name}/subnets/{snet_name}
subnet_id          = "/subscriptions/0f273017-b259-421d-894c-ae7906f901c8/resourceGroups/rg-web-dev/providers/Microsoft.Network/virtualNetworks/vnet-web-dev/subnets/snet-backend-web-dev"

# 【修正】バックエンドプールIDも同様に、末尾のリソース名を現在の構成に合わせて修正
lb_backend_pool_id = "/subscriptions/0f273017-b259-421d-894c-ae7906f901c8/resourceGroups/rg-web-dev/providers/Microsoft.Network/loadBalancers/lbe-web-dev/backendAddressPools/be-pool-web-dev"