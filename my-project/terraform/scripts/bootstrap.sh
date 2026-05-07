#!/bin/bash
set -euo pipefail

# ログ記録
exec > >(tee -a /var/log/user-data.log | logger -t user-data) 2>&1

echo "*** [START] Bootstrap ***"

# 1. 自動更新を停止
systemctl stop unattended-upgrades || true
systemctl disable unattended-upgrades || true

# 2. パッケージマネージャの更新（ロック待ちオプション付与）
export DEBIAN_FRONTEND=noninteractive
apt-get -o DPkg::Lock::Timeout=120 update -y
apt-get -o DPkg::Lock::Timeout=120 install -y python3 python3-apt

# 3. 管理ユーザーのSudoers設定
if [ -n "${admin_username}" ]; then
    echo "${admin_username} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${admin_username}"
    chmod 440 "/etc/sudoers.d/${admin_username}"
fi

# 4. 完了シグナル
echo "Infrastructure is ready" > /var/tmp/bootstrap_complete

echo "*** [SUCCESS] Bootstrap ***"