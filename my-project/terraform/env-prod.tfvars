# ==========================================
# 本番環境用パラメーター (env-prod.tfvars)
# ==========================================
# 命名を rg-web-project に合わせるため environment を project に設定
environment  = "project"
project_name = "web"
location     = "japaneast" 

# 本番環境用 VMサイズ
vm_size      = "Standard_D2s_v3"

# 管理ユーザー名
admin_username = "azureuser"

# 追加の管理タグ
tags = {
  BusinessUnit = "Production-Ops"
  CostCenter   = "WEB-101"
}