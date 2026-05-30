azure-infrastructure-project/
├── .github/
│   ├── workflows/
│   │   ├── infra-00-backend.yml
│   │   ├── infra-01-network.yml
│   │   └── infra-02-compute.yml
│   └── actions/
│
├── shared/
│   ├── config/
│   │   ├── env/
│   │   │   ├── dev.tfvars          # 00/01 層共通（location, environment, tags）
│   │   │   └── prod.tfvars
│   │   └── backend/
│   │       ├── dev.backend.hcl
│   │       └── prod.backend.hcl
│   └── terraform/
│       ├── versions.tf             # 01/02 providers.tf と同一（参照用）
│       └── provider-azurerm.tf
│
├── infrastructure/
│   ├── 00_backend/
│   │   ├── backend.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   └── variables.tf
│   ├── 01_network/
│   │   ├── base.tf
│   │   ├── network.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   └── variables.tf
│   └── 02_compute/
│       ├── scripts/
│       │   └── bootstrap.sh
│       ├── compute.tf
│       ├── env-dev.tfvars          # 02 層固有（vm_size, lb_backend_pool_name 等）
│       ├── env-prod.tfvars
│       ├── providers.tf
│       └── variables.tf
│
└── config-management/
    ├── ansible.cfg
    ├── inventory.ini
    ├── deploy-components.yml
    ├── group_vars/
    │   └── all.yml
    ├── playbooks/                  # 将来の分割用
    ├── components/
    │   ├── app/
    │   │   └── docker-compose-app.yml.j2
    │   ├── db/
    │   │   └── docker-compose-db.yml.j2
    │   └── web/
    │       └── docker-compose-web.yml.j2
    ├── html/
    │   └── index.html
    ├── modsecurity-rules.conf
    ├── nginx-host.conf.j2
    └── nginx.conf

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
