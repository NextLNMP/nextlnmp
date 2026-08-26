

Check_DB

case "${arg1}" in
    start)
        lnmp_start
        ;;
    stop)
        lnmp_stop
        ;;
    restart)
        lnmp_stop
        lnmp_start
        ;;
    reload)
        lnmp_reload
        ;;
    kill)
        lnmp_kill
        ;;
    status)
        lnmp_status
        ;;
    nginx)
        /etc/init.d/nginx ${arg2}
        ;;
    mysql)
        /etc/init.d/mysql ${arg2}
        ;;
    mariadb)
        /etc/init.d/mariadb ${arg2}
        ;;
    php-fpm)
        /etc/init.d/php-fpm ${arg2}
        ;;
    pureftpd)
        /etc/init.d/pureftpd ${arg2}
        ;;
    vhost)
        Function_Vhost ${arg2}
        ;;
    database)
        Verify_DB_Password
        Function_Database ${arg2}
        TempMycnf_Clean
        ;;
    ftp)
        Check_Pureftpd
        Function_Ftp ${arg2}
        ;;
    ssl)
        case "${arg2}" in
            add)
                echo ""
                echo "当前已有站点列表："
                echo "======================================="
                vhost_list=($(ls /usr/local/nginx/conf/vhost/ | grep ".conf$" | sed 's/.conf//g'))
                for i in "${!vhost_list[@]}"; do
                    echo "$((i+1)). ${vhost_list[$i]}"
                done
                echo "======================================="
                Echo_Yellow "请输入数字选择要申请证书的站点（直接回车选第 1 个）："
                read -e ssl_vhost_select
                if [ "${ssl_vhost_select}" == "" ]; then
                    ssl_vhost_select=1
                fi
                domain="${vhost_list[$((ssl_vhost_select-1))]}"
                if [ "${domain}" == "" ]; then
                    Echo_Red "选择无效！"
                    exit 1
                fi
                echo "已选择站点：${domain}"
                moredomain=$(grep "server_name" /usr/local/nginx/conf/vhost/${domain}.conf | head -1 | sed "s/server_name//g" | sed "s/${domain}//g" | sed "s/;//g" | tr -s ' ')
                vhostdir=$(grep "root " /usr/local/nginx/conf/vhost/${domain}.conf | head -1 | awk '{print $2}' | sed 's/;//g')
                if [ "${vhostdir}" == "" ]; then
                    vhostdir="/home/wwwroot/${domain}"
                fi
                echo "绑定域名：${domain} ${moredomain}"
                echo "网站目录：${vhostdir}"
                # 从现有 80 端口配置继承 rewrite/PHP/日志设置，缺省兜底，避免生成 include rewrite/.conf; 这类损坏配置
                rewrite=$(grep -oE 'include rewrite/[^.]+\.conf' /usr/local/nginx/conf/vhost/${domain}.conf | head -1 | sed 's#include rewrite/##;s#\.conf##')
                [ -z "${rewrite}" ] && rewrite="none"
                include_enable_php=$(grep -oE 'include enable-php[^;]*\.conf;' /usr/local/nginx/conf/vhost/${domain}.conf | head -1)
                [ -z "${include_enable_php}" ] && include_enable_php="include enable-php.conf;"
                al=$(grep -E '^\s*access_log' /usr/local/nginx/conf/vhost/${domain}.conf | head -1 | sed 's/^ *//')
                [ -z "${al}" ] && al="access_log off;"
                info="y"
                Add_SSL_Menu
                Add_SSL
                ;;
            *)
                info="n"
                Add_SSL_Menu
                Add_SSL
                ;;
        esac
        ;;
    dnsssl|dns)
        Add_Dns_SSL ${arg2}
        ;;
    onlyssl)
        Add_Dns_SSL_Only ${arg2}
        ;;
    info)
        if [ -f /root/nextlnmp-info.txt ]; then
            cat /root/nextlnmp-info.txt
        else
            echo "安装信息文件不存在，请运行 nextlnmp 安装后查看"
        fi
        ;;
    password)
        if [ "$2" = "--delete" ]; then
            if [ -f /root/.nextlnmp_db_password ]; then
                rm -f /root/.nextlnmp_db_password
                echo "✓ 密码文件已删除"
            else
                echo "密码文件不存在"
            fi
        else
            if [ -f /root/.nextlnmp_db_password ]; then
                echo "数据库 root 密码：$(cat /root/.nextlnmp_db_password)"
                echo ""
                echo "记住后执行 nextlnmp password --delete 删除密码文件"
            else
                echo "密码文件不存在（已删除或未生成）"
                echo "如需重置密码：bash tools/reset_mysql_root_password.sh"
            fi
        fi
        ;;
    *)
        echo "Usage: nextlnmp {start|stop|reload|restart|kill|status}"
        echo "Usage: nextlnmp {nginx|mysql|mariadb|php-fpm|pureftpd} {start|stop|reload|restart|kill|status}"
        echo "Usage: nextlnmp vhost {add|list|del}"
        echo "Usage: nextlnmp database {add|list|edit|del}"
        echo "Usage: nextlnmp ftp {add|list|edit|del|show}"
        echo "Usage: nextlnmp ssl add"
        echo "Usage: nextlnmp {dnsssl|dns} {cx|ali|cf|dp|he|gd|aws}"
        echo "Usage: nextlnmp onlyssl {cx|ali|cf|dp|he|gd|aws}"
        ;;
esac
exit