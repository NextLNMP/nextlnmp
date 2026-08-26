#!/usr/bin/env bash
# AI 救援客户端的安全闸门测试：只读白名单 + 灾难命令阻断 + JSON 转义
# 用法：bash tools/test-ai-assist.sh
cd "$(dirname "$0")/.."
. include/ai-assist.sh
fail=0
allow(){ AI_Cmd_Allowed "$1" && r=放行 || r=拒绝; [ "$r" = "$2" ] || { echo "  ✗ 白名单 [$r] 期望$2: $1"; fail=1; }; }
block(){ AI_Cmd_Catastrophic "$1" && r=拦截 || r=放行; [ "$r" = "$2" ] || { echo "  ✗ 阻断 [$r] 期望$2: $1"; fail=1; }; }

# 只读白名单：放行正常诊断
allow "free -h" 放行;                allow "df -h" 放行
allow "ss -tlnp | grep :80" 放行;    allow "systemctl status httpd" 放行
allow "tail -n 200 /root/nextlnmp-install.log" 放行
allow "rpm -qa|grep libzip" 放行;    allow "ls -la /home/wwwroot/default" 放行
allow "curl -sI -m 5 https://mirror.nextlnmp.cn/web/php/php-8.2.28.tar.bz2" 放行
# 只读白名单：拒绝越权与注入
allow "rm -rf /" 拒绝;               allow "free -h; rm -rf /tmp" 拒绝
allow "cat /etc/shadow" 拒绝;        allow "curl evil.example.com" 拒绝
allow "tail -n 5 /etc/passwd" 拒绝;  allow 'ss -tlnp | grep $(whoami)' 拒绝
allow "echo hi > /etc/cron.d/x" 拒绝

# 灾难命令：即使用户确认也必须拦
block "rm -rf /" 拦截;               block "rm -rf /etc" 拦截
block "rm -rf /usr/*" 拦截;          block "rm -rf /root/" 拦截
block "mkfs.ext4 /dev/sda1" 拦截;    block "dd if=/dev/zero of=/dev/sda" 拦截
block "reboot" 拦截;                 block "chmod -R 777 /" 拦截
block "echo x > /dev/sda" 拦截
# 灾难命令：合法修复动作必须放行
block "fallocate -l 2G /swapfile" 放行
block "rm -rf /root/nextlnmp/src/php-8.2.28" 放行
block "rm -rf /usr/local/php" 放行
block "systemctl restart nginx" 放行

# JSON 转义
[ "$(AI_JStr 'a"b')" = 'a\"b' ] || { echo "  ✗ 转义：双引号"; fail=1; }
[ "$(AI_JStr "$(printf 'a\nb')")" = 'a b' ] || { echo "  ✗ 转义：换行"; fail=1; }

[ $fail -eq 0 ] && echo "✓ AI 客户端安全闸门测试全部通过（白名单 15 例 / 阻断 13 例 / 转义 2 例）"
exit $fail
