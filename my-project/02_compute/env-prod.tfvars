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
# 01_network で作成されたリソースの ID を直接指定します。
# これにより、別フォルダのファイルを読み込むことなく動作を完結させます。
# ==========================================
# 本番環境（prod）のサブネット ID を指定
subnet_id          = "/subscriptions/<サブスクリプションID>/resourceGroups/rg-web-prod/providers/Microsoft.Network/virtualNetworks/vnet-web-prod/subnets/snet-backend"

# 本番環境（prod）の LB バックエンドプール ID を指定
lb_backend_pool_id = "/subscriptions/<サブスクリプションID>/resourceGroups/rg-web-prod/providers/Microsoft.Network/loadBalancers/lbe-web-prod/backendAddressPools/lbe-pool-web-prod"