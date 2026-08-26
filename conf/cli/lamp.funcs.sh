#@ lamp 栈专属函数
lamp_start()
{
    echo "Starting LAMP..."
    /etc/init.d/httpd start
    /etc/init.d/mysql start
}

lamp_stop()
{
    echo "Stoping LAMP..."
    /etc/init.d/httpd stop
    /etc/init.d/mysql stop
}

lamp_reload()
{
    echo "Reload LAMP..."
    /etc/init.d/httpd graceful
    /etc/init.d/mysql reload
}

lamp_kill()
{
    echo "Kill apache,mysql process..."
    killall httpd
    killall mysqld
    echo "done."
}

lamp_status()
{
    /etc/init.d/httpd status
    /etc/init.d/mysql status
}

Add_VHost_Config()
{
    cat >"/usr/local/apache/conf/vhost/${domain}.conf"<<EOF
<VirtualHost *:80>
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
        read domain
        if [ "${domain}" != "" ] && [[ "$domain" = "${domain%[[:space:]]*}" ]]; then
            if [ -f "/usr/local/apache/conf/vhost/${domain}.conf" ]; then
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

    Echo_Yellow "Enter more domain name(example: nextlnmp.com *.nextlnmp.com): "
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
        al_name="${domain}"
    else
        Echo_Yellow "Enter access log filename(Default:${domain}-access_log): "
        read al_name
        if [ "${al_name}" == "" ]; then
            al_name="${domain}"
        fi
        echo "You access log filename: ${al_name}-access_log"
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

    if [ -s /usr/local/pureftpd/sbin/pure-ftpd ]; then
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
        read domain
        if [ "${domain}" == "" ]; then
            Echo_Red "Domain name can't be empty."
        else
            break
        fi
    done
    if [ ! -f "/usr/local/apache/conf/vhost/${domain}.conf" ]; then
        echo "=========================================="
        echo "Domain: ${domain} was not exist!"
        echo "=========================================="
        exit 1
    else
        rm -f /usr/local/apache/conf/vhost/${domain}.conf
        echo "========================================================"
        echo "Domain: ${domain} has been deleted."
        echo "Website files will not be deleted for security reasons."
        echo "You need to manually delete the website files."
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
    if /usr/local/apache/bin/httpd -v|grep -Eqi "Apache/2.4.*"; then
        Conf_H2='Protocols h2 h2c http/1.1'
    else
        Conf_H2=''
    fi
    if echo "${ssl_choice}" | grep -Eqi "^[2-4]$"; then
        Conf_SSLChain="SSLCertificateChainFile /usr/local/apache/conf/ssl/${domain}/ca.cer"
    fi

    sed -i 's@#Include conf/extra/httpd-ssl.conf@Include conf/extra/httpd-ssl.conf@g' /usr/local/apache/conf/httpd.conf
    cat >>"/usr/local/apache/conf/vhost/${domain}.conf"<<EOF

<VirtualHost *:443>
ServerAdmin ${email}
php_admin_value open_basedir "${vhostdir}:/tmp/:/var/tmp/:/proc/"
DocumentRoot ${vhostdir}
ServerName ${domain}
SSLEngine on
SSLCertificateFile ${ssl_certificate}
SSLCertificateKeyFile ${ssl_certificate_key}
${Conf_SSLChain}
${Conf_H2}
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

    if [ "${using_301}" = "y" ]; then
        sed -i '0,/^ServerName/!b;//a\RewriteEngine On\nRewriteCond %{HTTPS} off\nRewriteCond %{REQUEST_URI} !^\/\.well-known/.*$\nRewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]' /usr/local/apache/conf/vhost/${domain}.conf
    fi

    if [ "${moredomain}" != "" ]; then
        sed -i "/^SSLEngine on/i\ServerAlias ${moredomain}" /usr/local/apache/conf/vhost/${domain}.conf
    fi

    echo "Test Apache configure file..."
    /etc/init.d/httpd configtest
    echo "Restart Apache..."
    /etc/init.d/httpd graceful
}

