# 検証環境用パラメーター
# ==========================================
env          = "test"

# 【修正】"storage-state" から "web-test" に戻します
# これにより、インフラは「rg-web-test」という専用の箱に作成されます
project_name = "web-test" 

location     = "Japan East"

# 【重要】B1s/B2sの在庫切れを回避するため、Standard_B2ms を指定
vm_size      = "Standard_B2ms"
# ==========================================