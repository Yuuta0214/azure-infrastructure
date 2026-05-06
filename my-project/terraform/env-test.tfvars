# 検証環境用パラメーター
# ==========================================
env          = "test"

# 【修正箇所】"web-test" から "storage-state" に変更
# これにより main.tf の定義と組み合わさり「rg-storage-state」が作成されます
project_name = "storage-state" 

location     = "Japan East"

# 【確認済み】在庫不足エラー (409) 回避のための Standard_B1s 指定
vm_size      = "Standard_B1s"
# ==========================================