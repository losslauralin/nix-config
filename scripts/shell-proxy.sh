#!/usr/bin/env bash
# shell-proxy.sh - Shell 会话代理设置
#
# 用途：为当前 shell 会话设置代理环境变量
# 使用：source ./scripts/shell-proxy.sh [port]
#       或：./scripts/shell-proxy.sh && export $(grep "^proxy" /tmp/proxy.env)

set -euo pipefail

PROXY_PORT="${1:-7890}"

# 检测是否在 WSL
_is_wsl() {
  [[ -n ${WSL_DISTRO_NAME:-} ]] && return 0
  grep -qi "microsoft" /proc/version 2>/dev/null
}

# 获取宿主机地址
_get_host() {
  if _is_wsl; then
    # 优先使用默认路由网关
    local gw
    gw=$(ip route 2>/dev/null | awk '/default/ {print $3; exit}')
    [[ -z $gw ]] && gw=$(awk '/nameserver/ {print $2; exit}' /etc/resolv.conf 2>/dev/null)
    echo "${gw:-127.0.0.1}"
  else
    echo "127.0.0.1"
  fi
}

# 设置代理
HOST=$(_get_host)
PROXY_URL="http://${HOST}:${PROXY_PORT}"

export http_proxy="$PROXY_URL"
export https_proxy="$PROXY_URL"
export HTTP_PROXY="$PROXY_URL"
export HTTPS_PROXY="$PROXY_URL"

# 不代理本地和内网
NO_PROXY="localhost,127.0.0.1,::1,*.local,*.lan,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,${HOST}"
export no_proxy="$NO_PROXY"
export NO_PROXY="$NO_PROXY"

echo "Proxy enabled: ${HOST}:${PROXY_PORT}"
echo "no_proxy=$NO_PROXY"
