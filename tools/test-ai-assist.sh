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


# ---- 审计发现的绕过（2026-08-27 网关专项审计）----
# 这三条以前都能溜过去：--no-preserve-root 把字符串匹配拆开、引号把 "/" 藏起来、
# 多目标写法让"目录必须在行尾"的规则落空。
block "rm -rf --no-preserve-root /" 拦截
block 'rm -rf "/"' 拦截
block "rm -rf /etc /usr" 拦截
block "rm -fr --no-preserve-root /" 拦截

# ---- 控制字符：显示与执行不一致 ----
# 根源是展示走 Color_Text 的 echo -e，模型在 fix 里塞一个回车符，
# 终端上的确认行就被覆盖成另一条无害命令，而 eval 跑的是真实内容。
if AI_Cmd_Printable "$(printf 'touch /tmp/x ;#\r  建议执行：systemctl status nginx')"; then
    echo "  ✗ 控制字符：带回车符的命令未被拦截"; fail=1
fi
if AI_Cmd_Printable "$(printf 'a\nFIX: rm -rf /')"; then
    echo "  ✗ 控制字符：带换行的命令未被拦截（可伪造协议行）"; fail=1
fi
AI_Cmd_Printable "systemctl status nginx" || { echo "  ✗ 控制字符：正常命令被误拦"; fail=1; }
AI_Cmd_Printable "ls -la /home/wwwroot/中文站点" || { echo "  ✗ 控制字符：含中文的正常命令被误拦"; fail=1; }

# ---- 反斜杠转义（原写法 s/[\]/\\/g 是空操作）----
[ "$(AI_JStr 'a\\\\b')" = 'a\\\\\\\\b' ] || { echo "  ✗ 转义：反斜杠未被转义"; fail=1; }

[ $fail -eq 0 ] && echo "✓ AI 客户端安全闸门测试全部通过（白名单 15 / 阻断 17 / 控制字符 4 / 转义 3 例）"
exit $fail
