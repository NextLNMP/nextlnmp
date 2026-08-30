#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "❌ 请使用 root 用户运行此脚本"
    exit 1
fi

cur_dir=$(pwd)
Stack=$1
if [ "${Stack}" = "" ]; then
    Stack="nextlnmp"
else
    Stack=$1
fi

NEXTLNMP_Ver='2.0.1'
. nextlnmp.conf
. include/main.sh
. include/ai-assist.sh
. include/php-select.sh
. include/init.sh
. include/mysql.sh
. include/mariadb.sh
. include/php.sh
. include/nginx.sh
. include/caddy.sh
. include/apache.sh
. include/end.sh
. include/only.sh
. include/multiplephp.sh

Get_Dist_Name

if [ "${DISTRO}" = "unknow" ]; then
    Echo_Red "Unable to get Linux distribution name, or do NOT support the current distribution."
    exit 1
fi

if [[ "${Stack}" = "nextlnmp" || "${Stack}" = "nextlnmpa" || "${Stack}" = "lamp" ]]; then
    if [ -f /bin/nextlnmp ]; then
        Echo_Red "nextLNMP 已安装过，请先卸载旧版本"
        echo -e "If you want to reinstall nextLNMP, please BACKUP your data.\nand run uninstall script: ./uninstall.sh before you install."
        exit 1
    fi
fi

Check_nextLNMPConf

clear
# Dynamic banner with CJK-aware padding (inner width=72)
_banner_pad() {
    local text="$1" width=72
    local byte_len=${#text}
    local ascii_only=$(printf '%s' "$text" | tr -dc '\x00-\x7F' | wc -c)
    local non_ascii=$(( byte_len - ascii_only ))
    local display_width=$(( ascii_only + non_ascii * 2 / 3 ))
    local pad=$(( width - display_width ))
    local left=$(( pad / 2 ))
    local right=$(( pad - left ))
    printf '|%*s%s%*s|\n' $left '' "$text" $right ''
}
echo "+------------------------------------------------------------------------+"
_banner_pad "NextLNMP v${NEXTLNMP_Ver} 一键建站安装程序"
echo "+------------------------------------------------------------------------+"
_banner_pad "安全可信 · SHA256 逐包校验 · 掌媒科技出品"
echo "+------------------------------------------------------------------------+"
_banner_pad "官网：nextlnmp.com · QQ群：615298"
echo "+------------------------------------------------------------------------+"

Init_Install()
{
    Press_Install
    Print_APP_Ver
    Get_Dist_Version
    Print_Sys_Info
    Check_Hosts
    Check_CMPT
    if [ "${CheckMirror}" != "n" ]; then
        Modify_Source
        Check_Mirror
    fi
    Add_Swap
    Set_Timezone
    if [ "$PM" = "yum" ]; then
        CentOS_InstallNTP
        CentOS_RemoveAMP
        CentOS_Dependent
    elif [ "$PM" = "apt" ]; then
        Deb_InstallNTP
        Xen_Hwcap_Setting
        Deb_RemoveAMP
        Deb_Dependent
    fi
    Disable_Selinux
    Check_Download
    Install_Libiconv
    Install_Libmcrypt
    Install_Mhash
    Install_Mcrypt
    Install_Freetype
    Install_Pcre
    Install_Icu4c
    if [ "${SelectMalloc}" = "2" ]; then
        Install_Jemalloc
    elif [ "${SelectMalloc}" = "3" ]; then
        Install_TCMalloc
    fi
    if [ "$PM" = "yum" ]; then
        CentOS_Lib_Opt
    elif [ "$PM" = "apt" ]; then
        Deb_Lib_Opt
    fi
    if [ "${DBSelect}" = "1" ]; then
        Install_MySQL_51
    elif [ "${DBSelect}" = "2" ]; then
        Install_MySQL_55
    elif [ "${DBSelect}" = "3" ]; then
        Install_MySQL_56
    elif [ "${DBSelect}" = "4" ]; then
        Install_MySQL_57
    elif [ "${DBSelect}" = "5" ]; then
        Install_MySQL_80
    elif [ "${DBSelect}" = "6" ]; then
        Install_MariaDB_5
    elif [ "${DBSelect}" = "7" ]; then
        Install_MariaDB_104
    elif [ "${DBSelect}" = "8" ]; then
        Install_MariaDB_105
    elif [ "${DBSelect}" = "9" ]; then
        Install_MariaDB_106
    elif [ "${DBSelect}" = "10" ]; then
        Install_MariaDB_1011
    elif [ "${DBSelect}" = "11" ]; then
        Install_MySQL_84
    elif [ "${DBSelect}" = "12" ] || [ "${DBSelect}" = "13" ]; then
        # 11.8/12.3 与 10.11 安装流程一致，函数按 ${Mariadb_Ver} 参数化
        Install_MariaDB_1011
    fi
    TempMycnf_Clean
    Clean_DB_Src_Dir
    Check_PHP_Option
}

Install_PHP()
{
    if [ "${PHPSelect}" = "1" ]; then
        Install_PHP_52
    elif [ "${PHPSelect}" = "2" ]; then
        Install_PHP_53
    elif [ "${PHPSelect}" = "3" ]; then
        Install_PHP_54
    elif [ "${PHPSelect}" = "4" ]; then
        Install_PHP_55
    elif [ "${PHPSelect}" = "5" ]; then
        Install_PHP_56
    elif [ "${PHPSelect}" = "6" ]; then
        Install_PHP_7
    elif [ "${PHPSelect}" = "7" ]; then
        Install_PHP_71
    elif [ "${PHPSelect}" = "8" ]; then
        Install_PHP_72
    elif [ "${PHPSelect}" = "9" ]; then
        Install_PHP_73
    elif [ "${PHPSelect}" = "10" ]; then
        Install_PHP_74
    elif [ "${PHPSelect}" = "11" ]; then
        Install_PHP_80
    elif [ "${PHPSelect}" = "12" ]; then
        Install_PHP_81
    elif [ "${PHPSelect}" = "13" ]; then
        Install_PHP_82
    elif [ "${PHPSelect}" = "14" ]; then
        Install_PHP_83
    elif [ "${PHPSelect}" = "15" ]; then
        Install_PHP_84
    fi
    Clean_PHP_Src_Dir
}

nextLNMP_Stack()
{
    Init_Install
    Install_PHP
    nextLNMP_PHP_Opt
    if [ "${WebServer}" = "nginx" ]; then
        Install_Nginx
    elif [ "${WebServer}" = "caddy" ]; then
        Install_Caddy
    fi
    Creat_PHP_Tools
    Add_Iptables_Rules
    Add_nextLNMP_Startup
    Check_nextLNMP_Install
}

nextLNMPA_Stack()
{
    Apache_Selection
    Init_Install
    if [ "${ApacheSelect}" = "1" ]; then
        Install_Apache_22
    else
        Install_Apache_24
    fi
    Install_PHP
    Install_Nginx
    Creat_PHP_Tools
    Add_Iptables_Rules
    Add_nextLNMPA_Startup
    Check_nextLNMPA_Install
}

LAMP_Stack()
{
    Apache_Selection
    Init_Install
    if [ "${ApacheSelect}" = "1" ]; then
        Install_Apache_22
    else
        Install_Apache_24
    fi
    Install_PHP
    Creat_PHP_Tools
    Add_Iptables_Rules
    Add_LAMP_Startup
    Check_LAMP_Install
}

# 安装日志里会出现自动生成的数据库 root 密码（成功面板会把它打出来），
# 而 tee 是按 umask 建文件的，默认就是 0644 —— 同机任何用户都能读。
# 先以 600 建好再让 tee 往里写。
Install_Log_Init()
{
    local f="$1"
    rm -f "${f}"
    (umask 077; : > "${f}")
}

case "${Stack}" in
    nextlnmp)
        Display_Selection
# 注意取 PIPESTATUS[0]：整条命令的 $? 是 tee 的（恒为 0），
        # 安装链路里所有 exit 1（下载失败、SHA256 不符、系统不兼容）都只杀掉
        # 管道左侧的子 shell，对外一律报成功——CI、自动化脚本、以及"装完再判断"
        # 的调用方全被骗过去。这里不用 set -o pipefail，因为脚本里还有
        # `cmd | grep -q` 这类条件判断，全局开 pipefail 会改掉它们的语义。
        Install_Log_Init /root/nextlnmp-install.log
        nextLNMP_Stack 2>&1 | tee /root/nextlnmp-install.log
        Install_Rc=${PIPESTATUS[0]}
        ;;
    nextlnmpa)
        Display_Selection
# 注意取 PIPESTATUS[0]：整条命令的 $? 是 tee 的（恒为 0），
        # 安装链路里所有 exit 1（下载失败、SHA256 不符、系统不兼容）都只杀掉
        # 管道左侧的子 shell，对外一律报成功——CI、自动化脚本、以及"装完再判断"
        # 的调用方全被骗过去。这里不用 set -o pipefail，因为脚本里还有
        # `cmd | grep -q` 这类条件判断，全局开 pipefail 会改掉它们的语义。
        Install_Log_Init /root/nextlnmp-install.log
        nextLNMPA_Stack 2>&1 | tee /root/nextlnmp-install.log
        Install_Rc=${PIPESTATUS[0]}
        ;;
    lamp)
        Display_Selection
# 注意取 PIPESTATUS[0]：整条命令的 $? 是 tee 的（恒为 0），
        # 安装链路里所有 exit 1（下载失败、SHA256 不符、系统不兼容）都只杀掉
        # 管道左侧的子 shell，对外一律报成功——CI、自动化脚本、以及"装完再判断"
        # 的调用方全被骗过去。这里不用 set -o pipefail，因为脚本里还有
        # `cmd | grep -q` 这类条件判断，全局开 pipefail 会改掉它们的语义。
        Install_Log_Init /root/nextlnmp-install.log
        LAMP_Stack 2>&1 | tee /root/nextlnmp-install.log
        Install_Rc=${PIPESTATUS[0]}
        ;;
    nginx)
        Install_Log_Init /root/nginx-install.log
        Install_Only_Nginx 2>&1 | tee /root/nginx-install.log
        Install_Rc=${PIPESTATUS[0]}
        ;;
    db)
        Install_Only_Database
        ;;
    mphp)
        Install_Multiplephp
        ;;
    *)
        Echo_Red "Usage: $0 {nextlnmp|nextlnmpa|lamp}"
        Echo_Red "Usage: $0 {nginx|db|mphp}"
        ;;
esac

# 装挂了就必须以非 0 退出，否则 `bash install.sh && echo 成功` 之类的
# 调用方永远看不到失败。
exit ${Install_Rc:-0}
