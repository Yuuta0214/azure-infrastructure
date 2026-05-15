#!/bin/bash
# ==========================================
# VM初期化スクリプト (Infrastructure Bootstrap)
# 役割: OSの最小限の健全性確保とAnsible実行環境の整備
# ==========================================
set -euo pipefail

# ログ記録設定 (保守用: 後で /var/log/user-data.log を確認可能に)
exec > >(tee -a /var/log/user-data.log | logger -t user-data) 2>&1

echo "*** [START] Bootstrap: $(date) ***"

# 1. aptロックの安全な待機
# 他のプロセスがaptを使用中の場合、最大300秒待機するように設定
echo "Waiting for apt locks to be released..."
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
    echo "Waiting for other software managers to finish..."
    sleep 5
done

# 2. パッケージ更新とPythonの導入 (Ansible用)
export DEBIAN_FRONTEND=noninteractive
echo "Installing minimal requirements for Ansible..."

# 120秒のタイムアウトを設定し、確実にインストール
apt-get -o DPkg::Lock::Timeout=120 update -y
apt-get -o DPkg::Lock::Timeout=120 install -y \
    python3 \
    python3-pip \
    python3-apt \
    ca-certificates \
    curl \
    sudo

# 3. ホスト名の設定 (Terraformから注入された変数を使用)
if [ -n "${hostname}" ]; then
    echo "Setting hostname to ${hostname}..."
    hostnamectl set-hostname "${hostname}"
    echo "127.0.1.1 ${hostname}" >> /etc/hosts
fi

# 4. 管理ユーザー（${admin_username}）の権限調整
# Ansibleが sudo 実行時にパスワードを求められないように設定 (保守性向上)
echo "Configuring sudoers for ${admin_username}..."
echo "${admin_username} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${admin_username}"
chmod 0440 "/etc/sudoers.d/${admin_username}"

# 5. 完了フラグの作成 (Ansible側の wait_for タスクとの同期用)
# このファイルが存在＝Ansibleが走り始めて良い状態、という「境界線」を作ります
echo "Creating synchronization flag..."
cat <<EOF > /var/tmp/bootstrap_complete
bootstrap_version=1.0
completion_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
status=ready
EOF

sync
echo "*** [SUCCESS] Bootstrap Complete: Infrastructure is ready ***"