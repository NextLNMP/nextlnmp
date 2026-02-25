#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

if [ $(id -u) != "0" ]; then
    echo "错误：请使用 root 用户运行此脚本"
    exit 1
fi

cur_dir=$(pwd)
. ${cur_dir}/nextlnmp.conf
. ${cur_dir}/include/main.sh

# 从 nextlnmp.sh 读取版本号
NEXTLNMP_Ver=$(grep "^NEXTLNMP_Ver=" ${cur_dir}/nextlnmp.sh 2>/dev/null | cut -d"'" -f2)
[ -z "$NEXTLNMP_Ver" ] && NEXTLNMP_Ver="unknown"

Get_Dist_Name

# 中英文混排对齐函数（中文占2列，ASCII占1列，兼容任何locale）
pad_line() {
    local content="$1"
    local total=58
    local total_bytes=$(printf '%s' "$content" | wc -c)
    local ascii_bytes=$(printf '%s' "$content" | LC_ALL=C tr -d '[\200-\377]' | wc -c)
    local non_ascii_bytes=$((total_bytes - ascii_bytes))
    local display_width=$((ascii_bytes + non_ascii_bytes * 2 / 3))
    local pad=$((total - display_width))
    [ $pad -lt 1 ] && pad=1
    printf "|%s%${pad}s|\n" "$content" ""
}

clear
echo "+----------------------------------------------------------+"
pad_line "  NextLNMP v${NEXTLNMP_Ver} 卸载程序"
pad_line "  官网：https://nextlnmp.cn"
echo "+----------------------------------------------------------+"
echo ""
echo "请选择操作："
echo "  1. 卸载 NextLNMP（保留网站数据和数据库备份）"
echo "  2. 恢复出厂（删除所有数据，彻底清空）"
echo ""
read -p "请输入选项 [1/2]：" action

case "$action" in
1)
    echo ""
    Echo_Yellow "即将卸载 NextLNMP，以下目录将被删除："
    echo "  /usr/local/nginx"
    echo "  /usr/local/php"
    echo "  /usr/local/mysql（数据库将备份到 /root/）"
    echo "  /etc/init.d/nginx、php-fpm"
    echo "  /bin/nextlnmp"
    echo ""
    read -p "确认卸载？[y/N]：" confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && echo "已取消" && exit 0

    echo "正在停止服务..."
    for svc in nginx mysql mysqld mariadb; do
        [ -f /etc/init.d/$svc ] && /etc/init.d/$svc stop 2>/dev/null
    done
    for phpfpm in /etc/init.d/php-fpm /etc/init.d/php-fpm[5,7,8].[0-9]; do
        [ -f "$phpfpm" ] && $phpfpm stop 2>/dev/null
    done
    pkill -f nginx 2>/dev/null
    pkill -f php-fpm 2>/dev/null
    pkill -f mysqld 2>/dev/null

    if [ -n "${MySQL_Data_Dir}" ] && [ -d "${MySQL_Data_Dir}" ]; then
        backup_dir="/root/databases_backup_$(date +%Y%m%d%H%M%S)"
        echo "备份数据库到 ${backup_dir}..."
        mv ${MySQL_Data_Dir} ${backup_dir}
    fi

    if [ -s /usr/local/acme.sh/acme.sh ]; then
        /usr/local/acme.sh/acme.sh --uninstall 2>/dev/null
        rm -rf /usr/local/acme.sh
    fi

    echo "删除 NextLNMP 文件..."
    rm -rf /usr/local/nginx /usr/local/php /usr/local/mysql /usr/local/mariadb /usr/local/zend
    rm -f /etc/my.cnf /etc/init.d/nginx /etc/init.d/mysql /etc/init.d/mysqld /etc/init.d/mariadb
    for phpfpm in /etc/init.d/php-fpm /etc/init.d/php-fpm[5,7,8].[0-9]; do
        rm -f "$phpfpm" 2>/dev/null
    done
    rm -f /bin/nextlnmp /usr/bin/nextlnmp
    rm -rf /root/nextlnmp

    Echo_Green "NextLNMP 卸载完成！网站文件和数据库备份保留在 /home/wwwroot 和 /root/"
    ;;
2)
    echo ""
    Echo_Yellow "⚠️  警告：恢复出厂将删除所有数据，包括网站文件和数据库，不可恢复！"
    echo ""
    read -p "请输入 YES 确认彻底清空：" confirm
    [[ "$confirm" != "YES" ]] && echo "已取消" && exit 0

    echo "正在停止服务..."
    for svc in nginx mysql mysqld mariadb; do
        [ -f /etc/init.d/$svc ] && /etc/init.d/$svc stop 2>/dev/null
    done
    for phpfpm in /etc/init.d/php-fpm /etc/init.d/php-fpm[5,7,8].[0-9]; do
        [ -f "$phpfpm" ] && $phpfpm stop 2>/dev/null
    done
    pkill -f nginx 2>/dev/null
    pkill -f php-fpm 2>/dev/null
    pkill -f mysqld 2>/dev/null

    if [ -s /usr/local/acme.sh/acme.sh ]; then
        /usr/local/acme.sh/acme.sh --uninstall 2>/dev/null
        rm -rf /usr/local/acme.sh
    fi

    echo "删除所有文件..."
    rm -rf /usr/local/nginx /usr/local/php /usr/local/mysql /usr/local/mariadb /usr/local/zend
    rm -rf /home/wwwroot
    rm -f /etc/my.cnf /etc/init.d/nginx /etc/init.d/mysql /etc/init.d/mysqld /etc/init.d/mariadb
    for phpfpm in /etc/init.d/php-fpm /etc/init.d/php-fpm[5,7,8].[0-9]; do
        rm -f "$phpfpm" 2>/dev/null
    done
    rm -f /bin/nextlnmp /usr/bin/nextlnmp
    rm -f /root/nextlnmp-info.txt
    rm -rf /root/nextlnmp

    apt-get remove -y nginx mysql-server mysql-client php* 2>/dev/null
    apt-get autoremove -y 2>/dev/null
    apt-get autoclean 2>/dev/null
    Echo_Green "恢复出厂完成，服务器已恢复至初始状态。"
    ;;
*)
    echo "无效选项，已退出"
    exit 1
    ;;
esac
