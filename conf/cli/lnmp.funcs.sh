#@ lnmp 栈专属函数
lnmp_start()
{
    echo "Starting LNMP..."
    /etc/init.d/nginx start
    /etc/init.d/mysql start
    /etc/init.d/php-fpm start
    for mphpfpm in /etc/init.d/php-fpm[578].[0-9]
    do
        if [ -f ${mphpfpm} ]; then
            ${mphpfpm} start
        fi
    done
}

lnmp_stop()
{
    echo "Stoping LNMP..."
    /etc/init.d/nginx stop
    /etc/init.d/mysql stop
    /etc/init.d/php-fpm stop
    for mphpfpm in /etc/init.d/php-fpm[578].[0-9]
    do
        if [ -f ${mphpfpm} ]; then
            ${mphpfpm} stop
        fi
    done
}

lnmp_reload()
{
    echo "Reload LNMP..."
    /etc/init.d/nginx reload
    /etc/init.d/mysql reload
    /etc/init.d/php-fpm reload
    for mphpfpm in /etc/init.d/php-fpm[578].[0-9]
    do
        if [ -f ${mphpfpm} ]; then
            ${mphpfpm} reload
        fi
    done
}

lnmp_kill()
{
    echo "Kill nginx,php-fpm,mysql process..."
    pkill -9 nginx 2>/dev/null
    pkill -9 mysqld 2>/dev/null
    pkill -9 php-fpm 2>/dev/null
    pkill -9 php-cgi 2>/dev/null
    echo "done."
}

lnmp_status()
{
    /etc/init.d/nginx status
    if [ -f $PHPFPMPIDFILE ]; then
        echo "php-fpm is running!"
    else
        echo "php-fpm is stop!"
    fi
    /etc/init.d/mysql status
}

Add_VHost_Config()
{
    if [ ! -f /usr/local/nginx/conf/rewrite/${rewrite}.conf ]; then
        echo "Create Virtual Host Rewrite file......"
        touch /usr/local/nginx/conf/rewrite/${rewrite}.conf
        echo "Create rewrite file successful,You can add rewrite rule into /usr/local/nginx/conf/rewrite/${rewrite}.conf."
    else
        echo "You select the exist rewrite rule:/usr/local/nginx/conf/rewrite/${rewrite}.conf"
    fi

    cat >"/usr/local/nginx/conf/vhost/${domain}.conf"<<EOF
server
    {
        listen 80;
        #listen [::]:80;
        server_name ${domain} ${moredomain};
        index index.html index.htm index.php default.html default.htm default.php;
        root  ${vhostdir};

        include rewrite/${rewrite}.conf;
        #error_page   404   /404.html;

        # Deny access to PHP files in specific directory
        #location ~ /(wp-content|uploads|wp-includes|images)/.*\.php$ { deny all; }

        ${include_enable_php}

        location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$
        {
            expires      30d;
        }

        location ~ .*\.(js|css)?$
        {
            expires      12h;
        }

        location ~ /.well-known {
            allow all;
        }

        location ~ /\.
        {
            deny all;
        }

        ${al}
    }
EOF

    if [ "${enable_ipv6}" == "y" ]; then
        sed -i 's/#listen \[::\]:80;/listen \[::\]:80;/g' /usr/local/nginx/conf/vhost/${domain}.conf
    fi

    echo "Test Nginx configure file......"
    /usr/local/nginx/sbin/nginx -t
    echo "Reload Nginx......"
    /usr/local/nginx/sbin/nginx -s reload
}

Multiple_PHP_Select()
{
    if [[ ! -s /usr/local/php5.2/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php5.2.conf ]] && [[ ! -s /usr/local/php5.3/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php5.3.conf ]] && [[ ! -s /usr/local/php5.4/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php5.4.conf ]] && [[ ! -s /usr/local/php5.5/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php5.5.conf ]] && [[ ! -s /usr/local/php5.6/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php5.6.conf ]] && [[ ! -s /usr/local/php7.0/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php7.0.conf ]] && [[ ! -s /usr/local/php7.1/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php7.1.conf ]] && [[ ! -s /usr/local/php7.2/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php7.2.conf ]] && [[ ! -s /usr/local/php7.3/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php7.3.conf ]] && [[ ! -s /usr/local/php7.4/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php7.4.conf ]] && [[ ! -s /usr/local/php8.0/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php8.0.conf ]] && [[ ! -s /usr/local/php8.1/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php8.1.conf ]] && [[ ! -s /usr/local/php8.2/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php8.2.conf ]] && [[ ! -s /usr/local/php8.3/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php8.3.conf ]] && [[ ! -s /usr/local/php8.4/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php8.4.conf ]]; then
        if [ "${enable_pathinfo}" == "y" ]; then
            include_enable_php="include enable-php-pathinfo.conf;"
        else
            include_enable_php="include enable-php.conf;"
        fi
    else
        echo "Multiple PHP version found, Please select the PHP version."
        Cur_PHP_Version="`/usr/local/php/bin/php-config --version`"
        Echo_Green "1: Default Main PHP ${Cur_PHP_Version}"
        if [[ -s /usr/local/php5.2/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php5.2.conf && -s /etc/init.d/php-fpm5.2 ]]; then
            Echo_Green "2: PHP 5.2 [found]"
        fi
        if [[ -s /usr/local/php5.3/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php5.3.conf && -s /etc/init.d/php-fpm5.3 ]]; then
            Echo_Green "3: PHP 5.3 [found]"
        fi
        if [[ -s /usr/local/php5.4/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php5.4.conf && -s /etc/init.d/php-fpm5.4 ]]; then
            Echo_Green "4: PHP 5.4 [found]"
        fi
        if [[ -s /usr/local/php5.5/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php5.5.conf && -s /etc/init.d/php-fpm5.5 ]]; then
            Echo_Green "5: PHP 5.5 [found]"
        fi
        if [[ -s /usr/local/php5.6/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php5.6.conf && -s /etc/init.d/php-fpm5.6 ]]; then
            Echo_Green "6: PHP 5.6 [found]"
        fi
        if [[ -s /usr/local/php7.0/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php7.0.conf && -s /etc/init.d/php-fpm7.0 ]]; then
            Echo_Green "7: PHP 7.0 [found]"
        fi
        if [[ -s /usr/local/php7.1/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php7.1.conf && -s /etc/init.d/php-fpm7.1 ]]; then
            Echo_Green "8: PHP 7.1 [found]"
        fi
        if [[ -s /usr/local/php7.2/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php7.2.conf && -s /etc/init.d/php-fpm7.2 ]]; then
            Echo_Green "9: PHP 7.2 [found]"
        fi
        if [[ -s /usr/local/php7.3/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php7.3.conf && -s /etc/init.d/php-fpm7.3 ]]; then
            Echo_Green "10: PHP 7.3 [found]"
        fi
        if [[ -s /usr/local/php7.4/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php7.4.conf && -s /etc/init.d/php-fpm7.4 ]]; then
            Echo_Green "11: PHP 7.4 [found]"
        fi
        if [[ -s /usr/local/php8.0/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php8.0.conf && -s /etc/init.d/php-fpm8.0 ]]; then
            Echo_Green "12: PHP 8.0 [found]"
        fi
        if [[ -s /usr/local/php8.1/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php8.1.conf && -s /etc/init.d/php-fpm8.1 ]]; then
            Echo_Green "13: PHP 8.1 [found]"
        fi
        if [[ -s /usr/local/php8.2/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php8.2.conf && -s /etc/init.d/php-fpm8.2 ]]; then
            Echo_Green "14: PHP 8.2 [found]"
        fi
        if [[ -s /usr/local/php8.3/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php8.3.conf && -s /etc/init.d/php-fpm8.3 ]]; then
            Echo_Green "15: PHP 8.3 [found]"
        fi
        if [[ -s /usr/local/php8.4/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php8.4.conf && -s /etc/init.d/php-fpm8.4 ]]; then
            Echo_Green "16: PHP 8.4 [found]"
        fi
        Echo_Yellow "Enter your choice (1-16): "
        read php_select
        case "${php_select}" in
            1)
                echo "Current selection: PHP ${Cur_PHP_Version}"
                if [ "${enable_pathinfo}" == "y" ]; then
                    include_enable_php="include enable-php-pathinfo.conf;"
                else
                    include_enable_php="include enable-php.conf;"
                fi
                ;;
            2)
                echo "Current selection: PHP `/usr/local/php5.2/bin/php-config --version`"
                if [ "${enable_pathinfo}" == "y" ]; then
                    include_enable_php="include enable-php5.2-pathinfo.conf;"
                    if [ ! -s /usr/local/nginx/conf/enable-php5.2-pathinfo.conf ]; then
                        \cp /usr/local/nginx/conf/enable-php-pathinfo.conf /usr/local/nginx/conf/enable-php5.2-pathinfo.conf
                        sed -i 's/php-cgi.sock/php-cgi5.2.sock/g' /usr/local/nginx/conf/enable-php5.2-pathinfo.conf
                    fi
                else
                    include_enable_php="include enable-php5.2.conf;"
                fi
                ;;
            3)
                echo "Current selection: PHP `/usr/local/php5.3/bin/php-config --version`"
                if [ "${enable_pathinfo}" == "y" ]; then
                    include_enable_php="include enable-php5.3-pathinfo.conf;"
                    if [ ! -s /usr/local/nginx/conf/enable-php5.3-pathinfo.conf ]; then
                        \cp /usr/local/nginx/conf/enable-php-pathinfo.conf /usr/local/nginx/conf/enable-php5.3-pathinfo.conf
                        sed -i 's/php-cgi.sock/php-cgi5.3.sock/g' /usr/local/nginx/conf/enable-php5.3-pathinfo.conf
                    fi
                else
                    include_enable_php="include enable-php5.3.conf;"
                fi
                ;;
            4)
                echo "Current selection: PHP `/usr/local/php5.4/bin/php-config --version`"
                if [ "${enable_pathinfo}" == "y" ]; then
                    include_enable_php="include enable-php5.4-pathinfo.conf;"
                    if [ ! -s /usr/local/nginx/conf/enable-php5.4-pathinfo.conf ]; then
                        \cp /usr/local/nginx/conf/enable-php-pathinfo.conf /usr/local/nginx/conf/enable-php5.4-pathinfo.conf
                        sed -i 's/php-cgi.sock/php-cgi5.4.sock/g' /usr/local/nginx/conf/enable-php5.4-pathinfo.conf
                    fi
                else
                    include_enable_php="include enable-php5.4.conf;"
                fi
                ;;
            5)
                echo "Current selection: PHP `/usr/local/php5.5/bin/php-config --version`"
                if [ "${enable_pathinfo}" == "y" ]; then
                    include_enable_php="include enable-php5.5-pathinfo.conf;"
                    if [ ! -s /usr/local/nginx/conf/enable-php5.5-pathinfo.conf ]; then
                        \cp /usr/local/nginx/conf/enable-php-pathinfo.conf /usr/local/nginx/conf/enable-php5.5-pathinfo.conf
                        sed -i 's/php-cgi.sock/php-cgi5.5.sock/g' /usr/local/nginx/conf/enable-php5.5-pathinfo.conf
                    fi
                else
                    include_enable_php="include enable-php5.5.conf;"
                fi
                ;;
            6)
                echo "Current selection: PHP `/usr/local/php5.6/bin/php-config --version`"
                if [ "${enable_pathinfo}" == "y" ]; then
                    include_enable_php="include enable-php5.6-pathinfo.conf;"
                    if [ ! -s /usr/local/nginx/conf/enable-php5.6-pathinfo.conf ]; then
                        \cp /usr/local/nginx/conf/enable-php-pathinfo.conf /usr/local/nginx/conf/enable-php5.6-pathinfo.conf
                        sed -i 's/php-cgi.sock/php-cgi5.6.sock/g' /usr/local/nginx/conf/enable-php5.6-pathinfo.conf
                    fi
                else
                    include_enable_php="include enable-php5.6.conf;"
                fi
                ;;
            7)
                echo "Current selection: PHP `/usr/local/php7.0/bin/php-config --version`"
                if [ "${enable_pathinfo}" == "y" ]; then
                    include_enable_php="include enable-php7.0-pathinfo.conf;"
                    if [ ! -s /usr/local/nginx/conf/enable-php7.0-pathinfo.conf ]; then
                        \cp /usr/local/nginx/conf/enable-php-pathinfo.conf /usr/local/nginx/conf/enable-php7.0-pathinfo.conf
                        sed -i 's/php-cgi.sock/php-cgi7.0.sock/g' /usr/local/nginx/conf/enable-php7.0-pathinfo.conf
                    fi
                else
                    include_enable_php="include enable-php7.0.conf;"
                fi
                ;;
            8)
                echo "Current selection: PHP `/usr/local/php7.1/bin/php-config --version`"
                if [ "${enable_pathinfo}" == "y" ]; then
                    include_enable_php="include enable-php7.1-pathinfo.conf;"
                    if [ ! -s /usr/local/nginx/conf/enable-php7.1-pathinfo.conf ]; then
                        \cp /usr/local/nginx/conf/enable-php-pathinfo.conf /usr/local/nginx/conf/enable-php7.1-pathinfo.conf
                        sed -i 's/php-cgi.sock/php-cgi7.1.sock/g' /usr/local/nginx/conf/enable-php7.1-pathinfo.conf
                    fi
                else
                    include_enable_php="include enable-php7.1.conf;"
                fi
                ;;
            9)
                echo "Current selection: PHP `/usr/local/php7.2/bin/php-config --version`"
                if [ "${enable_pathinfo}" == "y" ]; then
                    include_enable_php="include enable-php7.2-pathinfo.conf;"
                    if [ ! -s /usr/local/nginx/conf/enable-php7.2-pathinfo.conf ]; then
                        \cp /usr/local/nginx/conf/enable-php-pathinfo.conf /usr/local/nginx/conf/enable-php7.2-pathinfo.conf
                        sed -i 's/php-cgi.sock/php-cgi7.2.sock/g' /usr/local/nginx/conf/enable-php7.2-pathinfo.conf
                    fi
                else
                    include_enable_php="include enable-php7.2.conf;"
                fi
                ;;
            10)
                echo "Current selection: PHP `/usr/local/php7.3/bin/php-config --version`"
                if [ "${enable_pathinfo}" == "y" ]; then
                    include_enable_php="include enable-php7.3-pathinfo.conf;"
                    if [ ! -s /usr/local/nginx/conf/enable-php7.3-pathinfo.conf ]; then
                        \cp /usr/local/nginx/conf/enable-php-pathinfo.conf /usr/local/nginx/conf/enable-php7.3-pathinfo.conf
                        sed -i 's/php-cgi.sock/php-cgi7.3.sock/g' /usr/local/nginx/conf/enable-php7.3-pathinfo.conf
                    fi
                else
                    include_enable_php="include enable-php7.3.conf;"
                fi
                ;;
            11)
                echo "Current selection: PHP `/usr/local/php7.4/bin/php-config --version`"
                if [ "${enable_pathinfo}" == "y" ]; then
                    include_enable_php="include enable-php7.4-pathinfo.conf;"
                    if [ ! -s /usr/local/nginx/conf/enable-php7.4-pathinfo.conf ]; then
                        \cp /usr/local/nginx/conf/enable-php-pathinfo.conf /usr/local/nginx/conf/enable-php7.4-pathinfo.conf
                        sed -i 's/php-cgi.sock/php-cgi7.4.sock/g' /usr/local/nginx/conf/enable-php7.4-pathinfo.conf
                    fi
                else
                    include_enable_php="include enable-php7.4.conf;"
                fi
                ;;
            12)
                echo "Current selection: PHP `/usr/local/php8.0/bin/php-config --version`"
                if [ "${enable_pathinfo}" == "y" ]; then
                    include_enable_php="include enable-php8.0-pathinfo.conf;"
                    if [ ! -s /usr/local/nginx/conf/enable-php8.0-pathinfo.conf ]; then
                        \cp /usr/local/nginx/conf/enable-php-pathinfo.conf /usr/local/nginx/conf/enable-php8.0-pathinfo.conf
                        sed -i 's/php-cgi.sock/php-cgi8.0.sock/g' /usr/local/nginx/conf/enable-php8.0-pathinfo.conf
                    fi
                else
                    include_enable_php="include enable-php8.0.conf;"
                fi
                ;;
            13)
                echo "Current selection: PHP `/usr/local/php8.1/bin/php-config --version`"
                if [ "${enable_pathinfo}" == "y" ]; then
                    include_enable_php="include enable-php8.1-pathinfo.conf;"
                    if [ ! -s /usr/local/nginx/conf/enable-php8.1-pathinfo.conf ]; then
                        \cp /usr/local/nginx/conf/enable-php-pathinfo.conf /usr/local/nginx/conf/enable-php8.1-pathinfo.conf
                        sed -i 's/php-cgi.sock/php-cgi8.1.sock/g' /usr/local/nginx/conf/enable-php8.1-pathinfo.conf
                    fi
                else
                    include_enable_php="include enable-php8.1.conf;"
                fi
                ;;
            14)
                echo "Current selection: PHP `/usr/local/php8.2/bin/php-config --version`"
                if [ "${enable_pathinfo}" == "y" ]; then
                    include_enable_php="include enable-php8.2-pathinfo.conf;"
                    if [ ! -s /usr/local/nginx/conf/enable-php8.2-pathinfo.conf ]; then
                        \cp /usr/local/nginx/conf/enable-php-pathinfo.conf /usr/local/nginx/conf/enable-php8.2-pathinfo.conf
                        sed -i 's/php-cgi.sock/php-cgi8.2.sock/g' /usr/local/nginx/conf/enable-php8.2-pathinfo.conf
                    fi
                else
                    include_enable_php="include enable-php8.2.conf;"
                fi
                ;;
            15)
                echo "Current selection: PHP `/usr/local/php8.3/bin/php-config --version`"
                if [ "${enable_pathinfo}" == "y" ]; then
                    include_enable_php="include enable-php8.3-pathinfo.conf;"
                    if [ ! -s /usr/local/nginx/conf/enable-php8.3-pathinfo.conf ]; then
                        \cp /usr/local/nginx/conf/enable-php-pathinfo.conf /usr/local/nginx/conf/enable-php8.3-pathinfo.conf
                        sed -i 's/php-cgi.sock/php-cgi8.3.sock/g' /usr/local/nginx/conf/enable-php8.3-pathinfo.conf
                    fi
                else
                    include_enable_php="include enable-php8.3.conf;"
                fi
                ;;
            16)
                echo "Current selection: PHP `/usr/local/php8.4/bin/php-config --version`"
                if [ "${enable_pathinfo}" == "y" ]; then
                    include_enable_php="include enable-php8.4-pathinfo.conf;"
                    if [ ! -s /usr/local/nginx/conf/enable-php8.4-pathinfo.conf ]; then
                        \cp /usr/local/nginx/conf/enable-php-pathinfo.conf /usr/local/nginx/conf/enable-php8.4-pathinfo.conf
                        sed -i 's/php-cgi.sock/php-cgi8.4.sock/g' /usr/local/nginx/conf/enable-php8.4-pathinfo.conf
                    fi
                else
                    include_enable_php="include enable-php8.4.conf;"
                fi
                ;;
            *)
                echo "Default,Current selection: PHP ${Cur_PHP_Version}"
                php_select="1"
                if [ "${enable_pathinfo}" == "y" ]; then
                    include_enable_php="include enable-php-pathinfo.conf;"
                else
                    include_enable_php="include enable-php.conf;"
                fi
                ;;
        esac
    fi
}

Add_VHost()
{
    domain=""
    while :;do
        echo "请输入主域名（例如：nextlnmp.cn）："
        read -e domain
        if [ "${domain}" != "" ] && [[ "$domain" = "${domain%[[:space:]]*}" ]]; then
            if [ -f "/usr/local/nginx/conf/vhost/${domain}.conf" ]; then
                Echo_Red " ${domain} 已存在，请检查！"
                exit 1
            else
                echo " 主域名：${domain}"
            fi
            break
        else
            Echo_Red "域名不能为空或包含空格，请重新输入！"
        fi
    done

    echo ""
    echo "请输入其他绑定域名，多个用空格分隔（例如：www.nextlnmp.cn，直接回车跳过）："
    read -e moredomain
    if [ "${moredomain}" != "" ]; then
        echo " 绑定域名列表：${domain} ${moredomain}"
    fi

    vhostdir="/home/wwwroot/${domain}"
    echo ""
    echo "请输入网站根目录（直接回车使用默认）："
    echo "默认目录：${vhostdir}"
    read -e input_vhostdir
    if [ "${input_vhostdir}" != "" ]; then
        vhostdir="${input_vhostdir}"
    fi
    echo "网站目录：${vhostdir}"

    echo ""
    echo "请选择伪静态规则（几乎所有建站程序都需要）："
    echo "1. WordPress（推荐，博客/企业站）"
    echo "2. Typecho（轻量博客）"
    echo "3. Discuz X（论坛）"
    echo "4. ThinkPHP"
    echo "5. Laravel"
    echo "6. CodeIgniter"
    echo "7. Yii2"
    echo "8. ZBlog"
    echo "9. 不需要伪静态"
    echo "请输入数字（直接回车默认选 1 WordPress）："
    read -e rewrite_select
    case "${rewrite_select}" in
        2) rewrite="typecho" ;;
        3) rewrite="discuzx" ;;
        4) rewrite="thinkphp" ;;
        5) rewrite="laravel" ;;
        6) rewrite="codeigniter" ;;
        7) rewrite="yii2" ;;
        8) rewrite="zblog" ;;
        9) rewrite="none" ;;
        *) rewrite="wordpress" ;;
    esac
    echo "已选择伪静态规则：${rewrite}"

    # Typecho/ThinkPHP/Laravel/Yii2 需要 pathinfo，自动开启
    if [[ "${rewrite}" == "typecho" || "${rewrite}" == "thinkphp" || "${rewrite}" == "laravel" || "${rewrite}" == "yii2" ]]; then
        enable_pathinfo="y"
        Echo_Green "已自动启用 Pathinfo（${rewrite} 需要此功能）。"
    else
        echo ""
        echo "是否启用 PHP Pathinfo？（Typecho/ThinkPHP/Laravel 需要，WordPress/Discuz 不需要）[y/N] "
        read -e enable_pathinfo
        if [[ "${enable_pathinfo}" == "y" || "${enable_pathinfo}" == "Y" ]]; then
            echo "已启用 Pathinfo。"
            enable_pathinfo="y"
        else
            echo "Pathinfo 已关闭。"
            enable_pathinfo="n"
        fi
    fi

    echo ""
    echo "是否记录访问日志？（会占用磁盘空间，直接回车关闭）[y/N] "
    read -e access_log
    if [[ "${access_log}" == "y" || "${access_log}" == "Y" ]]; then
        al_name="${domain}"
        al="access_log  /home/wwwlogs/${al_name}.log;"
        echo "访问日志：/home/wwwlogs/${al_name}.log"
        access_log="y"
    else
        echo "访问日志已关闭。"
        al="access_log off;"
        access_log="n"
    fi

    echo ""
    echo "是否启用 IPv6？（不了解请直接回车关闭）[y/N] "
    read -e enable_ipv6
    if [[ "${enable_ipv6}" == "y" || "${enable_ipv6}" == "Y" ]]; then
        echo "已启用 IPv6。"
        enable_ipv6="y"
    else
        echo "IPv6 已关闭。"
        enable_ipv6="n"
    fi

    Multiple_PHP_Select

    if [[ -s /usr/local/mysql/bin/mysql || -s /usr/local/mariadb/bin/mysql ]]; then
        echo ""
        echo "是否自动创建数据库和数据库用户？（推荐创建，直接回车默认创建）[Y/n] "
        read -e create_database
        if [[ "${create_database}" == "n" || "${create_database}" == "N" ]]; then
            create_database="n"
        else
            create_database="y"
            Verify_DB_Password
            Add_Database_Menu
        fi
    fi

    if [ -s /usr/local/pureftpd/sbin/pure-ftpd ]; then
        Echo_Yellow "是否创建 FTP 账号？[y/N] "
        read create_ftp

        if [ "${create_ftp}" == "y" ]; then
            Add_Ftp_Menu
        fi
    fi

    echo ""
    echo "是否申请 SSL 证书？（域名已解析完成选 y，未解析选 n，之后可用 nextlnmp ssl add 补申请）[y/N] "
    read -e create_ssl
    if [[ "${create_ssl}" == "y" || "${create_ssl}" == "Y" ]]; then
        create_ssl="y"
        Add_SSL_Menu
    else
        create_ssl="n"
    fi

    echo ""
    echo "按任意键开始创建虚拟主机..."
    OLDCONFIG=`stty -g`
    stty -icanon -echo min 1 time 0
    dd count=1 2>/dev/null
    stty ${OLDCONFIG}

    echo "创建网站目录..."
    mkdir -p ${vhostdir}
    if [ "${access_log}" == "y" ]; then
        touch /home/wwwlogs/${al_name}.log
    fi
    # 解除可能残留的 chattr 不可变属性
    if [ -f "${vhostdir}/.user.ini" ]; then
        chattr -i "${vhostdir}/.user.ini" 2>/dev/null
        rm -f "${vhostdir}/.user.ini"
    fi
    echo "设置目录权限..."
    chmod -R 755 ${vhostdir}
    chown -R www:www ${vhostdir}
    Add_VHost_Config

    cat >${vhostdir}/.user.ini<<EOF
open_basedir=${vhostdir}:/tmp/:/proc/
EOF
    chmod 644 ${vhostdir}/.user.ini
    chattr +i ${vhostdir}/.user.ini

    # 兼容 Binary 安装的多版本 php-fpm
    for phpfpm in /etc/init.d/php-fpm /etc/init.d/php-fpm[578].[0-9]; do
        [ -f "$phpfpm" ] && $phpfpm reload
    done

    if [ "${create_database}" == "y" ]; then
        Add_Database
    fi

    if [ "${create_ftp}" == "y" ]; then
        Add_Ftp
    fi

    if [ "${create_ssl}" == "y" ]; then
        Add_SSL
    fi

    Echo_Green "================================================"
    echo "虚拟主机信息："
    echo "域名：${domain}"
    echo "网站目录：${vhostdir}"
    echo "伪静态：${rewrite}"
    if [ "${access_log}" == "n" ]; then
        echo "访问日志：关闭"
    else
        echo "访问日志：/home/wwwlogs/${al_name}.log"
    fi
    if [ "${create_database}" == "y" ]; then
        echo "数据库名：${database_name}"
        echo "数据库用户：${database_name}"
        echo "数据库密码：${mysql_password}"
    else
        echo "创建数据库：否"
    fi
    if [ "${create_ftp}" == "y" ]; then
        echo "FTP 用户：${ftp_account_name}"
        echo "FTP 密码：${ftp_account_password}"
    fi
    if [ "${create_ssl}" == "y" ]; then
        echo "SSL 证书：已申请"
        if [ "${ssl_choice}" == "2" ]; then
            echo "  => Let's Encrypt"
        elif [ "${ssl_choice}" == "3" ]; then
            echo "  => BuyPass"
        elif [ "${ssl_choice}" == "4" ]; then
            echo "  => ZeroSSL"
        elif [ "${ssl_choice}" == "1" ]; then
            echo "  => 自有证书"
        fi
    fi
    if [ "${enable_ipv6}" == "y" ]; then
        echo "IPv6：已启用"
    fi
    if [ "${enable_pathinfo}" == "y" ]; then
        echo "Pathinfo：已启用"
    fi
    Echo_Green "================================================"
    echo ""
    echo "💡 部署网站程序提示："
    echo "   cd ${vhostdir}"
    echo "   chattr -i .user.ini        # 先解锁"
    echo "   （上传/解压网站文件...）"
    echo "   chown -R www:www .         # 设置权限"
    echo "   chattr +i .user.ini        # 再锁回"
}

Del_VHost()
{
    echo "======================================="
    echo "当前虚拟主机："
    List_VHost
    echo "======================================="
    domain=""
    while :;do
        Echo_Yellow "请输入要删除的域名："
        read domain
        if [ "${domain}" == "" ]; then
            Echo_Red "域名不能为空！"
        else
            break
        fi
    done
    if [ ! -f "/usr/local/nginx/conf/vhost/${domain}.conf" ]; then
        Echo_Red "${domain} 不存在！"
        exit 1
    else
        vhostdir=$(grep -m1 'root ' /usr/local/nginx/conf/vhost/${domain}.conf | awk '{print $2}' | sed 's/;//g')
        if [ -f "${vhostdir}/.user.ini" ]; then
            chattr -i "${vhostdir}/.user.ini"
            rm -f "${vhostdir}/.user.ini"
        fi
        rm -f /usr/local/nginx/conf/vhost/${domain}.conf
        echo "Reload Nginx..."
        /usr/local/nginx/sbin/nginx -s reload
        echo "========================================================"
        echo "✓ 虚拟主机 ${domain} 已删除"
        echo "  网站文件未删除（安全起见），如需删除请手动执行："
        echo "  rm -rf ${vhostdir}"
        echo "========================================================"
    fi
}

Add_SSL_Info_Menu()
{
    domain=""
    while :;do
        Echo_Yellow "Please enter domain(example: www.nextlnmp.com): "
        read domain
        if [ "${domain}" != "" ] && [[ "$domain" = "${domain%[[:space:]]*}" ]]; then
            echo " Your domain: ${domain}"
            break
        else
            Echo_Red "Domain name can't be empty or contain spaces!"
        fi
    done

    Echo_Yellow "Enter more domain name(example: nextlnmp.com sub.nextlnmp.com): "
    read moredomain
    if [ "${moredomain}" != "" ]; then
        echo " domain list: ${moredomain}"
    fi

    Echo_Yellow "Please enter the directory for the domain: $domain"
    echo
    echo "Default directory: /home/wwwroot/${domain}: "
    read vhostdir
    if [ "${vhostdir}" == "" ]; then
        vhostdir="/home/wwwroot/${domain}"
    fi
    echo "Virtual Host Directory: ${vhostdir}"

    Echo_Yellow "Allow Rewrite rule? (y/n) "
    read allow_rewrite
    if [[ "${allow_rewrite}" == "n" || "${allow_rewrite}" == "" ]]; then
        rewrite="none"
    elif [ "${allow_rewrite}" == "y" ]; then
        rewrite="other"
        echo "Please enter the rewrite of programme, "
        echo "wordpress,discuzx,typecho,thinkphp,laravel,codeigniter,yii2,zblog rewrite was exist."
        Echo_Yellow "(Default rewrite: other): "
        read rewrite
        if [ "${rewrite}" == "" ]; then
            rewrite="other"
        fi
    fi
    echo "You choose rewrite: ${rewrite}"

    Echo_Yellow "Allow access log? (y/n) "
    read access_log
    if [[ "${access_log}" == "n" || "${access_log}" == "" ]]; then
        echo "Disable access log."
        al="access_log off;"
    else
        Echo_Yellow "Enter access log filename(Default:${domain}.log): "
        read al_name
        if [ "${al_name}" == "" ]; then
            al_name="${domain}"
        fi
        al="access_log  /home/wwwlogs/${al_name}.log;"
        echo "You access log filename: ${al_name}.log"
    fi

    Echo_Yellow "Enable PHP Pathinfo? (y/n) "
    read enable_pathinfo
    if [[ "${enable_pathinfo}" == "n" || "${enable_pathinfo}" == "" ]]; then
        echo "Disable pathinfo."
    elif [ "${allow_rewrite}" == "y" ]; then
        echo "Enable pathinfo."
        enable_pathinfo="y"
    fi

    Echo_Yellow "Enable IPv6? (y/n) "
    read enable_ipv6
    if [[ "${enable_ipv6}" == "n" || "${enable_ipv6}" == "" ]]; then
        echo "Disabled IPv6 Support in current Virtualhost."
        enable_ipv6="n"
    else
        echo "Enabled IPv6 Support in current Virtualhost."
        enable_ipv6="y"
    fi

    Multiple_PHP_Select
}

Create_SSL_Config()
{
    if [ ! -s /usr/local/nginx/conf/ssl/dhparam.pem ]; then
        echo "Create dhparam.pem..."
        mkdir -p /usr/local/nginx/conf/ssl/
        openssl dhparam -out /usr/local/nginx/conf/ssl/dhparam.pem 2048
    fi

    cat >>"/usr/local/nginx/conf/vhost/${domain}.conf"<<EOF

server
    {
        listen 443 ssl;
        http2 on;
        #listen [::]:443 ssl;
        ##listen [::]:443 ssl;
        server_name ${domain} ${moredomain};
        index index.html index.htm index.php default.html default.htm default.php;
        root  ${vhostdir};

        ssl_certificate ${ssl_certificate};
        ssl_certificate_key ${ssl_certificate_key};
        ssl_session_timeout 5m;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers "TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5";
        ssl_session_cache builtin:1000 shared:SSL:10m;
        # openssl dhparam -out /usr/local/nginx/conf/ssl/dhparam.pem 2048
        ssl_dhparam /usr/local/nginx/conf/ssl/dhparam.pem;

        include rewrite/${rewrite}.conf;
        #error_page   404   /404.html;

        # Deny access to PHP files in specific directory
        #location ~ /(wp-content|uploads|wp-includes|images)/.*\.php$ { deny all; }

        ${include_enable_php}

        location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$
        {
            expires      30d;
        }

        location ~ .*\.(js|css)?$
        {
            expires      12h;
        }

        location ~ /.well-known {
            allow all;
        }

        location ~ /\.
        {
            deny all;
        }

        ${al}
    }
EOF

    if [ "${using_301}" == "y" ]; then
        sed -i '0,/access_log/!b;//i\        location / {\n            return 301 https://$host$request_uri;\n        }\n' /usr/local/nginx/conf/vhost/${domain}.conf
        sed -i "0,/include rewrite\/${rewrite}.conf;/s//#include rewrite\/${rewrite}.conf;/" /usr/local/nginx/conf/vhost/${domain}.conf
    fi

    if [ "${enable_ipv6}" == "y" ]; then
        sed -i 's/#listen \[::\]:443 ssl;/listen \[::\]:443 ssl;/g' /usr/local/nginx/conf/vhost/${domain}.conf
    fi

    echo "Test Nginx configure file......"
    /usr/local/nginx/sbin/nginx -t
    echo "Reload Nginx......"
    /usr/local/nginx/sbin/nginx -s reload
}

