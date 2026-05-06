# 1. リージョンの定義
# ==========================================
variable "location" {
    description = "リソースを配置するリージョン"
    type         = string
    default      = "Japan East"
}

# 2. プロジェクト名の定義（リソース名のベース）
# ==========================================
variable "project_name" {
    description = "プロジェクトの基本名称"
    type         = string
    default      = "web-project"
}

# 3. 実行環境の定義（本番：prod / 検証：test）
# ==========================================
variable "env" {
    description = "実行環境 (prod または test)"
    type         = string
    default      = "test"
}

# 4. VMサイズの定義（在庫不足エラーへの対策）
# tfvars から Standard_B2s が注入されます
# ==========================================
variable "vm_size" {
    description = "VMのサイズ（SKU）"
    type         = string
    default      = "Standard_B2s" 
}

# 5. 管理ユーザー名の定義
# ==========================================
variable "admin_username" {
    description = "VMの管理者ユーザー名"
    type         = string
    default      = "azureuser"
}

# 6. パスワードの定義（機密情報）
# ==========================================
variable "admin_password" {
    description = "VMの管理者パスワード"
    type         = string
    sensitive   = true 
}