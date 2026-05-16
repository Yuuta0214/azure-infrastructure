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
# 【整合性確定】GitHub Secrets (ARM_SUBSCRIPTION_ID) を活用するため、
# ここでは ID 全体ではなく、compute.tf の動的生成に必要なリソース名との整合性のみ担保します。
# ※実際の ID 組み立ては compute.tf 内の data.azurerm_client_config 経由で実施することを推奨。
subnet_id          = "snet-backend-web-prod"
lb_backend_pool_id = "be-pool-web-prod"