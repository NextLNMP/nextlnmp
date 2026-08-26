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
    #@ 探测与选择逻辑共用 conf/cli/php-select.sh（addons.sh 走 include/php-select.sh 同源）
    PHP_Multi_Select
    local sfx="${PHP_Select_Ver}"
    if [ "${enable_pathinfo}" == "y" ]; then
        include_enable_php="include enable-php${sfx}-pathinfo.conf;"
        if [ -n "${sfx}" ] && [ ! -s "${MPHP_NGXCONF}/enable-php${sfx}-pathinfo.conf" ]; then
            \cp ${MPHP_NGXCONF}/enable-php-pathinfo.conf ${MPHP_NGXCONF}/enable-php${sfx}-pathinfo.conf
            sed -i "s/php-cgi.sock/php-cgi${sfx}.sock/g" ${MPHP_NGXCONF}/enable-php${sfx}-pathinfo.conf
        fi
    else
        include_enable_php="include enable-php${sfx}.conf;"
    fi
}

Add_VHost()
{
    domain=""
    while :;do
        echo "请输入主域名（例如：nextlnmp.cn）："
        read -e domain || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
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
    read -e input_vhostdir || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
    while [ "${input_vhostdir}" != "" ] && ! Check_VHost_Dir "${input_vhostdir}"; do
        echo "请重新输入网站根目录（直接回车使用默认 /home/wwwroot/${domain}）："
        read -e input_vhostdir || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
    done
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
    mkdir -p "${vhostdir}"
    if [ "${access_log}" == "y" ]; then
        touch /home/wwwlogs/${al_name}.log
    fi
    # 解除可能残留的 chattr 不可变属性
    if [ -f "${vhostdir}/.user.ini" ]; then
        chattr -i "${vhostdir}/.user.ini" 2>/dev/null
        rm -f "${vhostdir}/.user.ini"
    fi
    echo "设置目录权限..."
    chmod -R 755 "${vhostdir}"
    chown -R www:www "${vhostdir}"
    Add_VHost_Config

    cat >"${vhostdir}/.user.ini"<<EOF
open_basedir=${vhostdir}:/tmp/:/proc/
EOF
    chmod 644 "${vhostdir}/.user.ini"
    chattr +i "${vhostdir}/.user.ini"

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
    # 按【真实结果】打印，不按用户当初的 y/n。原来失败也照样吐出一套
    # 不存在的凭据，用户拿去装 WordPress 才发现连不上，完全想不到问题出在建站阶段。
    if [ "${create_database}" == "y" ]; then
        if [ "${Add_DB_Result}" = "ok" ]; then
            echo "数据库名：${database_name}"
            echo "数据库用户：${database_name}"
            echo "数据库密码：${mysql_password}"
        else
            Echo_Red "数据库：创建失败（上面有具体报错），以下凭据【不可用】"
            Echo_Red "  想重试：nextlnmp database add"
        fi
    else
        echo "创建数据库：否"
    fi
    if [ "${create_ftp}" == "y" ]; then
        if [ "${Add_FTP_Result}" = "ok" ]; then
            echo "FTP 用户：${ftp_account_name}"
            echo "FTP 密码：${ftp_account_password}"
        else
            Echo_Red "FTP：创建失败（账号可能已存在），以下凭据【不可用】"
        fi
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
        read domain || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
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
        read domain || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
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
        # 这里有两个坑，都是真机审计翻出来的：
        #  ① 原来插的是 location / { return 301 ... }。可 :80 段里有
        #     include enable-php.conf，那是【正则】location（location ~ \.php），
        #     而 nginx 的正则 location 优先于前缀 location —— 于是所有 .php 请求
        #     压根轮不到这个 301，PHP 站点的绝大多数页面从不跳 HTTPS。
        #     改用 ^~ 前缀：命中后 nginx 直接跳过正则匹配，对 .php 也生效。
        #  ② 原来无条件插入。对同一域名第二次配 SSL 就会插出第二个 location /，
        #     nginx 报 duplicate location 直接是致命错误，reload 静默失败，
        #     等到下次重启才发现全站起不来。所以先查再插。
        # acme-challenge 用更长的 ^~ 前缀单独放行，保证证书续期仍能走明文 HTTP。
        if ! grep -q "return 301 https://\$host\$request_uri;" /usr/local/nginx/conf/vhost/${domain}.conf; then
            sed -i '0,/access_log/!b;//i\        location ^~ /.well-known/acme-challenge/ {\n            allow all;\n        }\n        location ^~ / {\n            return 301 https://$host$request_uri;\n        }\n' /usr/local/nginx/conf/vhost/${domain}.conf
        fi
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

