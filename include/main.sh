#!/usr/bin/env bash

DB_Info=('MySQL 5.1.73' 'MySQL 5.5.62' 'MySQL 5.6.51' 'MySQL 5.7.44' 'MySQL 8.0.37' 'MariaDB 5.5.68' 'MariaDB 10.4.33' 'MariaDB 10.5.24' 'MariaDB 10.6.17' 'MariaDB 10.11.7' 'MySQL 8.4.4')
PHP_Info=('PHP 5.2.17' 'PHP 5.3.29' 'PHP 5.4.45' 'PHP 5.5.38' 'PHP 5.6.40' 'PHP 7.0.33' 'PHP 7.1.33' 'PHP 7.2.34' 'PHP 7.3.33' 'PHP 7.4.33' 'PHP 8.0.30' 'PHP 8.1.28' 'PHP 8.2.28' 'PHP 8.3.7' 'PHP 8.4.18')
Apache_Info=('Apache 2.2.34' 'Apache 2.4.57')

# ── 智能推荐：根据硬件自动计算最优安装方案 ──
# 设计原则：
#   1. 数据库统一 MySQL 5.7 — 1G能跑，迁移无痛，避免跨版本坑
#   2. PHP 统一 8.2 — 当前最佳平衡
#   3. 编译方式统一预编译 — 省时省内存
#   4. 内存分配器按内存分级 — 唯一需要区分的
#   5. 安装后根据内存自动优化 my.cnf
Smart_Recommend()
{
    REC_MEM=$(awk '/MemTotal/ {printf("%d", $2 / 1024)}' /proc/meminfo)
    REC_CPU=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo 1)
    REC_DISK=$(df -BG / | awk 'NR==2 {gsub("G",""); print $4}')

    # 统一推荐
    REC_DB=4        # MySQL 5.7 — 全配置通用
    REC_PHP=13      # PHP 8.2
    REC_BIN="y"     # 预编译二进制

    # 内存分配器按内存分级
    if [ ${REC_MEM} -le 2048 ]; then
        REC_MALLOC=1; REC_MALLOC_NAME="不安装（节省资源）"
    else
        REC_MALLOC=2; REC_MALLOC_NAME="Jemalloc（优化内存管理）"
    fi

    # my.cnf 优化参数（安装后自动写入）
    if [ ${REC_MEM} -le 768 ]; then
        REC_INNODB_POOL="64M"; REC_PFS="OFF"; REC_MAXCONN=30
        REC_MEM_LEVEL="极小内存模式"
    elif [ ${REC_MEM} -le 1536 ]; then
        REC_INNODB_POOL="128M"; REC_PFS="OFF"; REC_MAXCONN=50
        REC_MEM_LEVEL="小内存优化模式"
    elif [ ${REC_MEM} -le 3072 ]; then
        REC_INNODB_POOL="256M"; REC_PFS="ON"; REC_MAXCONN=100
        REC_MEM_LEVEL="标准模式"
    else
        local pool_mb=$((REC_MEM / 4))
        REC_INNODB_POOL="${pool_mb}M"; REC_PFS="ON"; REC_MAXCONN=200
        REC_MEM_LEVEL="高性能模式"
    fi

    echo ""
    Echo_Yellow "╭─────────── 硬件检测 & 智能推荐 ───────────╮"
    echo "│"
    echo "│  🖥  CPU：${REC_CPU} 核 · 内存：${REC_MEM} MB · 磁盘可用：${REC_DISK} GB"
    echo "│"
    echo "│  📋 推荐方案（${REC_MEM_LEVEL}）："
    echo "│     数据库 → MySQL 5.7（全配置通用，迁移无痛）"
    echo "│     PHP    → PHP 8.2（兼容性最好）"
    echo "│     编译   → 预编译二进制包（免编译，省时间）"
    echo "│     分配器 → ${REC_MALLOC_NAME}"
    echo "│"
    echo "│  ⚙  安装后自动优化数据库配置："
    echo "│     innodb_buffer_pool = ${REC_INNODB_POOL}"
    echo "│     max_connections = ${REC_MAXCONN}"
    echo "│"
    Echo_Yellow "│  💡 全部回车即可使用推荐配置一键安装"
    Echo_Yellow "╰───────────────────────────────────────────╯"
    echo ""
}

Database_Selection()
{
#which MySQL Version do you want to install?
    if [ -z ${DBSelect} ]; then
        DBSelect="4"
        Echo_Yellow "请选择数据库版本（共 11 个选项）："
        echo "1: 安装 ${DB_Info[0]}"
        echo "2: 安装 ${DB_Info[1]}"
        echo "3: 安装 ${DB_Info[2]}"
        echo "4: 安装 ${DB_Info[3]}"
        echo "5: 安装 ${DB_Info[4]}"
        echo "6: 安装 ${DB_Info[5]}"
        echo "7: 安装 ${DB_Info[6]}"
        echo "8: 安装 ${DB_Info[7]}"
        echo "9: 安装 ${DB_Info[8]}"
        echo "10: 安装 ${DB_Info[9]}"
        echo "11: 安装 ${DB_Info[10]}"
        echo "0: 不安装数据库"
        read -p "请输入选项（回车默认 4=MySQL 5.7 推荐）： " DBSelect
    fi

    case "${DBSelect}" in
    1)
        echo "即将安装 ${DB_Info[0]}"
        ;;
    2)
        if [[ "${DB_ARCH}" = "x86_64" || "${DB_ARCH}" = "i686" ]]; then
            if [ -z ${Bin} ]; then
                read -p "使用预编译二进制包？（推荐，回车默认 Y）[Y/n]： " Bin
            fi
            case "${Bin}" in
            [yY][eE][sS]|[yY])
                echo "即将安装 ${DB_Info[1]} （预编译二进制包）"
                Bin="y"
                ;;
            [nN][oO]|[nN])
                echo "即将安装 ${DB_Info[1]} （源码编译）"
                Bin="n"
                ;;
            *)
                Bin="y"
                ;;
            esac
        else
            echo "默认安装 ${DB_Info[1]} （源码编译）"
            Bin="n"
        fi
        ;;
    3)
        if [[ "${DB_ARCH}" = "x86_64" || "${DB_ARCH}" = "i686" ]]; then
            if [ -z ${Bin} ]; then
                read -p "使用预编译二进制包？（推荐，回车默认 Y）[Y/n]： " Bin
            fi
            case "${Bin}" in
            [yY][eE][sS]|[yY])
                echo "即将安装 ${DB_Info[2]} （预编译二进制包）"
                Bin="y"
                ;;
            [nN][oO]|[nN])
                echo "即将安装 ${DB_Info[2]} （源码编译）"
                Bin="n"
                ;;
            *)
                if [ "${CheckMirror}" != "n" ]; then
                    echo "默认安装 ${DB_Info[2]} （预编译二进制包）"
                    Bin="y"
                else
                    echo "默认安装 ${DB_Info[2]} （源码编译）"
                    Bin="y"
                fi
                ;;
            esac
        else
            Bin="n"
        fi
        ;;
    4)
        if [[ "${DB_ARCH}" = "x86_64" || "${DB_ARCH}" = "i686" ]]; then
            if [ -z ${Bin} ]; then
                read -p "使用预编译二进制包？（推荐，回车默认 Y）[Y/n]： " Bin
            fi
            case "${Bin}" in
            [yY][eE][sS]|[yY])
                echo "即将安装 ${DB_Info[3]} （预编译二进制包）"
                Bin="y"
                ;;
            [nN][oO]|[nN])
                echo "即将安装 ${DB_Info[3]} （源码编译）"
                Bin="n"
                ;;
            *)
                if [ "${CheckMirror}" != "n" ]; then
                    echo "默认安装 ${DB_Info[3]} （预编译二进制包）"
                    Bin="y"
                else
                    echo "默认安装 ${DB_Info[3]} （源码编译）"
                    Bin="y"
                fi
                ;;
            esac
        else
            Bin="n"
        fi
        ;;
    5)
        if [[ "${DB_ARCH}" = "x86_64" || "${DB_ARCH}" = "i686" || "${DB_ARCH}" = "aarch64" ]]; then
            if [ -z ${Bin} ]; then
                read -p "使用预编译二进制包？（推荐，回车默认 Y）[Y/n]： " Bin
            fi
            case "${Bin}" in
            [yY][eE][sS]|[yY])
                echo "即将安装 ${DB_Info[4]} （预编译二进制包）"
                Bin="y"
                ;;
            [nN][oO]|[nN])
                echo "即将安装 ${DB_Info[4]} （源码编译）"
                Bin="n"
                ;;
            *)
                if [ "${CheckMirror}" != "n" ]; then
                    echo "默认安装 ${DB_Info[4]} （预编译二进制包）"
                    Bin="y"
                else
                    echo "默认安装 ${DB_Info[4]} （源码编译）"
                    Bin="y"
                fi
                ;;
            esac
        else
            Bin="n"
        fi
        ;;
    6)
        echo "即将安装 ${DB_Info[5]}"
        if [[ "${DB_ARCH}" = "x86_64" || "${DB_ARCH}" = "i686" ]]; then
            if [ -z ${Bin} ]; then
                read -p "使用预编译二进制包？（推荐，回车默认 Y）[Y/n]： " Bin
            fi
            case "${Bin}" in
            [yY][eE][sS]|[yY])
                echo "即将安装 ${DB_Info[5]} （预编译二进制包）"
                Bin="y"
                ;;
            [nN][oO]|[nN])
                echo "即将安装 ${DB_Info[5]} （源码编译）"
                Bin="n"
                ;;
            *)
                if [ "${CheckMirror}" != "n" ]; then
                    echo "默认安装 ${DB_Info[5]} （预编译二进制包）"
                    Bin="y"
                else
                    echo "默认安装 ${DB_Info[5]} （源码编译）"
                    Bin="y"
                fi
                ;;
            esac
        else
            Bin="n"
        fi
        ;;
    7)
        echo "即将安装 ${DB_Info[6]}"
        if [[ "${DB_ARCH}" = "x86_64" || "${DB_ARCH}" = "i686" ]]; then
            if [ -z ${Bin} ]; then
                read -p "使用预编译二进制包？（推荐，回车默认 Y）[Y/n]： " Bin
            fi
            case "${Bin}" in
            [yY][eE][sS]|[yY])
                echo "即将安装 ${DB_Info[6]} （预编译二进制包）"
                Bin="y"
                ;;
            [nN][oO]|[nN])
                echo "即将安装 ${DB_Info[6]} （源码编译）"
                Bin="n"
                ;;
            *)
                if [ "${CheckMirror}" != "n" ]; then
                    echo "默认安装 ${DB_Info[6]} （预编译二进制包）"
                    Bin="y"
                else
                    echo "默认安装 ${DB_Info[6]} （源码编译）"
                    Bin="y"
                fi
                ;;
            esac
        else
            Bin="n"
        fi
        ;;
    8)
        echo "即将安装 ${DB_Info[7]}"
        if [[ "${DB_ARCH}" = "x86_64" || "${DB_ARCH}" = "i686" ]]; then
            if [ -z ${Bin} ]; then
                read -p "使用预编译二进制包？（推荐，回车默认 Y）[Y/n]： " Bin
            fi
            case "${Bin}" in
            [yY][eE][sS]|[yY])
                echo "即将安装 ${DB_Info[7]} （预编译二进制包）"
                Bin="y"
                ;;
            [nN][oO]|[nN])
                echo "即将安装 ${DB_Info[7]} （源码编译）"
                Bin="n"
                ;;
            *)
                if [ "${CheckMirror}" != "n" ]; then
                    echo "默认安装 ${DB_Info[7]} （预编译二进制包）"
                    Bin="y"
                else
                    echo "默认安装 ${DB_Info[7]} （源码编译）"
                    Bin="y"
                fi
                ;;
            esac
        else
            Bin="n"
        fi
        ;;
    9)
        echo "即将安装 ${DB_Info[8]}"
        if [[ "${DB_ARCH}" = "x86_64" ]]; then
            if [ -z ${Bin} ]; then
                read -p "使用预编译二进制包？（推荐，回车默认 Y）[Y/n]： " Bin
            fi
            case "${Bin}" in
            [yY][eE][sS]|[yY])
                echo "即将安装 ${DB_Info[8]} （预编译二进制包）"
                Bin="y"
                ;;
            [nN][oO]|[nN])
                echo "即将安装 ${DB_Info[8]} （源码编译）"
                Bin="n"
                ;;
            *)
                if [ "${CheckMirror}" != "n" ]; then
                    echo "默认安装 ${DB_Info[8]} （预编译二进制包）"
                    Bin="y"
                else
                    echo "默认安装 ${DB_Info[8]} （源码编译）"
                    Bin="y"
                fi
                ;;
            esac
        else
            Bin="n"
        fi
        ;;
    10)
        echo "即将安装 ${DB_Info[9]}"
        if [[ "${DB_ARCH}" = "x86_64" ]]; then
            if [ -z ${Bin} ]; then
                read -p "使用预编译二进制包？（推荐，回车默认 Y）[Y/n]： " Bin
            fi
            case "${Bin}" in
            [yY][eE][sS]|[yY])
                echo "即将安装 ${DB_Info[9]} （预编译二进制包）"
                Bin="y"
                ;;
            [nN][oO]|[nN])
                echo "即将安装 ${DB_Info[9]} （源码编译）"
                Bin="n"
                ;;
            *)
                if [ "${CheckMirror}" != "n" ]; then
                    echo "默认安装 ${DB_Info[9]} （预编译二进制包）"
                    Bin="y"
                else
                    echo "默认安装 ${DB_Info[9]} （源码编译）"
                    Bin="y"
                fi
                ;;
            esac
        else
            Bin="n"
        fi
        ;;
    11)
        echo "即将安装 ${DB_Info[10]}"
        if [[ "${DB_ARCH}" = "x86_64" || "${DB_ARCH}" = "i686" || "${DB_ARCH}" = "aarch64" ]]; then
            if [ -z ${Bin} ]; then
                read -p "使用预编译二进制包？（推荐，回车默认 Y）[Y/n]： " Bin
            fi
            case "${Bin}" in
            [yY][eE][sS]|[yY])
                echo "即将安装 ${DB_Info[10]} （预编译二进制包）"
                Bin="y"
                ;;
            [nN][oO]|[nN])
                echo "即将安装 ${DB_Info[10]} （源码编译）"
                Bin="n"
                ;;
            *)
                if [ "${CheckMirror}" != "n" ]; then
                    echo "默认安装 ${DB_Info[10]} （预编译二进制包）"
                    Bin="y"
                else
                    echo "默认安装 ${DB_Info[10]} （源码编译）"
                    Bin="y"
                fi
                ;;
            esac
        else
            Bin="n"
        fi
        ;;
    0)
        echo "不安装数据库"
        ;;
    *)
        echo "未输入，使用推荐配置 MySQL 5.7"
        DBSelect="4"
        Bin="y"
    esac

    if [ "${Bin}" != "y" ] && [[ "${DBSelect}" =~ ^5|[7-9]|1[0-1]$ ]] && [ $(awk '/MemTotal/ {printf( "%d\n", $2 / 1024 )}' /proc/meminfo) -le 1024 ]; then
        echo "内存不足 1GB，无法安装 MySQL 8.0 或 MariaDB 10.3+"
        exit 1
    fi

    if [[ "${DBSelect}" =~ ^(6|7|8|9|10)$ ]]; then
        MySQL_Bin="/usr/local/mariadb/bin/mysql"
        MySQL_Config="/usr/local/mariadb/bin/mysql_config"
        MySQL_Dir="/usr/local/mariadb"
    elif [[ "${DBSelect}" =~ ^(1|2|3|4|5|11)$ ]]; then
        MySQL_Bin="/usr/local/mysql/bin/mysql"
        MySQL_Config="/usr/local/mysql/bin/mysql_config"
        MySQL_Dir="/usr/local/mysql"
    fi

    if [[ "${DBSelect}" != "0" ]]; then
        #set mysql root password
        if [ -z ${DB_Root_Password} ]; then
            echo "==========================="
            DB_Root_Password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 16)
            Echo_Yellow "数据库 root 密码已自动生成："
            echo ""
            echo "  密码：${DB_Root_Password}"
            echo ""
            echo "${DB_Root_Password}" > /root/.nextlnmp_db_password
            chmod 600 /root/.nextlnmp_db_password
            echo "  密码已保存到：/root/.nextlnmp_db_password"
            echo "  查看密码：nextlnmp password"
            echo "  记住后删除：nextlnmp password --delete"
            echo ""
        fi
        echo "数据库 root 密码：${DB_Root_Password}"

        #do you want to enable or disable the InnoDB Storage Engine?
        echo "==========================="

        if [ -z ${InstallInnodb} ]; then
            InstallInnodb="y"
            Echo_Yellow "是否启用 InnoDB 存储引擎？"
            read -p "推荐启用（回车默认 Y）[Y/n]： " InstallInnodb
        fi

        case "${InstallInnodb}" in
        [yY][eE][sS]|[yY])
            echo "将启用 InnoDB 存储引擎"
            InstallInnodb="y"
            ;;
        [nN][oO]|[nN])
            echo "将禁用 InnoDB 存储引擎"
            InstallInnodb="n"
            ;;
        *)
            echo "未输入，默认启用 InnoDB"
            InstallInnodb="y"
        esac
    fi
}

PHP_Selection()
{
#which PHP Version do you want to install?
    if [ -z ${PHPSelect} ]; then
        echo "==========================="

        PHPSelect="13"
        Echo_Yellow "请选择 PHP 版本："
        echo "1: 安装 ${PHP_Info[0]}"
        echo "2: 安装 ${PHP_Info[1]}"
        echo "3: 安装 ${PHP_Info[2]}"
        echo "4: 安装 ${PHP_Info[3]}"
        echo "5: 安装 ${PHP_Info[4]}"
        echo "6: 安装 ${PHP_Info[5]}"
        echo "7: 安装 ${PHP_Info[6]}"
        echo "8: 安装 ${PHP_Info[7]}"
        echo "9: 安装 ${PHP_Info[8]}"
        echo "10: 安装 ${PHP_Info[9]}"
        echo "11: 安装 ${PHP_Info[10]}"
        echo "12: 安装 ${PHP_Info[11]}"
        echo "13: 安装 ${PHP_Info[12]}"
        echo "14: 安装 ${PHP_Info[13]}"
        echo "15: 安装 ${PHP_Info[14]}"
        read -p "请输入选项（回车默认 13=PHP 8.2 推荐，15=PHP 8.4）： " PHPSelect
    fi

    case "${PHPSelect}" in
    1)
        echo "即将安装 ${PHP_Info[0]}"
        if [[ "${DBSelect}" = 0 ]]; then
            echo "未安装数据库，无法选择 ${PHP_Info[0]}"
            exit 1
        fi
        ;;
    2)
        echo "即将安装 ${PHP_Info[1]}"
        ;;
    3)
        echo "即将安装 ${PHP_Info[2]}"
        ;;
    4)
        echo "即将安装 ${PHP_Info[3]}"
        ;;
    5)
        echo "即将安装 ${PHP_Info[4]}"
        ;;
    6)
        echo "即将安装 ${PHP_Info[5]}"
        ;;
    7)
        echo "即将安装 ${PHP_Info[6]}"
        ;;
    8)
        echo "即将安装 ${PHP_Info[7]}"
        ;;
    9)
        echo "即将安装 ${PHP_Info[8]}"
        ;;
    10)
        echo "即将安装 ${PHP_Info[9]}"
        ;;
    11)
        echo "即将安装 ${PHP_Info[10]}"
        ;;
    12)
        echo "即将安装 ${PHP_Info[11]}"
        ;;
    13)
        echo "即将安装 ${PHP_Info[12]}"
        ;;
    14)
        echo "即将安装 ${PHP_Info[13]}"
        ;;
    15)
        echo "即将安装 ${PHP_Info[14]}"
        ;;
    *)
        echo "未输入，使用推荐配置 PHP 8.2"
        PHPSelect="13"
    esac
}

MemoryAllocator_Selection()
{
#which Memory Allocator do you want to install?
    if [ -z ${SelectMalloc} ]; then
        echo "==========================="

        SelectMalloc="${REC_MALLOC}"
        Echo_Yellow "请选择内存分配器："
        echo "1: 不安装（默认）"
        echo "2: 安装 Jemalloc"
        echo "3: 安装 TCMalloc"
        read -p "请输入选项（回车使用推荐 ${REC_MALLOC}）： " SelectMalloc
    fi

    case "${SelectMalloc}" in
    1)
        echo "不安装内存分配器"
        ;;
    2)
        echo "即将安装 Jemalloc"
        ;;
    3)
        echo "即将安装 TCMalloc"
        ;;
    *)
        echo "未输入，默认不安装内存分配器"
        SelectMalloc="1"
    esac

    if [ "${SelectMalloc}" =  "1" ]; then
        MySQL51MAOpt=''
        MySQLMAOpt=''
        NginxMAOpt=''
    elif [ "${SelectMalloc}" =  "2" ]; then
        MySQL51MAOpt='--with-mysqld-ldflags=-ljemalloc'
        MySQLMAOpt='[mysqld_safe]
malloc-lib=/usr/lib/libjemalloc.so'
        NginxMAOpt="--with-ld-opt='-ljemalloc'"
    elif [ "${SelectMalloc}" =  "3" ]; then
        MySQL51MAOpt='--with-mysqld-ldflags=-ltcmalloc'
        MySQLMAOpt='[mysqld_safe]
malloc-lib=/usr/lib/libtcmalloc.so'
        NginxMAOpt='--with-google_perftools_module'
    fi
}

Dispaly_Selection()
{
    Smart_Recommend
    Database_Selection
    PHP_Selection
    MemoryAllocator_Selection
}

Apache_Selection()
{
    echo "==========================="
    #set Server Administrator Email Address
    if [ -z ${ServerAdmin} ]; then
        ServerAdmin=""
        read -p "请输入管理员邮箱： " ServerAdmin
    fi
    if [ "${ServerAdmin}" == "" ]; then
        echo "未输入，默认使用 webmaster@example.com"
        ServerAdmin="webmaster@example.com"
    else
        echo "==========================="
        echo Server Administrator Email: "${ServerAdmin}"
        echo "==========================="
    fi
    echo "==========================="

#which Apache Version do you want to install?
    if [ -z ${ApacheSelect} ]; then
        ApacheSelect="1"
        Echo_Yellow "请选择 Apache 版本："
        echo "1: 安装 ${Apache_Info[0]}"
        echo "2: 安装 ${Apache_Info[1]}"
        read -p "请输入选项（1 或 2）： " ApacheSelect
    fi

    if [ "${ApacheSelect}" = "1" ]; then
        echo "即将安装 ${Apache_Info[0]}"
    elif [ "${ApacheSelect}" = "2" ]; then
        echo "即将安装 ${Apache_Info[1]}"
    else
        echo "未输入，默认安装 ${Apache_Info[1]}"
        ApacheSelect="2"
    fi
    if [[ "${PHPSelect}" = "1" && "${ApacheSelect}" = "2" ]]; then
        Echo_Red "PHP 5.2.17 与 Apache 2.4 不兼容"
        Echo_Red "已自动切换为 Apache 2.2.31"
        ApacheSelect="1"
    fi
}

Kill_PM()
{
    if ps aux | grep -E "yum|dnf" | grep -qv "grep"; then
        kill -9 $(ps -ef|grep -E "yum|dnf"|grep -v grep|awk '{print $2}')
        if [ -s /var/run/yum.pid ]; then
            rm -f /var/run/yum.pid
        fi
    elif ps aux | grep -E "apt-get|dpkg|apt" | grep -qv "grep"; then
        kill -9 $(ps -ef|grep -E "apt-get|apt|dpkg"|grep -v grep|awk '{print $2}')
        if [[ -s /var/lib/dpkg/lock-frontend || -s /var/lib/dpkg/lock ]]; then
            rm -f /var/lib/dpkg/lock-frontend
            rm -f /var/lib/dpkg/lock
            dpkg --configure -a
        fi
    fi
}

Press_Install()
{
    if [ -z ${nextLNMP_Auto} ]; then
        echo ""
        Echo_Green "按任意键开始安装...按 Ctrl+C 取消"
        OLDCONFIG=`stty -g`
        stty -icanon -echo min 1 time 0
        dd count=1 2>/dev/null
        stty ${OLDCONFIG}
    fi
    . include/version.sh
    Kill_PM
}

Press_Start()
{
    echo ""
    Echo_Green "按任意键开始...按 Ctrl+C 取消"
    OLDCONFIG=`stty -g`
    stty -icanon -echo min 1 time 0
    dd count=1 2>/dev/null
    stty ${OLDCONFIG}
}

Install_LSB()
{
    echo "[+] 正在安装 lsb..."
    if [ "$PM" = "yum" ]; then
        yum -y install redhat-lsb
    elif [ "$PM" = "apt" ]; then
        apt-get update
        apt-get --no-install-recommends install -y lsb-release
    fi
}

Get_Dist_Version()
{
    if command -v lsb_release >/dev/null 2>&1; then
        DISTRO_Version=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO_Version="$DISTRIB_RELEASE"
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_Version="$VERSION_ID"
    fi
    if [[ "${DISTRO}" = "" || "${DISTRO_Version}" = "" ]]; then
        if command -v python2 >/dev/null 2>&1; then
            DISTRO_Version=$(python2 -c 'import platform; print platform.linux_distribution()[1]')
        elif command -v python3 >/dev/null 2>&1; then
            DISTRO_Version=$(python3 -c 'import platform; print(platform.linux_distribution()[1])')
        else
            Install_LSB
            DISTRO_Version=`lsb_release -rs`
        fi
    fi
    printf -v "${DISTRO}_Version" '%s' "${DISTRO_Version}"
}

Get_Dist_Name()
{
    if grep -Eqi "Alibaba" /etc/issue || grep -Eq "Alibaba Cloud Linux" /etc/*-release; then
        DISTRO='Alibaba'
        PM='yum'
    elif grep -Eqi "Aliyun" /etc/issue || grep -Eq "Aliyun Linux" /etc/*-release; then
        DISTRO='Aliyun'
        PM='yum'
    elif grep -Eqi "Amazon Linux" /etc/issue || grep -Eq "Amazon Linux" /etc/*-release; then
        DISTRO='Amazon'
        PM='yum'
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        DISTRO='Fedora'
        PM='yum'
    elif grep -Eqi "Oracle Linux" /etc/issue || grep -Eq "Oracle Linux" /etc/*-release; then
        DISTRO='Oracle'
        PM='yum'
    elif grep -Eqi "rockylinux" /etc/issue || grep -Eq "Rocky Linux" /etc/*-release; then
        DISTRO='Rocky'
        PM='yum'
    elif grep -Eqi "almalinux" /etc/issue || grep -Eq "AlmaLinux" /etc/*-release; then
        DISTRO='Alma'
        PM='yum'
    elif grep -Eqi "openEuler" /etc/issue || grep -Eq "openEuler" /etc/*-release; then
        DISTRO='openEuler'
        PM='yum'
    elif grep -Eqi "Anolis OS" /etc/issue || grep -Eq "Anolis OS" /etc/*-release; then
        DISTRO='Anolis'
        PM='yum'
    elif grep -Eqi "Kylin Linux Advanced Server" /etc/issue || grep -Eq "Kylin Linux Advanced Server" /etc/*-release; then
        DISTRO='Kylin'
        PM='yum'
    elif grep -Eqi "OpenCloudOS" /etc/issue || grep -Eq "OpenCloudOS" /etc/*-release; then
        DISTRO='OpenCloudOS'
        PM='yum'
    elif grep -Eqi "Huawei Cloud EulerOS" /etc/issue || grep -Eq "Huawei Cloud EulerOS" /etc/*-release; then
        DISTRO='HCE'
        PM='yum'
    elif grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        DISTRO='CentOS'
        PM='yum'
        if grep -Eq "CentOS Stream" /etc/*-release; then
            isCentosStream='y'
        fi
    elif grep -Eqi "Red Hat Enterprise Linux" /etc/issue || grep -Eq "Red Hat Enterprise Linux" /etc/*-release; then
        DISTRO='RHEL'
        PM='yum'
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        DISTRO='Ubuntu'
        PM='apt'
    elif grep -Eqi "Raspbian" /etc/issue || grep -Eq "Raspbian" /etc/*-release; then
        DISTRO='Raspbian'
        PM='apt'
    elif grep -Eqi "Deepin" /etc/issue || grep -Eq "Deepin" /etc/*-release; then
        DISTRO='Deepin'
        PM='apt'
    elif grep -Eqi "Mint" /etc/issue || grep -Eq "Mint" /etc/*-release; then
        DISTRO='Mint'
        PM='apt'
    elif grep -Eqi "Kali" /etc/issue || grep -Eq "Kali" /etc/*-release; then
        DISTRO='Kali'
        PM='apt'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        DISTRO='Debian'
        PM='apt'
    elif grep -Eqi "UnionTech OS|UOS" /etc/issue || grep -Eq "UnionTech OS|UOS" /etc/*-release; then
        DISTRO='UOS'
        if command -v apt >/dev/null 2>&1; then
            PM='apt'
        elif command -v yum >/dev/null 2>&1; then
            PM='yum'
        fi
    elif grep -Eqi "Kylin Linux Desktop" /etc/issue || grep -Eq "Kylin Linux Desktop" /etc/*-release; then
        DISTRO='Kylin'
        PM='apt'
    else
        DISTRO='unknow'
    fi
    Get_OS_Bit
}

Get_RHEL_Version()
{
    Get_Dist_Name
    if [ "${DISTRO}" = "RHEL" ]; then
        if grep -Eqi "release 5." /etc/redhat-release; then
            echo "Current Version: RHEL Ver 5"
            RHEL_Ver='5'
        elif grep -Eqi "release 6." /etc/redhat-release; then
            echo "Current Version: RHEL Ver 6"
            RHEL_Ver='6'
        elif grep -Eqi "release 7." /etc/redhat-release; then
            echo "Current Version: RHEL Ver 7"
            RHEL_Ver='7'
        elif grep -Eqi "release 8." /etc/redhat-release; then
            echo "Current Version: RHEL Ver 8"
            RHEL_Ver='8'
        elif grep -Eqi "release 9." /etc/redhat-release; then
            echo "Current Version: RHEL Ver 9"
            RHEL_Ver='9'
        fi
        RHEL_Version="$(cat /etc/redhat-release | sed 's/.*release\ //' | sed 's/\ .*//')"
    fi
}

Get_OS_Bit()
{
    if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
        Is_64bit='y'
        ARCH='x86_64'
        DB_ARCH='x86_64'
    else
        Is_64bit='n'
        ARCH='i386'
        DB_ARCH='i686'
    fi

    if uname -m | grep -Eqi "arm|aarch64"; then
        Is_ARM='y'
        if uname -m | grep -Eqi "armv7|armv6"; then
            ARCH='armhf'
        elif uname -m | grep -Eqi "aarch64"; then
            ARCH='aarch64'
            DB_ARCH='aarch64'
        else
            ARCH='arm'
        fi
    fi
}

Download_Files()
{
    local URL=$1
    local FileName=$2
    local SHA256_FILE="${cur_dir}/src/sha256sums.txt"
    
    # First run: download checksums file
    if [ ! -f "${SHA256_FILE}" ]; then
        echo "正在下载 SHA256 校验文件..."
        wget -q --no-check-certificate -O "${SHA256_FILE}" "${Download_Mirror}/sha256sums.txt"
    fi
    
    if [ -s "${FileName}" ]; then
        echo "${FileName} [已存在]"
    else
        echo "正在下载 ${FileName}..."
        wget -c --progress=bar:force --prefer-family=IPv4 --no-check-certificate ${URL}
        if [ $? -ne 0 ]; then
            echo "❌ 下载失败：${FileName}"
            exit 1
        fi
    fi
    
    # SHA256 verification
    if [ -f "${SHA256_FILE}" ] && [ -s "${FileName}" ]; then
        local actual_sha256=$(sha256sum "${FileName}" | awk "{print \$1}")
        local expected_sha256=$(grep "${FileName}" "${SHA256_FILE}" | awk "{print \$1}" | head -1)
        if [ -n "${expected_sha256}" ]; then
            if [ "${actual_sha256}" != "${expected_sha256}" ]; then
                echo "❌ SHA256 校验失败：${FileName}"
                echo "  期望值：${expected_sha256}"
                echo "  实际值：${actual_sha256}"
                rm -f "${FileName}"
                exit 1
            else
                echo "${FileName} ✓ SHA256 校验通过"
            fi
        else
            echo "⚠️  未找到 ${FileName} 的校验值，跳过校验"
        fi
    fi
}
Tar_Cd()
{
    local FileName=$1
    local DirName=$2
    local extension=${FileName##*.}
    cd ${cur_dir}/src
    [[ -d "${DirName}" ]] && rm -rf ${DirName}
    echo "正在解压 ${FileName}..."
    if [ "$extension" == "gz" ] || [ "$extension" == "tgz" ]; then
        tar zxf "${FileName}"
    elif [ "$extension" == "bz2" ]; then
        tar jxf "${FileName}"
    elif [ "$extension" == "xz" ]; then
        tar Jxf "${FileName}"
    fi
    if [ -n "${DirName}" ]; then
        echo "进入 ${DirName}..."
        cd ${DirName}
    fi
}

Check_nextLNMPConf()
{
    if [ ! -s "${cur_dir}/nextlnmp.conf" ]; then
        Echo_Red "❌ 未找到 nextlnmp.conf 配置文件"
        exit 1
    fi
    if [[ "${Download_Mirror}" = "" || "${MySQL_Data_Dir}" = "" || "${MariaDB_Data_Dir}" = "" || "${Default_Website_Dir}" = "" ]]; then
        Echo_Red "❌ 无法读取 nextlnmp.conf 配置"
        exit 1
    fi
    if [[ "${MySQL_Data_Dir}" = "/" || "${MariaDB_Data_Dir}" = "/" || "${Default_Website_Dir}" = "/" ]]; then
        Echo_Red "❌ 数据库/网站目录不能设为根目录 /"
        exit 1
    fi
}

Print_APP_Ver()
{
    echo "即将安装 ${Stack} stack."
    if [ "${Stack}" != "lamp" ]; then
        echo "${Nginx_Ver}"
    fi

    if [[ "${DBSelect}" =~ ^(1|2|3|4|5|11)$ ]]; then
        echo "${Mysql_Ver}"
    elif [[ "${DBSelect}" =~ ^(6|7|8|9|10)$ ]]; then
        echo "${Mariadb_Ver}"
    elif [ "${DBSelect}" = "0" ]; then
        echo "不安装数据库"
    fi

    echo "${Php_Ver}"

    if [ "${Stack}" != "nextlnmp" ]; then
        echo "${Apache_Ver}"
    fi

    if [ "${SelectMalloc}" = "2" ]; then
        echo "${Jemalloc_Ver}"
    elif [ "${SelectMalloc}" = "3" ]; then
        echo "${TCMalloc_Ver}"
    fi
    echo "InnoDB 引擎：${InstallInnodb}"
    echo "nextlnmp.conf 配置信息："
    echo "下载镜像站：${Download_Mirror}"
    echo "Nginx 额外模块：${Nginx_Modules_Options}"
    echo "PHP 额外模块：${PHP_Modules_Options}"
    if [ "${Enable_PHP_Fileinfo}" = "y" ]; then
        echo "启用 PHP fileinfo"
    fi
    if [ "${Enable_Nginx_Lua}" = "y" ]; then
        echo "启用 Nginx Lua"
    fi
    if [[ "${DBSelect}" =~ ^(1|2|3|4|5|11)$ ]]; then
        echo "数据库目录：${MySQL_Data_Dir}"
    elif [[ "${DBSelect}" =~ ^(6|7|8|9|10)$ ]]; then
        echo "数据库目录：${MariaDB_Data_Dir}"
    elif [ "${DBSelect}" = "0" ]; then
        echo "不安装数据库"
    fi
    echo "网站根目录：${Default_Website_Dir}"
}

# ── 安装后根据内存自动优化 my.cnf ──
Optimize_MyCnf()
{
    local MEM_MB=$(awk '/MemTotal/ {printf("%d", $2 / 1024)}' /proc/meminfo)
    local MYCNF="/etc/my.cnf"

    if [ ! -f "${MYCNF}" ]; then
        echo "my.cnf 不存在，跳过优化"
        return
    fi

    echo ""
    Echo_Yellow "正在根据内存（${MEM_MB}MB）优化数据库配置..."

    # 备份原始配置
    cp ${MYCNF} ${MYCNF}.bak.$(date +%Y%m%d%H%M%S)

    # 根据内存计算参数
    local POOL_SIZE="128M"
    local PFS="OFF"
    local MAX_CONN=50
    local KEY_BUF="8M"
    local TABLE_CACHE=256
    local SORT_BUF="256K"
    local READ_BUF="256K"

    if [ ${MEM_MB} -le 768 ]; then
        POOL_SIZE="64M"; PFS="OFF"; MAX_CONN=30
        KEY_BUF="4M"; TABLE_CACHE=128; SORT_BUF="128K"; READ_BUF="128K"
    elif [ ${MEM_MB} -le 1536 ]; then
        POOL_SIZE="128M"; PFS="OFF"; MAX_CONN=50
        KEY_BUF="8M"; TABLE_CACHE=256; SORT_BUF="256K"; READ_BUF="256K"
    elif [ ${MEM_MB} -le 3072 ]; then
        POOL_SIZE="256M"; PFS="ON"; MAX_CONN=100
        KEY_BUF="16M"; TABLE_CACHE=512; SORT_BUF="512K"; READ_BUF="512K"
    else
        local pool_mb=$((MEM_MB / 4))
        POOL_SIZE="${pool_mb}M"; PFS="ON"; MAX_CONN=200
        KEY_BUF="32M"; TABLE_CACHE=1024; SORT_BUF="1M"; READ_BUF="1M"
    fi

    # 追加优化参数（如果还没有添加过）
    if ! grep -q "# nextLNMP auto optimize" ${MYCNF}; then
        cat >> ${MYCNF} << OPTEOF

# nextLNMP auto optimize (${MEM_MB}MB memory)
[mysqld]
innodb_buffer_pool_size = ${POOL_SIZE}
max_connections = ${MAX_CONN}
performance_schema = ${PFS}
key_buffer_size = ${KEY_BUF}
table_open_cache = ${TABLE_CACHE}
sort_buffer_size = ${SORT_BUF}
read_buffer_size = ${READ_BUF}
read_rnd_buffer_size = ${READ_BUF}
thread_cache_size = 8
innodb_log_buffer_size = 4M
innodb_flush_log_at_trx_commit = 2
innodb_file_per_table = 1
skip-name-resolve
OPTEOF
        echo "  ✓ 数据库配置已优化"
        echo "    innodb_buffer_pool_size = ${POOL_SIZE}"
        echo "    max_connections = ${MAX_CONN}"
        echo "    performance_schema = ${PFS}"
    else
        echo "  已优化过，跳过"
    fi
}

Print_Sys_Info()
{
    echo "nextLNMP Version: ${NEXTLNMP_Ver}"
    eval echo "${DISTRO} \${${DISTRO}_Version}"
    cat /etc/issue
    cat /etc/*-release
    uname -a
    MemTotal=$(awk '/MemTotal/ {printf( "%d\n", $2 / 1024 )}' /proc/meminfo)
    echo "内存：${MemTotal} MB"
    df -h
    Check_Openssl
    Check_WSL
    Check_Docker
    if [ "${CheckMirror}" != "n" ]; then
        Get_Country
        echo "Server Location: ${country}"
    fi
}

StartUp()
{
    init_name=$1
    echo "正在设置 ${init_name} 开机自启..."
    [[ "${isWSL}" = "" ]] && Check_WSL
    [[ "${isDocker}" = "" ]] && Check_Docker
    if [ "${isWSL}" = "n" ] && [ "${isDocker}" = "n" ] && command -v systemctl >/dev/null 2>&1 && [[ -s /etc/systemd/system/${init_name}.service || -s /lib/systemd/system/${init_name}.service || -s /usr/lib/systemd/system/${init_name}.service ]]; then
        systemctl daemon-reload
        systemctl enable ${init_name}.service
    else
        if [ "$PM" = "yum" ]; then
            chkconfig --add ${init_name}
            chkconfig ${init_name} on
        elif [ "$PM" = "apt" ]; then
            update-rc.d -f ${init_name} defaults
        fi
    fi
}

Remove_StartUp()
{
    init_name=$1
    echo "正在移除 ${init_name} 开机自启..."
    [[ "${isWSL}" = "" ]] && Check_WSL
    [[ "${isDocker}" = "" ]] && Check_Docker
    if [ "${isWSL}" = "n" ] && [ "${isDocker}" = "n" ] && command -v systemctl >/dev/null 2>&1 && [[ -s /etc/systemd/system/${init_name}.service || -s /lib/systemd/system/${init_name}.service || -s /usr/lib/systemd/system/${init_name}.service ]]; then
        systemctl disable ${init_name}.service
    else
        if [ "$PM" = "yum" ]; then
            chkconfig ${init_name} off
            chkconfig --del ${init_name}
        elif [ "$PM" = "apt" ]; then
            update-rc.d -f ${init_name} remove
        fi
    fi
}

Get_Country()
{
    if command -v curl >/dev/null 2>&1; then
        country=`curl -sSk --connect-timeout 30 -m 60 http://ip.vpszt.com/country`
        if [ $? -ne 0 ]; then
            country=`curl -sSk --connect-timeout 30 -m 60 https://ip.nextlnmp.com/country`
        fi
    else
        country=`wget --timeout=5 --no-check-certificate -q -O - http://ip.vpszt.com/country`
    fi
}

Check_Mirror()
{
    if ! command -v curl >/dev/null 2>&1; then
        if [ "$PM" = "yum" ]; then
            yum install -y curl
        elif [ "$PM" = "apt" ]; then
            export DEBIAN_FRONTEND=noninteractive
            apt-get update
            apt-get install -y curl
        fi
    fi
    echo "正在检测镜像站..."
    mirror_code=$(curl -o /dev/null -m 10 --connect-timeout 10 -sk -w %{http_code} https://mirror.zhangmei.com/sha256sums.txt)
    if [[ "${mirror_code}" = "200" ]]; then
        echo "✓ 镜像站连接正常"
    else
        echo "❌ 无法连接镜像站（HTTP ${mirror_code}）"
        echo "请检查网络或手动修改 nextlnmp.conf"
        echo "帮助文档：https://nextlnmp.com"
        exit 1
    fi
}
Check_CMPT()
{
    if [[ "${DBSelect}" = "5" && "${Bin}" != "y" ]]; then
        if echo "${Ubuntu_Version}" | grep -Eqi "^1[0-7]\." || echo "${Debian_Version}" | grep -Eqi "^[4-8]" || echo "${Raspbian_Version}" | grep -Eqi "^[4-8]" || echo "${CentOS_Version}" | grep -Eqi "^[4-7]"  || echo "${RHEL_Version}" | grep -Eqi "^[4-7]" || echo "${Fedora_Version}" | grep -Eqi "^2[0-3]"; then
            Echo_Red "MySQL 8.0 需要较新的系统版本"
            exit 1
        fi
    fi
    if [[ "${PHPSelect}" =~ ^1[0-3]$ ]]; then
        if echo "${Ubuntu_Version}" | grep -Eqi "^1[0-7]\." || echo "${Debian_Version}" | grep -Eqi "^[4-8]" || echo "${Raspbian_Version}" | grep -Eqi "^[4-8]" || echo "${CentOS_Version}" | grep -Eqi "^[4-6]"  || echo "${RHEL_Version}" | grep -Eqi "^[4-6]" || echo "${Fedora_Version}" | grep -Eqi "^2[0-3]"; then
            Echo_Red "PHP 7.4 及 8.x 需要较新的系统版本"
            exit 1
        fi
    fi
    if [[ "${PHPSelect}" = "1" ]]; then
        if echo "${Ubuntu_Version}" | grep -Eqi "^19|2[0-7]\." || echo "${Debian_Version}" | grep -Eqi "^1[0-9]" || echo "${Raspbian_Version}" | grep -Eqi "^1[0-9]" || echo "${Deepin_Version}" | grep -Eqi "^2[0-9]" || echo "${UOS_Version}" | grep -Eqi "^2[0-9]" || echo "${Fedora_Version}" | grep -Eqi "^29|3[0-9]"; then
            Echo_Red "PHP 5.2 不支持 Ubuntu 19+、Debian 10+、Deepin 20+ 等较新系统"
            exit 1
        fi
    fi
}

Color_Text()
{
  echo -e " \e[0;$2m$1\e[0m"
}

Echo_Red()
{
  echo $(Color_Text "$1" "31")
}

Echo_Green()
{
  echo $(Color_Text "$1" "32")
}

Echo_Yellow()
{
  echo $(Color_Text "$1" "33")
}

Echo_Blue()
{
  echo $(Color_Text "$1" "34")
}

Get_PHP_Ext_Dir()
{
    Cur_PHP_Version="`/usr/local/php/bin/php-config --version`"
    zend_ext_dir="`/usr/local/php/bin/php-config --extension-dir`/"
}

Check_Stack()
{
    if [[ -s /usr/local/php/sbin/php-fpm && -s /usr/local/php/etc/php-fpm.conf && -s /etc/init.d/php-fpm && -s /usr/local/nginx/sbin/nginx ]]; then
        Get_Stack="nextlnmp"
    elif [[ -s /usr/local/nginx/sbin/nginx && -s /usr/local/apache/bin/httpd && -s /usr/local/apache/conf/httpd.conf && -s /etc/init.d/httpd && ! -s /usr/local/php/sbin/php-fpm ]]; then
        Get_Stack="nextlnmpa"
    elif [[ -s /usr/local/apache/bin/httpd && -s /usr/local/apache/conf/httpd.conf && -s /etc/init.d/httpd && ! -s /usr/local/php/sbin/php-fpm ]]; then
        Get_Stack="lamp"
    else
        Get_Stack="unknow"
    fi
}

Check_DB()
{
    if [[ -s /usr/local/mariadb/bin/mysql && -s /usr/local/mariadb/bin/mysqld_safe && -s /etc/my.cnf ]]; then
        MySQL_Bin="/usr/local/mariadb/bin/mysql"
        MySQL_Config="/usr/local/mariadb/bin/mysql_config"
        MySQL_Dir="/usr/local/mariadb"
        Is_MySQL="n"
        DB_Name="mariadb"
    elif [[ -s /usr/local/mysql/bin/mysql && -s /usr/local/mysql/bin/mysqld_safe && -s /etc/my.cnf ]]; then
        MySQL_Bin="/usr/local/mysql/bin/mysql"
        MySQL_Config="/usr/local/mysql/bin/mysql_config"
        MySQL_Dir="/usr/local/mysql"
        Is_MySQL="y"
        DB_Name="mysql"
    else
        Is_MySQL="None"
        DB_Name="None"
    fi
}

Do_Query()
{
    echo "$1" >/tmp/.mysql.tmp
    Check_DB
    ${MySQL_Bin} --defaults-file=~/.my.cnf </tmp/.mysql.tmp
    return $?
}

Make_TempMycnf()
{
    cat >~/.my.cnf<<EOF
[client]
user=root
password='$1'
EOF
    chmod 600 ~/.my.cnf
}

Verify_DB_Password()
{
    Check_DB
    status=1
    while [ $status -eq 1 ]; do
        read -s -p "请输入当前数据库 root 密码（不会显示）： " DB_Root_Password
        Make_TempMycnf "${DB_Root_Password}"
        Do_Query ""
        status=$?
    done
    echo "✓ 数据库密码验证通过"
}

TempMycnf_Clean()
{
    if [ -s ~/.my.cnf ]; then
        rm -f ~/.my.cnf
    fi
    if [ -s /tmp/.mysql.tmp ]; then
        rm -f /tmp/.mysql.tmp
    fi
}

StartOrStop()
{
    local action=$1
    local service=$2
    [[ "${isWSL}" = "" ]] && Check_WSL
    [[ "${isDocker}" = "" ]] && Check_Docker
    if [ "${isWSL}" = "n" ] && [ "${isDocker}" = "n" ] && command -v systemctl >/dev/null 2>&1 && [[ -s /etc/systemd/system/${service}.service ]]; then
        systemctl ${action} ${service}.service
    else
        /etc/init.d/${service} ${action}
    fi
}

Check_WSL() {
    if [[ "$(< /proc/sys/kernel/osrelease)" == *[Mm]icrosoft* ]]; then
        echo "检测到 WSL 环境"
        isWSL="y"
    else
        isWSL="n"
    fi
}

Check_Docker() {
    if [ -f /.dockerenv ]; then
        echo "检测到 Docker 环境"
        isDocker="y"
    elif [ -f /proc/1/cgroup ] && grep -q docker /proc/1/cgroup; then
        echo "检测到 Docker 环境"
        isDocker="y"
    elif [ -f /proc/self/cgroup ] && grep -q docker /proc/self/cgroup; then
        echo "检测到 Docker 环境"
        isDocker="y"
    else
        isDocker="n"
    fi
}

Check_Openssl()
{
    if ! command -v openssl >/dev/null 2>&1; then
        Echo_Blue "[+] 正在安装 openssl..."
        if [ "${PM}" = "yum" ]; then
            yum install -y openssl
        elif [ "${PM}" = "apt" ]; then
            apt-get update -y
            [[ $? -ne 0 ]] && apt-get update --allow-releaseinfo-change -y
            apt-get install -y openssl
        fi
    fi
    openssl version
    if openssl version | grep -Eqi "OpenSSL 3.*"; then
        isOpenSSL3='y'
    fi
}
