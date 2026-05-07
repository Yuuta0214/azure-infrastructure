# ==========================================
# 検証環境用パラメーター (env-test.tfvars)
# ==========================================

# 整合性確認: variables.tfのバリデーション通りの "test" に設定
environment  = "test"
project_name = "web"
location     = "japanwest" 

# 検証環境用 VMサイズ
vm_size      = "Standard_B2ms"

# 管理ユーザー名
admin_username = "azureuser"

# 追加の管理タグ
tags = {
  BusinessUnit = "Dev-Test"
}