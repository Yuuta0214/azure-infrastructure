#!/bin/bash
set -euo pipefail

# ログ記録（/var/log/user-data.log に出力され、トラブルシューティングに役立ちます）
exec > >(tee -a /var/log/user-data.log | logger -t user-data) 2>&1

echo "*** [START] Bootstrap ***"

# ==========================================
# 1. ホスト名の設定
# Terraformから渡された変数 ${hostname} が展開されます
# ==========================================
echo "Setting hostname to ${hostname}..."
hostnamectl set-hostname ${hostname}

# ==========================================
# 2. aptロック競合の回避（Ansible失敗対策）
# 起動直後のバックグラウンドアップデートを強制停止します
# ==========================================
echo "Disabling auto-updates to prevent apt lock conflicts..."
systemctl stop apt-daily.timer apt-daily-upgrade.timer unattended-upgrades.service || true
systemctl disable apt-daily.timer apt-daily-upgrade.timer unattended-upgrades.service || true
systemctl kill --kill-who=all apt-daily.service || true

# aptのロックが完全に解放されるまで待機する関数
wait_for_apt() {
  while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
    echo "Waiting for background apt processes to finish..."
    sleep 5
  done
}

wait_for_apt

# ==========================================
# 3. Ansible実行に必要な最小構成をインストール
# ==========================================
echo "Installing Python for Ansible..."
export DEBIAN_FRONTEND=noninteractive
apt-get -o DPkg::Lock::Timeout=120 update -y
apt-get -o DPkg::Lock::Timeout=120 install -y python3 python3-apt

# ==========================================
# 4. 権限設定
# Terraformから渡された変数 ${admin_username} が展開されます
# ==========================================
echo "Configuring sudoers for ${admin_username}..."
if [ -n "${admin_username}" ]; then
    echo "${admin_username} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${admin_username}"
    chmod 440 "/etc/sudoers.d/${admin_username}"
fi

# ==========================================
# 5. 【最重要：必達】完了フラグの作成
# Ansible側でこのファイルが作成されるのを待機します
# ==========================================
echo "Infrastructure is ready" > /var/tmp/bootstrap_complete
sync # ディスクに確実に書き込む

echo "***[SUCCESS] Bootstrap Complete ***"