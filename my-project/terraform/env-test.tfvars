# ==========================================
# 検証環境用パラメーター (env-test.tfvars)
# ==========================================
env          = "test"
project_name = "web-project"
location     = "japanwest" # 地理的冗長性の検証を兼ねた西日本リージョン

# 検証環境用 VMサイズ
# Standard_B2ms (2vCPU / 8GB RAM)
# B2s(4GB)ではなくB2ms(8GB)を選択することで、Ansibleの実行や
# Dockerイメージのビルド時にメモリ枯渇でプロセスが死ぬリスクを大幅に低減します。
vm_size      = "Standard_B2ms"

# 管理ユーザー名
admin_username = "azureuser"

# 追加の管理タグ
tags = {
  BusinessUnit = "Dev-Test"
}