# ==========================================
# 本番環境用パラメーター (env-prod.tfvars)
# ==========================================

# 修正ポイント: variables.tfのバリデーションに合わせ "prod" に設定
environment  = "prod"
project_name = "web"
location     = "japaneast" 

# 本番環境用 VMサイズ
vm_size      = "Standard_D2s_v3"

# 管理ユーザー名
admin_username = "azureuser"

# 存在しない変数 ssh_public_key の記述は、エラーを避けるためここには含めません。
# パスワードは GitHub Secrets から注入されるため、ここへの記載は不要です。

# 追加の管理タグ
tags = {
  BusinessUnit = "Production-Ops"
  CostCenter   = "WEB-101"
}