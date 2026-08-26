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
echo "|    nextLNMP 服务器管理工具 by 静水流深    |"
echo "+-------------------------------------------+"
echo "|              https://nextlnmp.com             |"
echo "+-------------------------------------------+"

# ===== 栈参数（公共函数据此适配，改这里不要改 common.sh）=====
Stack_Web='apache'
Vhost_Dir='/usr/local/apache/conf/vhost'
Web_SSL_Dir='/usr/local/apache/conf/ssl'
Web_Initd='/etc/init.d/httpd'

arg1=$1
arg2=$2


# ===== NextLNMP CLI 公共函数库（由 tools/build-cli.sh 拼装，勿直接编辑生成物）=====
