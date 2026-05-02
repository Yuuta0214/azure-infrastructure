#!/bin/bash
# =================================================================
# OS初期セットアップ・スクリプト（Bootstrap）
# 対象: vm-docker-host (Debian 12)
# 役割: Ansible実行環境の整備、および本番運用に必須な基盤パッケージの導入
# =================================================================

# --- 1. ログ記録の設定 ---
# 構築失敗時の「出戻り調査」を容易にするため、出力をログファイルに記録
# 実行ログは /var/log/user-data.log で確認可能
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "*** [START] Bootstrap Process: $(date) ***"

# --- 2. システム基本設定 ---
# Terraformから注入された変数を使用してホスト名を設定
hostnamectl set-hostname ${hostname}

# タイムゾーンを日本時間に設定（ログの整合性確保に必須）
timedatectl set-timezone Asia/Tokyo

# ロケールをUTF-8に固定（文字化けとスクリプトエラーの防止）
localectl set-locale LANG=C.UTF-8

# --- 3. パッケージマネージャの更新 ---
apt-get update

# --- 4. 必須パッケージのインストール ---
# 【Ansible基盤】
# python3-apt: Ansibleのaptモジュールを高速・正確に動かすために必要
apt-get install -y python3 python3-pip python3-apt

# 【本番運用基盤】
# chrony: 正確な時刻同期（認証やログの証跡に必須）
# rsyslog: システムログ収集の標準
# auditd: 「誰が何をしたか」を記録する監査ログ（セキュリティ要件）
# nftables: OS内ファイアウォール（多層防御の土台。設定はAnsibleで行う）
apt-get install -y chrony rsyslog auditd nftables

# 【メンテナンスツール】
# 運用・トラブルシューティングでエンジニアが必ず使うツール群
apt-get install -y curl git vim htop

# --- 5. サービスの有効化（起動設定） ---
# インストールした各基盤サービスを、OS再起動後も自動起動するように設定
systemctl enable chrony
systemctl enable rsyslog
systemctl enable auditd
systemctl enable nftables

# --- 6. 管理ユーザー (${admin_username}) の権限設定 ---
# AnsibleがSSH経由でログインし、パスワードなしでsudo（設定変更）ができるようにする
# これがないと自動化処理が途中で止まり、出戻りが発生する
echo "${admin_username} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${admin_username}
chmod 440 /etc/sudoers.d/${admin_username}

# --- 7. 完了報告 ---
echo "*** [SUCCESS] Bootstrap Process Completed: $(date) ***"
