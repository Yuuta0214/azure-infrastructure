#!/bin/bash
# =================================================================
# OS初期セットアップ・スクリプト（Ansible接続確保版）
# 役割：AnsibleがSSH経由で設定を開始できる最小限の環境を整える
# =================================================================
set -euo pipefail

# ログ記録の設定
exec > >(tee -a /var/log/user-data.log | logger -t user-data) 2>&1

echo "*** [START] Bootstrap: Infrastructure Layer ***"

# 1. 競合回避：自動更新を停止（Ansibleに制御権を渡すため）
systemctl stop unattended-upgrades || true
systemctl disable unattended-upgrades || true

# 2. パッケージマネージャの更新（Ansible用python3-aptの導入）
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y python3 python3-apt

# 3. 管理ユーザーの権限設定（Sudoers）
# Ansibleがパスワードなしで特権操作を行えるようにする
if [ -n "${admin_username}" ]; then
    echo "${admin_username} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${admin_username}"
    chmod 440 "/etc/sudoers.d/${admin_username}"
fi

# 4. 【重要】完了シグナルの発行
# 「Ansibleが接続して良い状態になった」ことを明示する
echo "Infrastructure is ready" > /var/tmp/bootstrap_complete

echo "*** [SUCCESS] Bootstrap: Ready for Ansible ***"