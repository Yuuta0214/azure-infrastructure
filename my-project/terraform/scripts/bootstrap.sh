#!/bin/bash
# ==========================================
# VM初期化スクリプト (Infrastructure Bootstrap)
# 役割: Ansibleが実行可能になるまでの最小環境構築
# ==========================================
set -euo pipefail

# すべての出力をログに記録 (デバッグ用)
exec > >(tee -a /var/log/user-data.log | logger -t user-data) 2>&1

echo "*** [START] Bootstrap: Preparing for Ansible ***"

# 1. パッケージマネージャーのロック競合を回避
# Ubuntu/Debianの自動更新サービスがaptを掴んでAnsibleが失敗するのを防ぎます
echo "Disabling unattended-upgrades to prevent apt lock..."
systemctl stop unattended-upgrades || true
systemctl disable unattended-upgrades || true

# 2. aptの更新とAnsible実行に必要な最小パッケージの導入
# DEBIAN_FRONTEND=noninteractive によりプロンプト待ちで停止するのを防ぎます
export DEBIAN_FRONTEND=noninteractive

echo "Updating apt and installing Python3..."
# 120秒のタイムアウトを設定し、一時的なロックがあっても待機するようにします
apt-get -o DPkg::Lock::Timeout=120 update -y
apt-get -o DPkg::Lock::Timeout=120 install -y \
    python3 \
    python3-apt \
    ca-certificates \
    curl \
    gnupg

# 3. ホスト名の設定 (Terraformから渡された変数を使用)
echo "Setting hostname to ${hostname}..."
hostnamectl set-hostname "${hostname}"

# 4. Ansible実行の安全性確保 (境界線の定義)
# Ansible側の site.yml で wait_for を使い、このファイルの存在を確認させます。
# これにより、インフラ準備が整う前にAnsibleが走り始める「衝突」を防止します。
echo "Creating synchronization flag for Ansible..."
echo "Infrastructure is ready for configuration at $(date)" > /var/tmp/bootstrap_complete
sync

echo "*** [SUCCESS] Bootstrap Complete ***"