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
# セキュリティ・ベストプラクティス：variables.tf のバリデーション（admin/root等禁止）を遵守
admin_username = "azureuser"

# セキュリティ・ベストプラクティス：12文字以上かつ複雑性の要件を遵守
admin_password = "Dev-Secure-Pass-2026!"

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
# 【整合性修正】01_network/network.tf で定義された命名規則に基づき ID を正確に反映
# サブネット名: snet-backend-${project_name}-${environment} -> snet-backend-web-dev
subnet_id          = "/subscriptions/0f273017-b259-421d-894c-ae7906f901c8/resourceGroups/rg-web-dev/providers/Microsoft.Network/virtualNetworks/vnet-web-dev/subnets/snet-backend-web-dev"

# 【整合性修正】01_network/outputs.tf の定義に準拠したバックエンドプール ID
lb_backend_pool_id = "/subscriptions/0f273017-b259-421d-894c-ae7906f901c8/resourceGroups/rg-web-dev/providers/Microsoft.Network/loadBalancers/lb-web-dev/backendAddressPools/be-pool-web-dev"