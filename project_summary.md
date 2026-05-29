azure-infrastructure-project/
├── .github/workflows/
│   ├── 00_backend.yml
│   ├── 01_network.yml
│   └── 02_compute.yml
│
└── my-project/
    ├── 00_backend/
    │   ├── backend.tf
    │   ├── env-dev.tfvars
    │   ├── env-prod.tfvars
    │   ├── outputs.tf
    │   ├── providers.tf
    │   └── variables.tf
    ├── 01_network/
    │   ├── base.tf
    │   ├── env-dev.tfvars
    │   ├── env-prod.tfvars
    │   ├── network.tf
    │   ├── outputs.tf
    │   ├── providers.tf
    │   └── variables.tf
    ├── 02_compute/
    │   ├── scripts/
    │   │   └── bootstrap.sh
    │   ├── compute.tf
    │   ├── env-dev.tfvars
    │   ├── env-prod.tfvars
    │   ├── providers.tf
    │   └── variables.tf
    └── Ansible/
        ├── components/
        │   ├── app/
        │   │   └── docker-compose-app.yml.j2
        │   ├── db/
        │   │   └── docker-compose-db.yml.j2
        │   └── web/
        │       └── docker-compose-web.yml.j2
        ├── html/
        ├── ansible.cfg
        ├── deploy-components.yml
        ├── inventory.ini
        ├── modsecurity-rules.conf
        ├── nginx-host.conf.j2
        └── nginx.conf