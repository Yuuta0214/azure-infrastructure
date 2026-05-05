#!/bin/bash
# =================================================================
# OS初期セットアップ・スクリプト（Bootstrap）
# =================================================================
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# --- 1. ログ記録の設定 ---
exec > >(tee -a /var/log/user-data.log | logger -t user-data) 2>&1

# $$(date) でシェル変数として実行
echo "*** [START] Bootstrap Process: $$(date) ***"

# --- 2. システム基本設定 ---
# ${hostname} は Terraform から注入される変数
if [ -n "${hostname}" ]; then
    hostnamectl set-hostname "${hostname}"
fi

timedatectl set-timezone Asia/Tokyo
localectl set-locale LANG=C.UTF-8

# --- 3. パッケージマネージャの更新 ---
apt-get update -y

# --- 4. 必須パッケージのインストール ---
# 修正：$を重ねることで、Terraformではなくシェル変数として扱わせる
INSTALL_OPTS="-y --no-install-recommends"
apt-get install $$INSTALL_OPTS python3 python3-pip python3-apt software-properties-common
apt-get install $$INSTALL_OPTS chrony rsyslog auditd nftables ca-certificates gnupg
apt-get install $$INSTALL_OPTS curl git vim htop iputils-ping dnsutils net-tools

# --- 5. Dockerエンジンのインストール ---
echo "Installing Docker Engine..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# $$(...) でシェルコマンドとして実行
echo "deb [arch=$$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $$(. /etc/os-release && echo "$$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install $$INSTALL_OPTS docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ユーザー権限の追加
# ${admin_username} は Terraform から注入される変数
if [ -n "${admin_username}" ]; then
    usermod -aG docker "${admin_username}"
fi

# --- 6. サービスの有効化 ---
systemctl enable --now chrony
systemctl enable --now rsyslog
systemctl enable --now auditd
systemctl enable --now docker

if [ -f /etc/nftables.conf ]; then
    systemctl enable --now nftables
fi

# --- 7. 管理ユーザーの権限設定 ---
if [ -n "${admin_username}" ]; then
    # 修正：シェル変数として扱うため変数の頭に$を追加し、必要に応じてエスケープ
    SUDOERS_FILE="/etc/sudoers.d/${admin_username}"
    echo "${admin_username} ALL=(ALL) NOPASSWD:ALL" > "$$SUDOERS_FILE"
    chmod 440 "$$SUDOERS_FILE"
    visudo -cf "$$SUDOERS_FILE" || (rm "$$SUDOERS_FILE" && exit 1)
fi

# --- 8. 完了報告 ---
echo "*** [SUCCESS] Bootstrap Process Completed: $$(date) ***"