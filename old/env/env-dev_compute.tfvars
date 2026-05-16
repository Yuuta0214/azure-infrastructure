# ==========================================
# 02_compute / env-dev.tfvars
# ==========================================

# ==========================================
# 1. 基盤・環境定義
# ==========================================
# 01_network 側の定義および 02_compute.yml の TARGET_ENV=dev と整合
location     = "japanwest"
environment  = "dev"
project_name = "web"

# 【整合性修正】01_network 層で作成済みのリソースグループ名を正確に指定
resource_group_name = "rg-web-dev"

# ==========================================
# 2. コンピューティング定義 (VMスペック)
# ==========================================
vm_size      = "Standard_D2s_v3"

# ==========================================
# 3. 認証・セキュリティ定義
# ==========================================
# セキュリティ・ベストプラクティス：variables.tf のバリデーション（admin/root等禁止）を遵守
admin_username = "azureuser"

# セキュリティ・ベストプラクティス：12文字以上かつ複雑性要件を遵守
# 開発環境であっても、推測されにくい安全なパスワードを設定
admin_password = "Dev-Secure-Pass-2026!"

# ==========================================
# 4. メタデータ定義 (運用管理用)
# ==========================================
# 01_network 側のタグ構成（Production-Dev / WEB-201）と完全に一致させる
tags = {
  BusinessUnit = "Production-Dev"
  CostCenter   = "WEB-201"
}

# ==========================================
# 5. ネットワーク参照定義 (01_network層との整合性)
# ==========================================
# 【整合性修正】01_network/network.tf の命名規則に基づき ID を正確に反映
# サブネット名: snet-backend-web-dev (snet-backend-${project_name}-${environment})
subnet_id          = "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-web-dev/providers/Microsoft.Network/virtualNetworks/vnet-web-dev/subnets/snet-backend-web-dev"

# 【整合性修正】LBおよびバックエンドプール名: be-pool-web-dev (be-pool-${project_name}-${environment})
lb_backend_pool_id = "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-web-dev/providers/Microsoft.Network/loadBalancers/lb-web-dev/backendAddressPools/be-pool-web-dev"