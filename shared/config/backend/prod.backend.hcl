# 本番環境: Terraform リモート State 接続（00_backend で作成したリソース名と一致）
resource_group_name  = "rg-web-prod-mgmt"
storage_account_name = "stwebprobackend"
container_name       = "tfstate"
use_oidc             = true
