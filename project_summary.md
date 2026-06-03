# プロジェクト名: Azure-Infrastructure-Project

# 1. 目的と概要


# 2. ディレクトリ構成（期待値）
azure-infrastructure-project/
├── .github/                      # CI/CD パイプライン定義（IaC自動化の心臓部）
│   ├── workflows/                # ワークフロー定義（各層を独立してデプロイ・テストする）
│   │   ├── infra-00-backend.yml  # Terraformの状態管理基盤の更新
│   │   ├── infra-01-network.yml  # ネットワーク・基盤インフラの保護と更新
│   │   └── infra-02-compute.yml  # アプリ層・VMの柔軟な更新
│   └── actions/                  # 再利用可能なCI/CDロジックの格納
│
├── shared/                       # 共通設定（DRY: Don't Repeat Yourself）
│   ├── config/
│   │   ├── env/                  # 環境変数（全層で参照されるタグやリージョン情報）
│   │   │   ├── dev.tfvars
│   │   │   └── prod.tfvars
│   │   └── backend/              # バックエンド設定（Stateファイルの格納先）
│   │       ├── dev.backend.hcl
│   │       └── prod.backend.hcl
│   └── terraform/                # プロバイダー定義の共通化（バージョン整合性の維持）
│       ├── versions.tf           # Terraform/Providerのバージョン固定（ロック）
│       └── provider-azurerm.tf   # サブスクリプション情報等の共通設定
│
├── infrastructure/               # Terraform 実装（レイヤー分割によりリスクを分離）
│   ├── 00_backend/               # 【層0】初期化（ストレージアカウント・State管理）
│   │   ├── backend.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   └── variables.tf
│   ├── 01_network/               # 【層1】ネットワーク（VNet, Subnet, NSG：変更頻度低）
│   │   ├── base.tf               # VNet定義
│   │   ├── network.tf            # サブネット・ルートテーブル
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   └── variables.tf
│   └── 02_compute/               # 【層2】コンピューティング（VM, LB：変更頻度高）
│       ├── scripts/              # 初期構築用シェルスクリプト
│       │   └── bootstrap.sh
│       ├── compute.tf            # VM/LB定義（ここにBastionも配置）
│       ├── env-dev.tfvars        # 各環境ごとのSKUやインスタンス数
│       ├── env-prod.tfvars
│       ├── providers.tf
│       └── variables.tf
│
└── config-management/            # 構成管理（Terraform実行後のOS/アプリ設定）
    ├── ansible.cfg               # Ansibleの設定ファイル
    ├── inventory.ini             # 対象ホスト情報
    ├── deploy-components.yml     # アプリデプロイ用メインプレイブック
    ├── group_vars/               # 全ホスト共通のパラメータ
    │   └── all.yml
    ├── playbooks/                # 機能別実行ファイル
    ├── components/               # 再利用可能なアプリ定義（Docker Compose構成）
    │   ├── app/
    │   ├── db/
    │   └── web/
    ├── html/                     # コンテンツ（Webサーバー用静的ファイル）
    └── nginx.conf系              # Webサーバーのプロキシ設定（テンプレート化済み）


azure-infrastructure-project
|   .github.code-workspace  # VSCode/Cursor用のワークスペース設定（PJ全体を管理）
|   project_summary.md      # プロジェクトの設計書・ドキュメント（READMEの役割）
|   
+---.cursor                 # Cursorエディタ専用のルール設定（AIの挙動制御用）
+---.github
|   +---actions             # 再利用可能なカスタムActionの定義場所
|   \---workflows           # 各層ごとのCI/CDパイプライン定義
|           infra-00-backend.yml    # 状態管理基盤（Storage Account）の自動デプロイ
|           infra-01-network.yml    # ネットワーク基盤（VNet/Subnet/NSG）の自動デプロイ
|           infra-02-compute.yml    # VM/Bastion/LBの自動デプロイ
|           
+---config-management               # AnsibleによるOS・アプリの構成管理レイヤー
|   |   ansible.cfg                 # Ansibleの設定ファイル
|   |   deploy-components.yml       # 全コンポーネントをデプロイするメインプレイブック
|   |   inventory.ini               # 対象サーバーの接続先リスト
|   |   modsecurity-rules.conf      # Webアプリのセキュリティルール定義
|   |   nginx-container.conf        # Docker上のNginx設定
|   |   nginx-host.conf.j2          # サーバー側Nginxのテンプレート（環境ごとに書き換え）
|   |   
|   +---components                  # アプリの役割ごとの設定テンプレート
|   |   +---app
|   |   |       docker-compose-app.yml.j2   # Docker Compose定義（アプリケーション）
|   |   |       
|   |   +---db
|   |   |       docker-compose-db.yml.j2    # Docker Compose定義（データベース）
|   |   |       
|   |   \---web
|   |           docker-compose-web.yml.j2   # Docker Compose定義（Webサーバー）
|   |           
|   +---group_vars                          # ホスト共通変数の定義
|   |       all.yml
|   |       
|   +---html                                # コンテンツ（Webサーバー用静的資産）
|   |       index.html
|   |       
|   \---playbooks                           # 機能ごとの実行タスク（将来の拡張用）
|           .gitkeep
|           
+---infrastructure                          # Terraformによるインフラ定義レイヤー（疎結合設計）
|   +---00_backend                          # Terraform Stateを管理するための初期基盤）
|   |       backend.tf                      # リモートバックエンド（Azure Storage）の接続定義
|   |       outputs.tf                      # StorageAccount名などを他層へ渡すための出力定義
|   |       providers.tf                    # この層専用のProvider初期化設定
|   |       variables.tf                    # バックエンド構築に必要な変数定義
|   |       
|   +---01_network                          # ネットワーク基盤（一度構築したら変更頻度が低い層）
|   |       base.tf                         # Virtual Network(VNet)の基本設計
|   |       network.tf                      # サブネット、NSG（セキュリティグループ）の定義
|   |       outputs.tf                      # サブネットIDなどをCompute層へ渡すための出力定義
|   |       providers.tf                    # ネットワーク構築用Provider設定
|   |       variables.tf                    # IPアドレス空間やサブネット名の変数定義
|   |       
|   \---02_compute                          # アプリケーションを稼働させる計算層（頻繁に変更・入替する層）
|       |   compute.tf                      # 仮想マシン(VM)、Bastion、ロードバランサー(LB)の統合定義
|       |   env-dev.tfvars                  # 開発環境用のVMサイズやリソースパラメータ（可変）
|       |   env-prod.tfvars                 # 本番環境用のVMサイズやリソースパラメータ（可変）
|       |   providers.tf                    # Compute層用Provider設定
|       |   variables.tf                    # VMイメージやSKUなどリソース構築に必要な変数定義
|       |   
|       \---scripts                         # リソース作成後の初期化処理（OS設定・アプリデプロイ準備）
|               bootstrap.sh                # VM起動時に実行されるパッケージインストール用スクリプト
|               
\---shared                                  # 全レイヤー共通で利用する設定・DRY原則のための集約場所
    +---config                              # 環境依存の設定値（ハードコーディング防止）
    |   +---backend                         # リモートステート管理用のバックエンド設定
    |   |       dev.backend.hcl             # 開発環境用State格納先（コンテナ名やパス）
    |   |       prod.backend.hcl            # 本番環境用State格納先（分離によるリスク低減）
    |   |
    |   \---env                             # 全リソースで共通利用する環境変数（タグ・リージョン等）
    |           dev.tfvars                  # 開発環境全体の共通パラメータ
    |           prod.tfvars                 # 本番環境全体の共通パラメータ
    |
    \---terraform                           # Terraform実行環境の統一定義
            provider-azurerm.tf             # Azure Providerの共通設定（認証情報や機能フラグ）
            versions.tf                     # 必須Terraformバージョンおよびプロバイダーの固定
## デプロイ順序

1. `infra-00-backend.yml` → infrastructure/00_backend
2. `infra-01-network.yml` → infrastructure/01_network（var: shared/config/env/*.tfvars）
3. `infra-02-compute.yml` → infrastructure/02_compute + config-management（Ansible）

## 旧パスからの移行

| 旧 | 新 |
|----|-----|
| my-project/00_backend/ | infrastructure/00_backend/ |
| my-project/00_backend/env-*.tfvars | shared/config/env/*.tfvars |
| my-project/01_network/ | infrastructure/01_network/ |
| my-project/02_compute/ | infrastructure/02_compute/ |
| my-project/Ansible/ | config-management/ |
