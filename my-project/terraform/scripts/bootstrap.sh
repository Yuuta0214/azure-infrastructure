#!/bin/bash
set -euo pipefail

# ログ記録（/var/log/user-data.log に出力され、トラブルシューティングに役立ちます）
exec > >(tee -a /var/log/user-data.log | logger -t user-data) 2>&1

echo "*** [START] Bootstrap: $(date) ***"

# ==========================================
# 1. ホスト名の設定
# Terraformから渡された変数 ${hostname} が展開されます
# ==========================================
echo "Setting hostname to ${hostname}..."
hostnamectl set-hostname "${hostname}"
# /etc/hosts にも自分自身を登録（一部のミドルウェアの警告回避）
echo "127.0.0.1 ${hostname}" >> /etc/hosts

# ==========================================
# 2. aptロック競合の回避（Ansible失敗対策）
# ==========================================
echo "Stopping background auto-updates..."
systemctl stop apt-daily.timer apt-daily-upgrade.timer unattended-upgrades.service || true

# aptのロックが完全に解放されるまで待機する関数
wait_for_apt() {
  local count=0
  while fuser /var/lib/dpkg/lock-frontends >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    echo "Waiting for background apt processes to finish... ($((count*5))s)"
    sleep 5
    count=$((count+1))
    if [ $count -gt 60 ]; then
      echo "Timeout waiting for apt lock. Attempting to force clear..."
      rm -f /var/lib/dpkg/lock-frontends
      break
    fi
  done
}

wait_for_apt

# ==========================================
# 3. システム更新とAnsible基盤のインストール
# ==========================================
echo "Updating package lists and installing Python..."
export DEBIAN_FRONTEND=noninteractive

# リトライ処理を追加してネットワークの瞬断に備える
for i in {1..3}; do
  apt-get update -y && break || sleep 10
done

# python3-pipとvenvを追加（最新のAnsibleモジュールで必要になる場合が多いため）
apt-get install -y \
    python3 \
    python3-apt \
    python3-pip \
    python3-venv \
    curl \
    ca-certificates \
    gnupg

# ==========================================
# 4. 権限設定
# Terraformから渡された変数 ${admin_username} が展開されます
# ==========================================
echo "Configuring sudoers for ${admin_username}..."
if [ -n "${admin_username}" ]; then
    # /etc/sudoers.d/ に追加。既存のファイルがある場合は上書き。
    echo "${admin_username} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-cloud-init-users"
    chmod 440 "/etc/sudoers.d/90-cloud-init-users"
fi

# ==========================================
# 5. 【追加】Dockerインストール前の事前準備（オプション）
# Ansible側でDockerをインストールしやすくするため、共通の依存関係を入れておきます
# ==========================================
echo "Preparing for Docker installation..."
install -m 0755 -d /etc/apt/keyrings

# ==========================================
# 6. 【最重要】完了フラグの作成
# ==========================================
echo "Infrastructure is ready" > /var/tmp/bootstrap_complete
sync

echo "*** [SUCCESS] Bootstrap Complete: $(date) ***"