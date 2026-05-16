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
# 【整合性修正】variables.tfのバリデーション（12文字以上）に準拠した値を設定してください
admin_password = "ComplexPasswordProd2026!"
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
# 【修正】01_network層との整合性：本番環境のサブネットIDを指定
subnet_id          = "/subscriptions/0f273017-b259-421d-894c-ae7906f901c8/resourceGroups/rg-web-prod/providers/Microsoft.Network/virtualNetworks/vnet-web-prod/subnets/snet-backend"

# 【修正】compute.tfの15行目で参照されている変数を追加（network層のLBリソースを指定）
lb_backend_pool_id = "/subscriptions/0f273017-b259-421d-894c-ae7906f901c8/resourceGroups/rg-web-prod/providers/Microsoft.Network/loadBalancers/lb-web-prod/backendAddressPools/be-web-prod"