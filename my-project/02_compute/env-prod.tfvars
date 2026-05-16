# ==========================================
# 1. 基盤・環境定義
# ==========================================
location     = "japaneast"
environment  = "prod"
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
# ※実際の運用では GitHub Secrets 経由で上書きすることを推奨します
admin_password = "REPLACE_WITH_YOUR_SECURE_PASSWORD_12chars"
ssh_public_key = ""

# ==========================================
# 4. メタデータ定義 (運用管理用)
# ==========================================
tags = {
  BusinessUnit = "Production-Ops"
  CostCenter   = "WEB-101"
}

# ==========================================
# 5. ネットワーク参照定義 (追記箇所)
# ==========================================
# 【修正】プレースホルダーを実測値のサブスクリプションIDに置換し、本番環境のパスに修正
subnet_id          = "/subscriptions/0f273017-b259-421d-894c-ae7906f901c8/resourceGroups/rg-web-prod/providers/Microsoft.Network/virtualNetworks/vnet-web-prod/subnets/snet-backend"

# 【修正】プレースホルダーを実測値のサブスクリプションIDに置換し、本番環境のLBバックエンドプールIDに修正
lb_backend_pool_id = "/subscriptions/0f273017-b259-421d-894c-ae7906f901c8/resourceGroups/rg-web-prod/providers/Microsoft.Network/loadBalancers/lbi-web-prod/backendAddressPools/lbi-backend-pool"