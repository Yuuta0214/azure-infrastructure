# ==========================================
# 本番環境用パラメーター (env-prod.tfvars)
# ==========================================
env          = "prod"
project_name = "web-project"
location     = "japaneast" # 本番は主要リージョンである東日本

# 本番環境: 安定したCPU/メモリ比率を持つDシリーズ
# Docker上で複数のコンテナを動かす場合、2vCPU/8GBメモリのD2sはバランスが良いです
vm_size      = "Standard_D2s_v3"

# 追加の管理タグが必要な場合はここに記述
tags = {
  BusinessUnit = "Production-Ops"
  CostCenter   = "WEB-101"
}