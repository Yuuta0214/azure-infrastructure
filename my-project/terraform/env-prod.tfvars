# ==========================================
# 本番環境用パラメーター (env-prod.tfvars)
# ==========================================
env          = "prod"
project_name = "web-project"
location     = "japaneast" # 本番運用の中心である東日本リージョン

# 本番環境用 VMサイズ
# Standard_D2s_v3 (2vCPU / 8GB RAM)
# 専有CPUに近い挙動をするDシリーズを採用し、Web/App/DBの3層コンテナが
# 同時に高負荷になっても安定した処理性能を確保します。
vm_size      = "Standard_D2s_v3"

# 管理ユーザー名
admin_username = "azureuser"

# 追加の管理タグ
# コストセンターやビジネスユニットを定義し、Azureポータルでの請求管理を容易にします
tags = {
  BusinessUnit = "Production-Ops"
  CostCenter   = "WEB-101"
}