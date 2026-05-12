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
# 5. ネットワーク参照定義 (追記箇所)
# 開発環境（dev）用のリソース ID を指定します。
# ==========================================
# 開発環境（dev）のサブネット ID を指定
subnet_id          = "/subscriptions/<サブスクリプションID>/resourceGroups/rg-web-dev/providers/Microsoft.Network/virtualNetworks/vnet-web-dev/subnets/snet-backend"

# 開発環境（dev）の LB バックエンドプール ID を指定
lb_backend_pool_id = "/subscriptions/<サブスクリプションID>/resourceGroups/rg-web-dev/providers/Microsoft.Network/loadBalancers/lbe-web-dev/backendAddressPools/lbe-pool-web-dev"