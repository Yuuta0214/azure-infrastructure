# 本番環境用パラメーター
# ==========================================
env          = "prod"

# 【修正】"storage-state" から "web-project" に戻します
# これにより、本番インフラは「rg-web-project」に作成されます
project_name = "web-project" 

location     = "Japan East"

# 【重要】本番も在庫リスクを最小化するため Standard_B2ms に合わせます
vm_size      = "Standard_D2s_v3" 
# ==========================================