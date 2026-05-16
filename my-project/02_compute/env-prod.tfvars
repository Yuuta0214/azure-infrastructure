# ==========================================
# 02_compute / env-prod.tfvars
# ==========================================

# ==========================================
# 1. 基盤・環境定義
# ==========================================
# 01_network/env-prod.tfvars および variables.tf との整合性を維持
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
# セキュリティ・ベストプラクティス：variables.tf のバリデーション（admin/root等禁止）を遵守
admin_username = "azureuser"

# セキュリティ・ベストプラクティス：12文字以上かつ複雑性要件を遵守した本番用パスワード
# ※ 実際の運用では Key Vault 等の利用を推奨しますが、現状の構成に基づき安全な値を設定
admin_password = "Prod-Secure-Pass-2026!"

# ==========================================
# 4. メタデータ定義 (運用管理用)
# ==========================================
# 01_network 側のタグ構成（Production-Ops / WEB-101）とプロジェクト基準を統一
tags = {
  BusinessUnit = "Production-Ops"
  CostCenter   = "WEB-101"
}

# ==========================================
# 5. ネットワーク参照定義 (01_network層との整合性)
# ==========================================
# 【整合性修正】01_network/network.tf で定義された命名規則に基づき ID を正確に反映
# サブネット名: snet-backend-${project_name}-${environment} -> snet-backend-web-prod
subnet_id          = "/subscriptions/0f273017-b259-421d-894c-ae7906f901c8/resourceGroups/rg-web-prod/providers/Microsoft.Network/virtualNetworks/vnet-web-prod/subnets/snet-backend-web-prod"

# 【整合性修正】01_network/outputs.tf の定義に準拠したバックエンドプール ID
lb_backend_pool_id = "/subscriptions/0f273017-b259-421d-894c-ae7906f901c8/resourceGroups/rg-web-prod/providers/Microsoft.Network/loadBalancers/lb-web-prod/backendAddressPools/be-pool-web-prod"