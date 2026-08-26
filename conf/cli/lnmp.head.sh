#!/bin/bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script!"
    exit 1
else
    if env |grep -q SUDO; then
        acme_sh_sudo="-f"
    fi
fi

echo "+-------------------------------------------+"
echo "|    NextLNMP 服务器管理工具 by 静水流深    |"
echo "+-------------------------------------------+"
echo "|          https://nextlnmp.cn              |"
echo "+-------------------------------------------+"

PHPFPMPIDFILE=/usr/local/php/var/run/php-fpm.pid

arg1=$1
arg2=$2

