#@ lnmpa 栈专属函数
lnmpa_start()
{
    echo "Starting LNMPA..."
    /etc/init.d/nginx start
    /etc/init.d/mysql start
    /etc/init.d/httpd start
}

lnmpa_stop()
{
    echo "Stoping LNMPA..."
    /etc/init.d/nginx stop
    /etc/init.d/mysql stop
    /etc/init.d/httpd stop
}

lnmpa_reload()
{
    echo "Reload LNMPA..."
    /etc/init.d/nginx reload
    /etc/init.d/mysql reload
    /etc/init.d/httpd graceful
}

lnmpa_kill()
{
    echo "Kill nginx,apache,mysql process..."
    killall nginx
    killall httpd
    killall mysqld
    echo "done."
}

lnmpa_status()
{
    /etc/init.d/nginx status
    /etc/init.d/mysql status
    /etc/init.d/httpd status
}

Add_VHost_Config()
{
    cat >"/usr/local/nginx/conf/vhost/${domain}.conf"<<EOF
server
    {
        listen 80;
        #listen [::]:80;
        server_name ${domain} ${moredomain};
        index index.html index.htm index.php default.html default.htm default.php;
        root  ${vhostdir};

        #error_page   404   /404.html;

        # Deny access to PHP files in specific directory
        #location ~ /(wp-content|uploads|wp-includes|images)/.*\.php$ { deny all; }

        include proxy-pass-php.conf;

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

    cat >"/usr/local/apache/conf/vhost/${domain}.conf"<<EOF
<VirtualHost *:88>
ServerAdmin ${email}
php_admin_value open_basedir "${vhostdir}:/tmp/:/var/tmp/:/proc/"
DocumentRoot "${vhostdir}"
ServerName ${domain}
ErrorLog "/home/wwwlogs/${al_name}-error_log"
CustomLog "/home/wwwlogs/${al_name}-access_log" combined
<Directory "${vhostdir}">
    SetOutputFilter DEFLATE
    Options FollowSymLinks
    AllowOverride All
    Order allow,deny
    Allow from all
    DirectoryIndex index.html index.php
</Directory>
</VirtualHost>
EOF

    if [ "${access_log}" != 'y' ]; then
        sed -i 's/^ErrorLog/#ErrorLog/g' /usr/local/apache/conf/vhost/${domain}.conf
        sed -i 's/^CustomLog/#CustomLog/g' /usr/local/apache/conf/vhost/${domain}.conf
    fi

    if [ "${moredomain}" != "" ]; then
        sed -i "/ServerName/a\
    ServerAlias ${moredomain}" /usr/local/apache/conf/vhost/${domain}.conf
    fi

    if [ "${enable_ipv6}" == "y" ]; then
        sed -i 's/#listen \[::\]:80;/listen \[::\]:80;/g' /usr/local/nginx/conf/vhost/${domain}.conf
    fi

    echo "Test Nginx configure file......"
    /usr/local/nginx/sbin/nginx -t
    echo ""
    echo "Reload Nginx......"
    /usr/local/nginx/sbin/nginx -s reload
        echo "Reload Apache..."
        /etc/init.d/httpd reload
    echo "Test Apache configure file..."
    /etc/init.d/httpd configtest
    echo "Restart Apache..."
    /etc/init.d/httpd graceful
}

Add_VHost()
{
    domain=""
    while :;do
        Echo_Yellow "Please enter domain(example: www.nextlnmp.com): "
        read domain || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
        if [ "${domain}" != "" ] && [[ "$domain" = "${domain%[[:space:]]*}" ]]; then
            if [[ -f "/usr/local/nginx/conf/vhost/${domain}.conf" || -f "/usr/local/apache/conf/vhost/${domain}.conf" ]]; then
                Echo_Red " ${domain} is exist,please check!"
                exit 1
            else
                echo " Your domain: ${domain}"
            fi
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

    vhostdir="/home/wwwroot/${domain}"
    echo "Please enter the directory for the domain: $domain"
    Echo_Yellow "Default directory: /home/wwwroot/${domain}: "
    read vhostdir
    if [ "${vhostdir}" == "" ]; then
        vhostdir="/home/wwwroot/${domain}"
    fi
    echo "Virtual Host Directory: ${vhostdir}"

    Echo_Yellow "Allow access log? (y/n) "
    read access_log
    if [[ "${access_log}" == "n" || "${access_log}" == "" ]]; then
        echo "Disable access log."
        al="access_log off;"
        al_name="${domain}"
    else
        Echo_Yellow "Enter access log filename(Default:${domain}.log): "
        read al_name
        if [ "${al_name}" == "" ]; then
            al_name="${domain}"
        fi
        al="access_log  /home/wwwlogs/${al_name}.log;"
        echo "You access log filename: ${al_name}.log"
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

    email=""
    Echo_Yellow "Please enter Administrator Email Address: "
    read email
    if [ "${email}" == "" ]; then
        echo "Administrator Email Address will set to webmaster@example.com!"
        email='webmaster@example.com'
    else
        echo "Server Administrator Email:${email}"
    fi

    if [[ -s /usr/local/mysql/bin/mysql || -s /usr/local/mariadb/bin/mysql ]]; then
        Echo_Yellow "Create database and MySQL user with same name (y/n) "
        read create_database

        if [ "${create_database}" == "y" ]; then
            Verify_DB_Password
            Add_Database_Menu
        fi
    fi

    if [ -f /usr/local/pureftpd/sbin/pure-ftpd ]; then
        Echo_Yellow "Create ftp account (y/n) "
        read create_ftp

        if [ "${create_ftp}" == "y" ]; then
            Add_Ftp_Menu
        fi
    fi

    Echo_Yellow "Add SSL Certificate (y/n) "
    read create_ssl
    if [ "${create_ssl}" == "y" ]; then
        Add_SSL_Menu
    fi

    echo ""
    echo "Press any key to start create virtul host..."
    OLDCONFIG=`stty -g`
    stty -icanon -echo min 1 time 0
    dd count=1 2>/dev/null
    stty ${OLDCONFIG}

    echo "Create Virtul Host directory......"
    mkdir -p ${vhostdir}
    if [ "${access_log}" == "y" ]; then
        touch /home/wwwlogs/${al_name}.log
        touch /home/wwwlogs/${al_name}-access_log
    fi
    echo "set permissions of Virtual Host directory......"
    chmod -R 755 ${vhostdir}
    chown -R www:www ${vhostdir}

    Add_VHost_Config

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
    echo "Virtualhost infomation:"
    echo "Your domain: ${domain}"
    echo "Home Directory: ${vhostdir}"
    if [ "${access_log}" == "n" ]; then
        echo "Enable log: no"
    else
        echo "Enable log: yes"
    fi
    if [ "${create_database}" == "y" ]; then
        echo "Database username: ${database_name}"
        echo "Database userpassword: ${mysql_password}"
        echo "Database Name: ${database_name}"
    else
        echo "Create database: no"
    fi
    if [ "${create_ftp}" == "y" ]; then
        echo "FTP account name: ${ftp_account_name}"
        echo "FTP account password: ${ftp_account_password}"
    else
        echo "Create ftp account: no"
    fi
    if [ "${create_ssl}" == "y" ]; then
        echo "Enable SSL: yes"
        if [ "${ssl_choice}" == "1" ]; then
            echo "  =>Certificate file"
        elif [ "${ssl_choice}" == "2" ]; then
            echo "  =>Let's Encrypt"
        elif [ "${ssl_choice}" == "3" ]; then
            echo "  =>BuyPass"
        elif [ "${ssl_choice}" == "4" ]; then
            echo "  =>ZeroSSL"
        fi
    fi
    if [ "${enable_ipv6}" == "y" ]; then
        echo "IPv6 Support: Enabled"
    else
        echo "IPv6 Support: Disabled"
    fi
    Echo_Green "================================================"
}

Del_VHost()
{
    echo "======================================="
    echo "Current Virtualhost:"
    List_VHost
    echo "======================================="
    domain=""
    while :;do
        Echo_Yellow "Please enter domain you want to delete: "
        read domain || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
        if [ "${domain}" == "" ]; then
            Echo_Red "Domain name can't be empty."
        else
            break
        fi
    done
    if [ ! -f "/usr/local/nginx/conf/vhost/${domain}.conf" ] || [ ! -f "/usr/local/apache/conf/vhost/${domain}.conf" ]; then
        echo "=========================================="
        echo "Domain: ${domain} was not exist!"
        echo "=========================================="
        exit 1
    else
        rm -f /usr/local/nginx/conf/vhost/${domain}.conf
        rm -f /usr/local/apache/conf/vhost/${domain}.conf
        echo "Reload Nginx..."
        /usr/local/nginx/sbin/nginx -s reload
        echo "Reload Apache..."
        /etc/init.d/httpd reload
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
    echo " domain list: ${domain} ${moredomain}"

    Echo_Yellow "Please enter the directory for the domain: $domain"
    echo
    Echo_Yellow "Default directory: /home/wwwroot/${domain}: "
    read vhostdir
    if [ "${vhostdir}" == "" ]; then
        vhostdir="/home/wwwroot/${domain}"
    fi
    echo "Virtual Host Directory: ${vhostdir}"

    Echo_Yellow "Allow access log? (y/n) "
    read access_log
    if [[ "${access_log}" == "n" || "${access_log}" == "" ]]; then
        echo "Disable access log."
        al="access_log off;"
        al_name="${domain}"
    else
        Echo_Yellow "Enter access log filename(Default:${domain}.log): "
        read al_name
        if [ "${al_name}" == "" ]; then
            al_name="${domain}"
        fi
        al="access_log  /home/wwwlogs/${al_name}.log;"
        echo "You access log filename: ${al_name}.log"
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

    email=""
    Echo_Yellow "Please enter Administrator Email Address: "
    read email
    if [ "${email}" == "" ]; then
        echo "Administrator Email Address will set to webmaster@example.com!"
        email='webmaster@example.com'
    else
        echo "Server Administrator Email:${email}"
    fi
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
        listen 443 ssl http2;
        #listen [::]:443 ssl http2;
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

        #error_page   404   /404.html;

        # Deny access to PHP files in specific directory
        #location ~ /(wp-content|uploads|wp-includes|images)/.*\.php$ { deny all; }

        include proxy-pass-php.conf;

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
        sed -i '0,/include proxy-pass-php.conf;/s/include proxy-pass-php.conf;/#include proxy-pass-php.conf;/' /usr/local/nginx/conf/vhost/${domain}.conf
    fi

    if [ "${enable_ipv6}" == "y" ]; then
        sed -i 's/#listen \[::\]:443 ssl http2;/listen \[::\]:443 ssl http2;/g' /usr/local/nginx/conf/vhost/${domain}.conf
    fi

    echo "Test Nginx configure file......"
    /usr/local/nginx/sbin/nginx -t
    echo "Reload Nginx......"
    /usr/local/nginx/sbin/nginx -s reload
        echo "Reload Apache..."
        /etc/init.d/httpd reload
}

