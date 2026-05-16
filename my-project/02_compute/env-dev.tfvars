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
admin_password = "REPLACE_WITH_YOUR_SECURE_DEV_PASSWORD_12chars"
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
# 【修正】リソースグループ名やVNet名の整合性をdev環境用に修正
# 正しい形式：/subscriptions/{sub_id}/resourceGroups/{rg_name}/providers/Microsoft.Network/virtualNetworks/{vnet_name}/subnets/{snet_name}
subnet_id          = "/subscriptions/0f273017-b259-421d-894c-ae7906f901c8/resourceGroups/rg-web-dev/providers/Microsoft.Network/virtualNetworks/vnet-web-dev/subnets/snet-backend"

# 【整合性修正】compute.tf (11. NICとLBの紐付け) で使用される変数を追加
# 01_network で構築した dev環境用のLBバックエンドプールを指定します
lb_backend_pool_id = "/subscriptions/0f273017-b259-421d-894c-ae7906f901c8/resourceGroups/rg-web-dev/providers/Microsoft.Network/loadBalancers/lbi-web-dev/backendAddressPools/lbi-backend-pool"