#!/usr/bin/env bash
# git-proxy.sh - Git 命令代理包装器
#
# 用途：为 Git 命令临时设置代理环境变量
# 使用：./scripts/git-proxy.sh git push

set -euo pipefail

# 获取 WSL 网关 IP
if grep -qi "microsoft" /proc/version 2>/dev/null; then
  HOST=$(ip route 2>/dev/null | awk '/default/ {print $3; exit}')
  [[ -z $HOST ]] && HOST=$(awk '/nameserver/ {print $2; exit}' /etc/resolv.conf 2>/dev/null)
else
  HOST="127.0.0.1"
fi

PROXY_PORT="${PROXY_PORT:-7890}"
PROXY_URL="http://${HOST}:${PROXY_PORT}"

# 设置代理环境变量
export http_proxy="$PROXY_URL"
export https_proxy="$PROXY_URL"
export HTTP_PROXY="$PROXY_URL"
export HTTPS_PROXY="$PROXY_URL"

NO_PROXY="localhost,127.0.0.1,::1,*.local,*.lan,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,${HOST}"
export no_proxy="$NO_PROXY"
export NO_PROXY="$NO_PROXY"

# 执行传入的命令
exec "$@"
