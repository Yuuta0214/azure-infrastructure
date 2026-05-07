# ==========================================
# 検証環境用パラメーター (env-test.tfvars)
# ==========================================
env          = "test"
project_name = "web-project"
location     = "japanwest" # 本番とのリージョン分散テストを兼ねて西日本

# 検証環境: コスト効率重視のBシリーズ
# B2ms(2vCPU/8GB)は、B2sよりもメモリに余裕があり、
# Dockerビルドや初期セットアップ時に「メモリ不足でのハングアップ」を防げます
vm_size      = "Standard_B2ms"

tags = {
  BusinessUnit = "Dev-Test"
}