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
# admin_password は GitHub Secrets (TF_VAR_admin_password) から注入するため記述不要
ssh_public_key = ""

# ==========================================
# 4. メタデータ定義 (運用管理用)
# ==========================================
tags = {
  Environment  = "prod"
  Project      = "web"
  BusinessUnit = "Production-Ops"
  CostCenter   = "WEB-101"
  ManagedBy    = "Terraform"
}