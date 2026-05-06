# 本番環境用パラメーター
# ==========================================
env          = "prod"

# 【修正箇所】"web-project" から "storage-state" に変更
# これにより本番実行時も「rg-storage-state」という共通の箱を使用します
project_name = "storage-state" 

location     = "Japan East"

# 【修正箇所】在庫不足 (409) 回避のため、Standard_B1s に変更（安全策）
vm_size      = "Standard_B1s" 
# ==========================================