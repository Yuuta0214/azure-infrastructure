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
# 【整合性修正】variables.tfおよびcompute.tfで必須となっているパスワード定義を追加
# 12文字以上のAzure要件およびvariables.tfのバリデーションに準拠する必要があります
admin_password = "ComplexPasswordDev2026!"
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
# 【修正】01_network層との整合性：リソースグループ名が重複（rg-web-dev/rg-web-dev）していたパスを修正
subnet_id          = "/subscriptions/0f273017-b259-421d-894c-ae7906f901c8/resourceGroups/rg-web-dev/providers/Microsoft.Network/virtualNetworks/vnet-web-dev/subnets/snet-backend"

# 【修正】compute.tfの15行目で参照されている変数を追加（network層のLBリソースを指定）
lb_backend_pool_id = "/subscriptions/0f273017-b259-421d-894c-ae7906f901c8/resourceGroups/rg-web-dev/providers/Microsoft.Network/loadBalancers/lb-web-dev/backendAddressPools/be-web-dev"