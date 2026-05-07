#!/bin/bash
set -euo pipefail

# ログ記録
exec > >(tee -a /var/log/user-data.log | logger -t user-data) 2>&1

echo "*** [START] Bootstrap ***"

# 1. 競合を避けるために自動更新を強制停止
systemctl stop unattended-upgrades || true
systemctl disable unattended-upgrades || true

# 2. Ansible実行に必要な最小構成をインストール
export DEBIAN_FRONTEND=noninteractive
apt-get -o DPkg::Lock::Timeout=120 update -y
apt-get -o DPkg::Lock::Timeout=120 install -y python3 python3-apt

# 3. 権限設定
if [ -n "${admin_username}" ]; then
    echo "${admin_username} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${admin_username}"
    chmod 440 "/etc/sudoers.d/${admin_username}"
fi

# --- 【最重要：必達】完了フラグの作成 ---
echo "Infrastructure is ready" > /var/tmp/bootstrap_complete
sync # ディスクに確実に書き込む

echo "*** [SUCCESS] Bootstrap Complete ***"