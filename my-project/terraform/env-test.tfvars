# ==========================================
# 1. 基盤・環境定義
# ==========================================
location     = "japanwest"
environment  = "test"
project_name = "web"

# ==========================================
# 2. コンピューティング定義 (VMスペック)
# ==========================================
# 修正ポイント: 409 Conflict (SkuNotAvailable) 回避のため B2ms から B2s へ変更
vm_size      = "Standard_D2s_v3"

# ==========================================
# 3. 認証・セキュリティ定義
# ==========================================
admin_username = "azureuser"
# admin_password は GitHub Secrets (TF_VAR_admin_password) から注入するため記述不要
ssh_public_key = ""

# ==========================================
# 4. メタデータ定義 (運用管理用)
# ==========================================
tags = {
  Environment  = "test"
  Project      = "web"
  BusinessUnit = "Dev-Test"
  CostCenter   = "WEB-102"
  ManagedBy    = "Terraform"
}