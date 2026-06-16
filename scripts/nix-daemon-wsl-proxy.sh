#!/usr/bin/env bash

# @file nix-daemon-wsl-proxy.sh
# @description NixOS WSL2 环境下 nix-daemon 代理配置工具
# @usage ./nix-daemon-wsl-proxy.sh {http|socks|off} [port]

set -e # 遇到错误立即退出

# --- 默认配置 ---
DEFAULT_HTTP_PORT=7890
DEFAULT_SOCKS_PORT=10808
OVERRIDE_DIR="/run/systemd/system/nix-daemon.service.d"
OVERRIDE_FILE="$OVERRIDE_DIR/override.conf"

##
# @description 获取 WSL2 宿主机的真实通信 IP 地址
# @returns string 探测到的宿主机 IP
##
_get_host_ip() {
  local host_ip

  # 获取默认路由的网关 IP（WSL2 宿主机的标准虚拟网卡地址）
  host_ip=$(ip route show default | awk '{print $3; exit}')

  # 如果路由表无法获取，则回退至从 resolv.conf 中提取 DNS 服务器地址
  if [[ -z $host_ip ]]; then
    host_ip=$(awk '/nameserver/ {print $2; exit}' /etc/resolv.conf 2>/dev/null)
  fi

  # 如果以上均失败，回退至本地回环地址（通常不适用于 WSL2 代理）
  echo "${host_ip:-127.0.0.1}"
}

# 变量初始化
HOST_IP=$(_get_host_ip)
HTTP_PORT=${2:-$DEFAULT_HTTP_PORT}
SOCKS_PORT=${2:-$DEFAULT_SOCKS_PORT}

##
# @description 权限检查：如果非 root 用户，则尝试使用 sudo 重新执行
##
_check_privileges() {
  if [[ $EUID -ne 0 ]]; then
    echo "[INFO] 权限不足，正在尝试通过 sudo 获取 root 权限..."
    exec sudo -E bash "$0" "$@"
  fi
}

##
# @description 应用代理配置并重启 nix-daemon
# @param 1 proxy_url 完整的代理 URL 地址
##
apply_proxy() {
  local proxy_url="$1"

  echo "[INFO] 探测到宿主机 IP: $HOST_IP"
  echo "[INFO] 正在配置代理: $proxy_url"

  # 确保 systemd 覆盖目录存在
  mkdir -p "$OVERRIDE_DIR"

  # 写入环境变量：涵盖大小写形式以确保工具兼容性
  cat <<EOF >"$OVERRIDE_FILE"
[Service]
Environment="HTTP_PROXY=$proxy_url" "HTTPS_PROXY=$proxy_url" "ALL_PROXY=$proxy_url"
Environment="http_proxy=$proxy_url" "https_proxy=$proxy_url" "all_proxy=$proxy_url"
EOF

  # 重新加载 systemd 配置并重启服务
  systemctl daemon-reload
  systemctl restart nix-daemon

  # 执行连通性验证测试
  _validate_connection "$proxy_url"
}

##
# @description 验证代理是否实际可用
# @param 1 proxy_url 待测试的代理地址
##
_validate_connection() {
  local proxy_url="$1"
  echo "[INFO] 正在验证代理连通性 (Target: GitHub)..."

  if curl -I --connect-timeout 5 -x "$proxy_url" https://github.com >/dev/null 2>&1; then
    echo "[SUCCESS] 代理验证通过，nix-daemon 已就绪。"
  else
    echo "[ERROR] 代理配置失败或无法连接。请检查："
    echo "  1. Windows 代理软件是否开启 'Allow LAN' (允许局域网连接)"
    echo "  2. Windows 防火墙是否放行了 $HTTP_PORT 端口"
    echo "  3. 宿主机代理软件是否在监听 $HOST_IP:$HTTP_PORT"
  fi
}

##
# @description 清除所有 nix-daemon 的代理配置
##
clear_proxy() {
  if [[ -f $OVERRIDE_FILE ]]; then
    echo "[INFO] 正在清除代理配置..."
    rm -f "$OVERRIDE_FILE"
    rmdir "$OVERRIDE_DIR" 2>/dev/null || true
    systemctl daemon-reload
    systemctl restart nix-daemon
    echo "[SUCCESS] 代理配置已移除。"
  else
    echo "[INFO] 未发现活动的代理配置，无需操作。"
  fi
}

# --- 执行入口 ---

_check_privileges "$@"

case "$1" in
http)
  apply_proxy "http://$HOST_IP:$HTTP_PORT"
  ;;
socks)
  # 使用 socks5h 协议以支持远程 DNS 解析
  apply_proxy "socks5h://$HOST_IP:$SOCKS_PORT"
  ;;
off | clear)
  clear_proxy
  ;;
*)
  echo "用法: $(basename "$0") {http|socks|off} [port]"
  exit 1
  ;;
esac
