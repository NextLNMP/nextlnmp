#!/usr/bin/env bash
# ============================================================================
# NextLNMP AI 安装救援客户端
# 安装失败时自动进入对话：网关给诊断，需要更多信息时请求【只读】命令，
# 修复命令一律 y/N 确认后才执行。
#
# 铁律（不可退让）：
#   · 永不阻塞安装 —— 网关超时/异常/不可达一律静默跳过
#   · 只读命令必须过本地白名单（服务端也有一份，双重保险）
#   · 写命令永远 y/N，v2.0 不做自动执行
#   · NEXTLNMP_AI=n 整段关闭
# 契约：~/.claude/契约-NextLNMP-AI网关-v2.0-2026-08-26.md
# ============================================================================

AI_ENDPOINT="${AI_ENDPOINT:-https://mirror.nextlnmp.cn/ai/chat}"
AI_TIMEOUT="${AI_TIMEOUT:-60}"
AI_MAX_ROUNDS="${AI_MAX_ROUNDS:-10}"
AI_LOG="${AI_LOG:-/root/nextlnmp-install.log}"

# ---- 只读命令白名单：任何 DIAG 都必须整行匹配，否则拒绝执行 ----
AI_Cmd_Allowed()
{
    local cmd="$1"
    # 先毙掉 shell 元字符（放行的管道形态在下面白名单里逐条列出）
    case "${cmd}" in
        *';'*|*'&'*|*'`'*|*'$('*|*'>'*|*'<'*) return 1 ;;
    esac
    local logs='(/root/nextlnmp-install\.log|/root/[a-z0-9_-]+\.log|/usr/local/nginx/logs/[a-z._-]+|/var/log/nginx/[a-z._-]+|/usr/local/php/var/log/[a-z._-]+|/usr/local/(mysql|mariadb)/var/[A-Za-z0-9._-]+)'
    local dirs='(/usr/local/(nginx|apache|php|mysql|mariadb)[A-Za-z0-9./-]*|/home/wwwroot[A-Za-z0-9./-]*|/root/nextlnmp/src[A-Za-z0-9./-]*)'
    local svcs='(nginx|php-fpm|mysql|mysqld|mariadb|httpd|caddy|pureftpd|redis|memcached)[A-Za-z0-9._-]*'
    grep -Eq "^(\
free -h|df -h|uname -a|lsblk|id www|php -v|nginx -t|\
cat /etc/os-release|cat /etc/my\.cnf|\
ss -tlnp( \| grep [A-Za-z0-9:._-]+)?|\
systemctl status ${svcs}|\
tail -n [0-9]+ ${logs}|\
(rpm -qa|dpkg -l) ?\| ?grep [A-Za-z0-9._-]+|\
ls -la ${dirs}|\
curl -sI( -m [0-9]+)? https://mirror\.nextlnmp\.cn/[A-Za-z0-9./_-]*\
)$" <<< "${cmd}"
}

# 命令里出现控制字符一律不收。根源是显示用的 Echo_Yellow 走 Color_Text 的
# `echo -e`，会解释反斜杠转义：模型只要在 fix 里塞一个回车符，终端上的确认行
# 就被覆盖成另一条无害命令，而用户按 y 之后 eval 跑的是真实内容——
# 「你看到什么就执行什么」这个前提被打破，y/N 确认形同虚设。本机已复现。
# 同理换行符可以伪造出额外的 FIX:/DIAG:/DONE 协议行，绕过白名单与危险模式过滤。
AI_Cmd_Printable()
{
    # 内嵌换行 grep 是看不见的（它按行切分），必须单独数一次换行符。
    [ "$(printf '%s' "$1" | wc -l)" -gt 0 ] && return 1
    printf '%s' "$1" | LC_ALL=C grep -q '[[:cntrl:]]' && return 1
    return 0
}

# 灾难命令硬阻断：即使用户按了 y 也不执行（网关幻觉或被篡改时的最后一道闸）
AI_Cmd_Catastrophic()
{
    local c="$1" n
    # 先归一化再判：去掉引号、把连续空白压成一个。否则 rm -rf "/" 这种
    # 只要插一个引号就能从字符串匹配里溜过去。
    n=$(printf '%s' "${c}" | tr -d "\"'" | tr -s '[:space:]' ' ')
    case "${n}" in
        *"rm -rf /"|*"rm -rf /"[!a-zA-Z0-9]*|*"rm -fr /"|*"rm -fr /"[!a-zA-Z0-9]*) return 0 ;;
    esac
    # rm 带递归/强制标志、且参数里出现裸 / 或裸系统目录 —— 不要求它在行尾，
    # 否则 `rm -rf /etc /usr` 这种多目标写法会漏掉。
    printf '%s' "${n}" | grep -Eq "(^|[[:space:]|;&])rm([[:space:]]+-[-a-zA-Z]+)*[[:space:]]+([^[:space:]]+[[:space:]]+)*(/|/etc|/usr|/var|/home|/boot|/bin|/sbin|/lib|/lib64|/opt|/root|/srv)(/\*)?([[:space:]]|$)" && return 0
    grep -Eq "(^|[[:space:]])(mkfs([.][a-z0-9]+)?|fdisk|sgdisk|parted|shutdown|reboot|halt|userdel|passwd)([[:space:]]|$)" <<< "${n}" && return 0
    # 只拦「裸系统目录」本身（/etc、/usr/ 、/root/*），放行更深的合法路径如 /usr/local/php、/root/nextlnmp/src/xxx
    grep -Eq "rm[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*(/etc|/usr|/var|/home|/boot|/bin|/sbin|/lib|/root)(/\*|/)?[[:space:]]*$" <<< "${n}" && return 0
    grep -Eq "dd[[:space:]].*of=/dev/" <<< "${n}" && return 0
    grep -Eq ">[[:space:]]*/dev/(sd|nvme|vd)" <<< "${n}" && return 0
    grep -Eq "chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/([[:space:]]|$)" <<< "${n}" && return 0
    grep -Eq ":\(\)\{.*\};:" <<< "${n}" && return 0
    return 1
}

# 交互读取：优先 /dev/tty（安装走 tee 管道时 stdin 可能被占），无 tty 时回退 stdin
AI_Read()
{
    local __var="$1" __prompt="$2"
    if { : < /dev/tty; } 2>/dev/null; then
        read -r -p "${__prompt}" "${__var}" < /dev/tty
    else
        read -r -p "${__prompt}" "${__var}"
    fi
}

AI_B64() { base64 2>/dev/null | tr -d '\n'; }

# JSON 字符串转义（只用于我们自己产生的短字段）
AI_JStr() { printf '%s' "$1" | tr -d '\015' | tr '
	' '  ' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

AI_Post()
{
    curl -sS -m "${AI_TIMEOUT}" -X POST "${AI_ENDPOINT}?fmt=text" \
         -H 'Content-Type: application/json' --data-binary @- 2>/dev/null
}

# 上传前把日志里的密码抹掉。安装日志里明摆着有这些：
#   数据库 root 密码已自动生成：
#     密码：vXkaSHbIJoIIQ3G8
# 只要它落在最后 12KB 里就会跟着传出去。
AI_Scrub_Log()
{
    local sed_args=()
    # 已知的具体密码值优先精确替换（最可靠，不依赖措辞）
    local v esc
    for v in "${DB_Root_Password}" "${mysql_password}" "${ftp_account_password}"; do
        if [ -n "${v}" ] && [ "${#v}" -ge 6 ]; then
            esc=$(printf '%s' "${v}" | sed 's/[]\/$*.^[]/\\&/g')
            sed_args+=(-e "s|${esc}|***已屏蔽***|g")
        fi
    done
    # 再按措辞兜一遍。注意：不能把全角冒号塞进方括号——sed 按字节处理，
    # 多字节字符进方括号会乱匹配，把标签本身也吃掉，AI 反而少了诊断线索。
    # 所以全角/半角各写一条，标签原样保留，只换值。
    sed "${sed_args[@]}" \
        -e 's/密码：[^[:space:]]\{4,\}/密码：***已屏蔽***/g' \
        -e 's/密码:[[:space:]]*[^[:space:]]\{4,\}/密码: ***已屏蔽***/g' \
        -e 's/\([Pp]assword[[:space:]]*[:=][[:space:]]*\)[^[:space:]]\{4,\}/\1***已屏蔽***/g' \
        -e "s/\(IDENTIFIED BY[[:space:]]*'\)[^']*\('\)/\1***已屏蔽***\2/g" \
        -e 's/\(-p\)[A-Za-z0-9!@#$%^&*_+=-]\{6,\}/\1***已屏蔽***/g' \
        -e 's/\([Tt]oken[[:space:]]*[:=][[:space:]]*\)[A-Za-z0-9_-]\{12,\}/\1***已屏蔽***/g'
}

# 上传前征求同意。原来是"失败即自动上传、不问"，改为问一句——
# 日志尾部可能带着数据库密码等信息，发出去之前该让用户知道并点头。
AI_Consent()
{
    echo ""
    Echo_Yellow "────────────────────────────────────────────────"
    Echo_Yellow " 安装失败了。可以让 AI 帮你分析原因（免费，无需配置）"
    echo ""
    echo "  需要上传：安装日志的最后 12KB（用于定位问题）"
    echo "  已自动屏蔽其中的密码字段"
    echo "  日志仅用于本次分析，网关侧 24 小时后清除"
    echo ""
    Echo_Yellow " 不需要就按 n；永久关闭本功能：NEXTLNMP_AI=n"
    Echo_Yellow "────────────────────────────────────────────────"
    local __ok=''
    AI_Read __ok "  要现在分析吗？[Y/n] "
    case "${__ok}" in
        [nN]|[nN][oO]) return 1 ;;
    esac
    return 0
}

# 安装失败时调用：AI_Rescue "<失败步骤描述>"
AI_Rescue()
{
    [ "${NEXTLNMP_AI}" = "n" ] && return 0
    command -v curl >/dev/null 2>&1 || return 0
    command -v base64 >/dev/null 2>&1 || return 0

    local step="$(AI_JStr "$1")"
    local os_name="$(AI_JStr "$( [ -f /etc/os-release ] && . /etc/os-release && echo "${PRETTY_NAME:-${ID} ${VERSION_ID}}" )")"
    local arch="$(uname -m)"
    local ver="$(AI_JStr "${NEXTLNMP_Ver:-unknown}")"
    local log_b64=''
    [ -s "${AI_LOG}" ] || return 0      # 没有日志可交，不打扰用户

    AI_Consent || { echo "  已跳过 AI 分析。"; return 0; }

    # 脱敏之后再编码上传
    log_b64="$(tail -c 12000 "${AI_LOG}" | AI_Scrub_Log | AI_B64)"
    [ -z "${log_b64}" ] && return 0

    local payload resp sess round=0 diag_json reply
    payload="$(printf '{"ver":"%s","step":"%s","os":"%s","arch":"%s","log_b64":"%s"}' \
               "${ver}" "${step}" "${os_name}" "${arch}" "${log_b64}")"

    while [ ${round} -lt ${AI_MAX_ROUNDS} ]; do
        round=$((round + 1))
        resp="$(printf '%s' "${payload}" | AI_Post)"
        if [ -z "${resp}" ]; then
            Echo_Yellow "（AI 服务暂时不可用，跳过；安装流程不受影响）"
            return 0
        fi

        sess="$(grep -m1 '^SESSION: ' <<< "${resp}" | cut -d' ' -f2-)"
        grep '^SAY: ' <<< "${resp}" | cut -c6- | while IFS= read -r line; do echo "  ${line}"; done
        grep -q '^HEAL: ' <<< "${resp}" && Echo_Green "  ✓ 已受理镜像补货：$(grep '^HEAL: ' <<< "${resp}" | cut -c7- | tr '\n' ' ')"
        grep '^HUMAN: ' <<< "${resp}" | cut -c8- | while IFS= read -r line; do Echo_Yellow "  ${line}"; done

        # ---- FIX：写命令，逐条 y/N ----
        local fix
        while IFS= read -r fix; do
            [ -z "${fix}" ] && continue
            echo ""
            if ! AI_Cmd_Printable "${fix}"; then
                Echo_Red "  ⛔ 命令含控制字符，拒绝执行（显示可能与实际执行不一致）"
                continue
            fi
            if AI_Cmd_Catastrophic "${fix}"; then
                Echo_Red "  ⛔ 已拦截高危命令，拒绝执行：${fix}"
                continue
            fi
            # 用 printf 展示，不走 Echo_Yellow —— 后者经 Color_Text 的 echo -e，
            # 会解释反斜杠转义，等于把「你看到什么就执行什么」这个前提交出去。
            printf '  \033[0;33m建议执行：\033[0m%s\n' "${fix}"
            AI_Read yn "  要现在执行吗？[y/N] "
            case "${yn}" in
                [yY]) eval "${fix}" ;;
                *) echo "  已跳过" ;;
            esac
        done < <(grep '^FIX: ' <<< "${resp}" | cut -c6-)

        grep -q '^DONE$' <<< "${resp}" && break

        # ---- DIAG：只读命令，过白名单后执行并回传 ----
        diag_json=''
        local cmd out
        while IFS= read -r cmd; do
            [ -z "${cmd}" ] && continue
            if ! AI_Cmd_Printable "${cmd}"; then
                Echo_Yellow "  （已拒绝含控制字符的命令）"
                continue
            fi
            if ! AI_Cmd_Allowed "${cmd}"; then
                Echo_Yellow "  （已拒绝不在只读白名单内的命令：${cmd}）"
                continue
            fi
            echo "  正在收集：${cmd}"
            out="$(timeout 15 bash -c "${cmd}" 2>&1 | tail -c 4000 | AI_B64)"
            [ -n "${diag_json}" ] && diag_json="${diag_json},"
            diag_json="${diag_json}{\"cmd\":\"$(AI_JStr "${cmd}")\",\"out_b64\":\"${out}\"}"
        done < <(grep '^DIAG: ' <<< "${resp}" | cut -c7-)

        if [ -z "${diag_json}" ]; then
            echo ""
            AI_Read reply "  还有什么要补充的？（直接回车结束） "
            [ -z "${reply}" ] && break
        fi
        payload="$(printf '{"session":"%s","diag":[%s],"reply":"%s"}' \
                   "${sess}" "${diag_json}" "$(AI_JStr "${reply}")")"
        reply=''
    done
    echo ""
    Echo_Yellow " 排查完成后建议改一次数据库密码：日志已上传做分析，虽然已屏蔽密码字段，"
    Echo_Yellow " 但换一次更稳妥。命令：nextlnmp password"
    Echo_Yellow " 如需人工协助：带上 ${AI_LOG} 加 QQ 群 615298"
    echo ""
    return 0
}
