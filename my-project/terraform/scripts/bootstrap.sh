#!/bin/bash
# =================================================================
# OS初期セットアップ・スクリプト（修正版）
# =================================================================
set -euo pipefail

# 1. 対話型プロンプトを完全に封殺する設定
export DEBIAN_FRONTEND=noninteractive
export UCFR_FORCE_CONFFNEW=YES
# 設定ファイルの競合時に「現在の設定を維持（古いものを保持）」して進めるオプション
APT_OPTS="-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -y"

# ログ記録の設定
exec > >(tee -a /var/log/user-data.log | logger -t user-data) 2>&1

echo "*** [START] Bootstrap Process: $(date) ***"

# --- 2. システム基本設定 ---
# ${hostname} は Terraform から注入
if [ -n "${hostname}" ]; then
    hostnamectl set-hostname "${hostname}"
fi

timedatectl set-timezone Asia/Tokyo
localectl set-locale LANG=C.UTF-8

# --- 3. パッケージマネージャの更新 ---
apt-get update $APT_OPTS

# --- 4. 必須パッケージのインストール ---
# 修正：変数を直接参照し、確実に -y を適用
apt-get install $APT_OPTS python3 python3-pip python3-apt software-properties-common \
    chrony rsyslog auditd nftables ca-certificates gnupg \
    curl git vim htop iputils-ping dnsutils net-tools

# --- 5. Dockerエンジンのインストール ---
echo "Installing Docker Engine..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# アーキテクチャとコードネームを正しく取得してリポジトリ登録
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update $APT_OPTS
apt-get install $APT_OPTS docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ユーザー権限の追加
if [ -n "${admin_username}" ]; then
    usermod -aG docker "${admin_username}"
fi

# --- 6. サービスの有効化 ---
systemctl enable --now chrony rsyslog auditd docker
[ -f /etc/nftables.conf ] && systemctl enable --now nftables

# --- 7. 管理ユーザーの権限設定（Sudoers） ---
if [ -n "${admin_username}" ]; then
    SUDOERS_FILE="/etc/sudoers.d/${admin_username}"
    echo "${admin_username} ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE"
    chmod 440 "$SUDOERS_FILE"
fi

# --- 8. 完了報告 ---
echo "*** [SUCCESS] Bootstrap Process Completed: $(date) ***"