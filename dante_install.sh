#!/bin/sh

set -e

# 获取公网IP函数（尝试多个服务）
get_public_ip() {
  for url in https://api.ipify.org https://ifconfig.me https://ipinfo.io/ip; do
    ip=$(curl -fs $url || wget -qO- $url) && [ -n "$ip" ] && echo "$ip" && return
  done
  echo "0.0.0.0"
}

SERVER_IP=$(get_public_ip)
PORT=2025

# 读取输入函数，兼容 sh 和 bash
read_input() {
  printf "%s" "$1"
  if [ -t 0 ]; then
    read input
    echo "$input"
  else
    # 非交互环境，默认空
    echo ""
  fi
}

# 读取密码（隐藏输入）
read_password() {
  printf "%s" "$1"
  if command -v stty >/dev/null 2>&1; then
    stty -echo
    read pass
    stty echo
    printf "\n"
    echo "$pass"
  else
    read pass
    echo "$pass"
  fi
}

USERNAME=$(read_input "请输入 Socks5 用户名: ")
PASSWORD=$(read_password "请输入 Socks5 密码: ")

# 安装curl和wget（尝试多个包管理器）
install_tools() {
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update && apt-get install -y curl wget
  elif command -v yum >/dev/null 2>&1; then
    yum install -y curl wget
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y curl wget
  elif command -v pacman >/dev/null 2>&1; then
    pacman -Sy --noconfirm curl wget
  else
    echo "无法自动安装 curl/wget，请手动安装！"
    exit 1
  fi
}

if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
  install_tools
fi

# 下载原始脚本
if command -v curl >/dev/null 2>&1; then
  curl -fsSL -O https://raw.githubusercontent.com/Lozy/danted/master/install.sh
elif command -v wget >/dev/null 2>&1; then
  wget --no-check-certificate https://raw.githubusercontent.com/Lozy/danted/master/install.sh
else
  echo "未找到 curl 或 wget，无法下载安装脚本！"
  exit 1
fi

# 运行安装脚本
bash install.sh --ip="$SERVER_IP" --port=$PORT --user="$USERNAME" --passwd="$PASSWORD" --whitelist="0.0.0.0/0"
INSTALL_STATUS=$?

# 放行端口函数
open_firewall_port() {
  if command -v ufw >/dev/null 2>&1; then
    ufw allow $PORT/tcp || true
  fi
  if command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --permanent --add-port=$PORT/tcp && firewall-cmd --reload || true
  fi
  if command -v iptables >/dev/null 2>&1; then
    iptables -C INPUT -p tcp --dport $PORT -j ACCEPT 2>/dev/null || \
    iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
    if command -v iptables-save >/dev/null 2>&1; then
      iptables-save > /etc/iptables.rules || true
    fi
  fi
}

open_firewall_port

# 输出安装结果
if [ $INSTALL_STATUS -eq 0 ]; then
  echo "\n✅ Dante Socks5 安装成功！"
  echo "-----------------------------------------"
  echo "Socks5 地址: $SERVER_IP"
  echo "端口:        $PORT"
  echo "用户名:      $USERNAME"
  echo "密码:        $PASSWORD"
  echo "协议:        socks5"
  echo "-----------------------------------------"
else
  echo "\n❌ 安装失败，请检查上方日志信息。"
fi
