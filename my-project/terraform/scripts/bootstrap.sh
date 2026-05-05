#!/bin/bash
# =================================================================
# OS初期セットアップ・スクリプト（Bootstrap）
# 役割: OS基盤設定、セキュリティ、Dockerエンジンの導入まで
# =================================================================
# 1. 未定義変数の使用で停止(u)、コマンド失敗時に即停止(e)、パイプ内のエラー検知(o pipefail)
set -euo pipefail
# 2. インストール中の対話型プロンプトを強制無効化
export DEBIAN_FRONTEND=noninteractive

# --- 1. ログ記録の設定 ---
# 追記モード(-a)で /var/log/user-data.log に全ての出力を記録
exec > >(tee -a /var/log/user-data.log | logger -t user-data) 2>&1

echo "*** [START] Bootstrap Process: $(date) ***"

# --- 2. システム基本設定 ---
# 変数未定義時の安全策を講じてホスト名を設定
if [ -n "${hostname:-}" ]; then
    hostnamectl set-hostname "${hostname}"
fi

timedatectl set-timezone Asia/Tokyo
localectl set-locale LANG=C.UTF-8

# --- 3. パッケージマネージャの更新 ---
apt-get update -y

# --- 4. 必須パッケージのインストール ---
# --no-install-recommends: 不要な推奨パッケージを除外し、環境をクリーンに保つ
INSTALL_OPTS="-y --no-install-recommends"

# 【Ansible/基盤】
# python3-apt は Ansible が apt モジュールを操作する際に必須
apt-get install $INSTALL_OPTS python3 python3-pip python3-apt software-properties-common

# 【本番運用基盤】
apt-get install $INSTALL_OPTS chrony rsyslog auditd nftables ca-certificates gnupg

# 【メンテナンス/ネットワーク調査ツール】
apt-get install $INSTALL_OPTS curl git vim htop iputils-ping dnsutils net-tools

# --- 5. Dockerエンジンのインストール (Debian 12 公式リポジトリ) ---
echo "Installing Docker Engine..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install $INSTALL_OPTS docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ユーザー権限の追加（sudoなしでdockerコマンドを実行可能にする）
if [ -n "${admin_username:-}" ]; then
    usermod -aG docker "${admin_username}"
fi

# --- 6. サービスの有効化（起動設定） ---
# enable --now により、自動起動設定と即時起動を同時に実施
systemctl enable --now chrony
systemctl enable --now rsyslog
systemctl enable --now auditd
systemctl enable --now docker

# nftables の安全起動（設定ファイルの存在を確認）
if [ -f /etc/nftables.conf ]; then
    systemctl enable --now nftables
else
    echo "Warning: /etc/nftables.conf not found. Skipping nftables start."
fi

# --- 7. 管理ユーザー (${admin_username}) の権限設定 ---
# visudo による構文チェックを行い、設定ミスによる締め出しを防止
if [ -n "${admin_username:-}" ]; then
    SUDOERS_FILE="/etc/sudoers.d/${admin_username}"
    echo "${admin_username} ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE"
    chmod 440 "$SUDOERS_FILE"
    visudo -cf "$SUDOERS_FILE" || (rm "$SUDOERS_FILE" && exit 1)
fi

# --- 8. 完了報告 ---
echo "*** [SUCCESS] Bootstrap Process Completed: $(date) ***"