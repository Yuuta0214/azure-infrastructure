# リージョンの定義
# ==========================================
variable "location" {
    description = "リソースを配置するリージョン"
    type        = string
    default     = "Japan East"
}
# ==========================================

# プロジェクト名の定義（リソース名の接頭辞などに利用）
# ==========================================
variable "project_name" {
    description = "プロジェクト名"
    type        = string
    default     = "web-project"
}
# ==========================================

# 管理ユーザー名の定義
# ==========================================
variable "admin_username" {
    description = "VMの管理者ユーザー名"
    type        = string
    default     = "azureuser"
}
# ==========================================

# パスワードの定義（機密情報）
# ==========================================
variable "admin_password" {
    description = "VMの管理者パスワード"
    type        = string
    sensitive   = true # ログに表示されないように設定
}
# ==========================================