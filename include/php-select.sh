#!/usr/bin/env bash
# 【生成物】由 tools/build-cli.sh 从 conf/cli/php-select.sh 生成，请勿直接编辑。
# ===== 多版本 PHP 探测与选择（单一事实源）=====
# 新增 PHP 版本只需改 MPHP_VERSIONS 一行；CLI（构建期内嵌）与 addons.sh
# （运行期 source include/php-select.sh）共用同一份实现，杜绝「改一处漏一处」。
# 选项编号沿用历史约定：2 起对应 MPHP_VERSIONS 的第 1 项，保证老用户手感不变。
MPHP_VERSIONS='5.2 5.3 5.4 5.5 5.6 7.0 7.1 7.2 7.3 7.4 8.0 8.1 8.2 8.3 8.4'
MPHP_ROOT="${MPHP_ROOT:-/usr/local}"
MPHP_NGXCONF="${MPHP_NGXCONF:-/usr/local/nginx/conf}"
MPHP_INITD="${MPHP_INITD:-/etc/init.d}"

# 探测已安装的多版本 PHP，结果写入 MPHP_FOUND；有则返回 0
PHP_Multi_Detect()
{
    MPHP_FOUND=''
    local v
    for v in ${MPHP_VERSIONS}; do
        if [[ -s "${MPHP_ROOT}/php${v}/sbin/php-fpm" && -s "${MPHP_NGXCONF}/enable-php${v}.conf" && -s "${MPHP_INITD}/php-fpm${v}" ]]; then
            MPHP_FOUND="${MPHP_FOUND}${v} "
        fi
    done
    MPHP_FOUND="${MPHP_FOUND% }"
    [ -n "${MPHP_FOUND}" ]
}

# 交互选择 PHP 版本；结果写入 PHP_Select_Ver（空串 = 主 PHP）
PHP_Multi_Select()
{
    PHP_Select_Ver=''
    PHP_Multi_Detect || return 0
    local cur idx v pick
    cur="$(${MPHP_ROOT}/php/bin/php-config --version 2>/dev/null)"
    echo "Multiple PHP version found, Please select the PHP version."
    Echo_Green "1: Default Main PHP ${cur}"
    idx=1
    for v in ${MPHP_VERSIONS}; do
        idx=$((idx + 1))
        case " ${MPHP_FOUND} " in
            *" ${v} "*) Echo_Green "${idx}: PHP ${v} [found]" ;;
        esac
    done
    Echo_Yellow "Enter your choice (1-${idx}): "
    read pick
    case "${pick}" in
        ''|1) return 0 ;;
    esac
    if [ "${pick}" -ge 2 ] 2>/dev/null && [ "${pick}" -le "${idx}" ] 2>/dev/null; then
        v="$(echo ${MPHP_VERSIONS} | cut -d' ' -f$((pick - 1)))"
        case " ${MPHP_FOUND} " in
            *" ${v} "*) PHP_Select_Ver="${v}"; echo "Current selection: PHP ${v}"; return 0 ;;
        esac
    fi
    echo "Default, Current selection: PHP ${cur}"
}
