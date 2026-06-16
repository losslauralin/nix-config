#!/usr/bin/env bash

#
# nixdaemon-proxy.sh - NixOS 物理/虚拟机 nix-daemon 代理配置脚本
#
# 用途：为非 WSL 环境（物理机/VM）的 nix-daemon 服务配置代理
#
# Usage:
#   ./nixdaemon-proxy.sh http    # 设置 HTTP 代理
#   ./nixdaemon-proxy.sh socks   # 设置 SOCKS5 代理
#   ./nixdaemon-proxy.sh off     # 清除代理设置
#

# --- Configuration ---
# HTTP 代理地址和端口
HTTP_PROXY_URL="http://127.0.0.1:7890"

# SOCKS5 代理地址和端口
# 使用 socks5h:// 可以在代理端解析 DNS，通常是推荐的做法。
SOCKS_PROXY_URL="socks5h://127.0.0.1:10808"

# Systemd 覆盖配置文件的路径 (使用 /run 表示临时，重启后失效)
# 这是NixOS和大多数Systemd系统通用的临时 override 目录
OVERRIDE_DIR="/run/systemd/system/nix-daemon.service.d"
OVERRIDE_FILE="$OVERRIDE_DIR/override.conf"

# --- Script Logic ---

# 1. 检查是否以 root 身份运行，如果不是，则用 sudo 重新运行脚本
if [ "$(id -u)" -ne 0 ]; then
  echo "This script needs root privileges to modify systemd services."
  echo "Re-running with sudo..."
  # 重新运行脚本时，确保传递所有参数，并保留 PATH 环境变量以便找到命令
  # 使用 exec 可以避免创建额外的shell层级
  exec sudo -E bash "$0" "$@"
fi

# 2. 定义核心功能函数
# 函数：应用代理配置并重启服务
apply_proxy() {
  local proxy_url="$1"
  echo "--> Setting Nix daemon proxy to: $proxy_url"

  # 创建覆盖目录
  mkdir -p "$OVERRIDE_DIR"

  # 使用 cat 和 heredoc 写入配置文件，安全且清晰
  # 为确保最大兼容性，同时设置大写和小写环境变量
  cat <<EOF >"$OVERRIDE_FILE"
[Service]
Environment="HTTPS_PROXY=$proxy_url" "HTTP_PROXY=$proxy_url" "ALL_PROXY=$proxy_url"
Environment="https_proxy=$proxy_url" "http_proxy=$proxy_url" "all_proxy=$proxy_url"
EOF

  echo "--> Reloading systemd daemon..."
  systemctl daemon-reload

  echo "--> Restarting nix-daemon service..."
  systemctl restart nix-daemon

  echo "✅ Proxy has been successfully set."
}

# 函数：清除代理配置
clear_proxy() {
  if [ -f "$OVERRIDE_FILE" ]; then
    echo "--> Clearing Nix daemon proxy configuration..."
    rm -f "$OVERRIDE_FILE"
    # 如果目录为空，也可以一并删除
    # 2>/dev/null || true 用于抑制错误，如果目录不为空，rmdir 会失败但脚本继续
    rmdir "$OVERRIDE_DIR" 2>/dev/null || true

    echo "--> Reloading systemd daemon..."
    systemctl daemon-reload

    echo "--> Restarting nix-daemon service..."
    systemctl restart nix-daemon

    echo "✅ Proxy has been successfully cleared."
  else
    echo "ℹ️ No active proxy configuration found. Nothing to do."
  fi
}

# 3. 解析用户输入参数
case "$1" in
http)
  apply_proxy "$HTTP_PROXY_URL"
  ;;
socks)
  apply_proxy "$SOCKS_PROXY_URL"
  ;;
off | clear)
  clear_proxy
  ;;
*)
  # 使用 basename "$0" 让用法提示更通用
  echo "Usage: $(basename "$0") {http|socks|off}"
  echo
  echo "  http      Set nix-daemon to use HTTP proxy ($HTTP_PROXY_URL)"
  echo "  socks     Set nix-daemon to use SOCKS5 proxy ($SOCKS_PROXY_URL)"
  echo "  off       Clear any proxy settings for nix-daemon"
  exit 1
  ;;
esac
