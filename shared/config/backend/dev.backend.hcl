# 開発環境: Terraform リモート State 接続（00_backend で作成したリソース名と一致）
resource_group_name  = "rg-web-dev-mgmt"
storage_account_name = "stwebdevbackend"
container_name       = "tfstate"
use_oidc             = true
