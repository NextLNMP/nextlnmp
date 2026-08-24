#!/usr/bin/env bash

Add_Iptables_Rules()
{
    #add iptables firewall rules
    if command -v iptables >/dev/null 2>&1; then
        iptables -I INPUT 1 -i lo -j ACCEPT
        iptables -I INPUT 2 -m state --state ESTABLISHED,RELATED -j ACCEPT
        iptables -I INPUT 3 -p tcp --dport 22 -j ACCEPT
        iptables -I INPUT 4 -p tcp --dport 80 -j ACCEPT
        iptables -I INPUT 5 -p tcp --dport 443 -j ACCEPT
        iptables -I INPUT 6 -p tcp --dport 3306 -j DROP
        iptables -I INPUT 7 -p icmp -m icmp --icmp-type 8 -j ACCEPT
        if [ "$PM" = "yum" ]; then
            yum -y install iptables-services
            service iptables save
            service iptables reload
            if command -v firewalld >/dev/null 2>&1; then
                systemctl stop firewalld
                systemctl disable firewalld
            fi
            StartUp iptables
        elif [ "$PM" = "apt" ]; then
            apt-get --no-install-recommends install -y iptables-persistent
            if [ -s /etc/init.d/netfilter-persistent ]; then
                /etc/init.d/netfilter-persistent save
                /etc/init.d/netfilter-persistent reload
                StartUp netfilter-persistent
            else
                /etc/init.d/iptables-persistent save
                /etc/init.d/iptables-persistent reload
                StartUp iptables-persistent
            fi
        fi
    fi
}

Add_nextLNMP_Startup()
{
    echo "Add Startup and Starting nextLNMP..."
    \cp ${cur_dir}/conf/nextlnmp /bin/nextlnmp
    chmod +x /bin/nextlnmp
    if [ "${WebServer}" = "caddy" ]; then
        # caddy.sh 已 enable+start systemd 单元并装好 /etc/init.d/caddy shim；把 CLI 的 web 服务操作指过去
        sed -i 's#/etc/init.d/nginx#/etc/init.d/caddy#g' /bin/nextlnmp
    else
        StartUp nginx
        StartOrStop start nginx
    fi
    if [[ "${DBSelect}" =~ ^(6|7|8|9|10|12|13)$ ]]; then
        StartUp mariadb
        StartOrStop start mariadb
        sed -i 's#/etc/init.d/mysql#/etc/init.d/mariadb#' /bin/nextlnmp
    elif [[ "${DBSelect}" =~ ^(1|2|3|4|5|11)$ ]]; then
        StartUp mysql
        StartOrStop start mysql
    elif [ "${DBSelect}" = "0" ]; then
        sed -i 's#/etc/init.d/mysql.*##' /bin/nextlnmp
    fi
    StartUp php-fpm
    StartOrStop start php-fpm
    if [ "${PHPSelect}" = "1" ]; then
        sed -i 's#/usr/local/php/var/run/php-fpm.pid#/usr/local/php/logs/php-fpm.pid#' /bin/nextlnmp
    fi
}

Add_nextLNMPA_Startup()
{
    echo "Add Startup and Starting nextLNMPA..."
    \cp ${cur_dir}/conf/nextlnmpa /bin/nextlnmp
    chmod +x /bin/nextlnmp
    StartUp nginx
    StartOrStop start nginx
    if [[ "${DBSelect}" =~ ^(6|7|8|9|10|12|13)$ ]]; then
        StartUp mariadb
        StartOrStop start mariadb
        sed -i 's#/etc/init.d/mysql#/etc/init.d/mariadb#' /bin/nextlnmp
    elif [[ "${DBSelect}" =~ ^(1|2|3|4|5|11)$ ]]; then
        StartUp mysql
        StartOrStop start mysql
    elif [ "${DBSelect}" = "0" ]; then
        sed -i 's#/etc/init.d/mysql.*##' /bin/nextlnmp
    fi
    StartUp httpd
    StartOrStop start httpd
}

Add_LAMP_Startup()
{
    echo "Add Startup and Starting NextLAMP..."
    \cp ${cur_dir}/conf/nextlamp /bin/nextlnmp
    chmod +x /bin/nextlnmp
    StartUp httpd
    StartOrStop start httpd
    if [[ "${DBSelect}" =~ ^(6|7|8|9|10|12|13)$ ]]; then
        StartUp mariadb
        StartOrStop start mariadb
        sed -i 's#/etc/init.d/mysql#/etc/init.d/mariadb#' /bin/nextlnmp
    elif [[ "${DBSelect}" =~ ^(1|2|3|4|5|11)$ ]]; then
        StartUp mysql
        StartOrStop start mysql
    elif [ "${DBSelect}" = "0" ]; then
        sed -i 's#/etc/init.d/mysql.*##' /bin/nextlnmp
    fi
}

Check_Nginx_Files()
{
    isNginx=""
    echo "============================== Check install =============================="
    echo "Checking ..."
    if [[ -s /usr/local/nginx/conf/nginx.conf && -s /usr/local/nginx/sbin/nginx ]]; then
        Echo_Green "Nginx: OK"
        isNginx="ok"
    else
        Echo_Red "Error: Nginx install failed."
    fi
}

Check_Caddy_Files()
{
    isNginx=""
    echo "============================== Check install =============================="
    echo "Checking ..."
    if [ -s /usr/local/bin/caddy ] && [ -s /etc/caddy/Caddyfile ] && systemctl is-active --quiet caddy; then
        Echo_Green "Caddy: OK"
        isNginx="ok"
    else
        Echo_Red "Error: Caddy install failed."
    fi
}

Check_DB_Files()
{
    isDB=""
    if [[ "${DBSelect}" =~ ^(6|7|8|9|10|12|13)$ ]]; then
        if [[ -s /usr/local/mariadb/bin/mysql && -s /usr/local/mariadb/bin/mysqld_safe && -s /etc/my.cnf ]]; then
            Echo_Green "MariaDB: OK"
            isDB="ok"
        else
            Echo_Red "Error: MariaDB install failed."
        fi
    elif [[ "${DBSelect}" =~ ^(1|2|3|4|5|11)$ ]]; then
        if [[ -s /usr/local/mysql/bin/mysql && -s /usr/local/mysql/bin/mysqld_safe && -s /etc/my.cnf ]]; then
            Echo_Green "MySQL: OK"
            isDB="ok"
        else
            Echo_Red "Error: MySQL install failed."
        fi
    elif [ "${DBSelect}" = "0" ]; then
        Echo_Green "Do not install MySQL/MariaDB."
        isDB="ok"
    fi
}

Check_PHP_Files()
{
    isPHP=""
    if [ "${Stack}" = "nextlnmp" ]; then
        if [[ -s /usr/local/php/sbin/php-fpm && -s /usr/local/php/etc/php.ini && -s /usr/local/php/bin/php ]]; then
            Echo_Green "PHP: OK"
            Echo_Green "PHP-FPM: OK"
            isPHP="ok"
        else
            Echo_Red "Error: PHP install failed."
        fi
    else
        if [[ -s /usr/local/php/bin/php && -s /usr/local/php/etc/php.ini ]]; then
            Echo_Green "PHP: OK"
            isPHP="ok"
        else
            Echo_Red "Error: PHP install failed."
        fi
    fi
}

Check_Apache_Files()
{
    isApache=""
    if [[ "${PHPSelect}" =~ ^[6789]|10$ ]]; then
        if [[ -s /usr/local/apache/bin/httpd && -s /usr/local/apache/modules/libphp7.so && -s /usr/local/apache/conf/httpd.conf ]]; then
            Echo_Green "Apache: OK"
            isApache="ok"
        else
            Echo_Red "Error: Apache install failed."
        fi
    elif [[ "${PHPSelect}" =~ ^1[1-5]$ ]]; then
        if [[ -s /usr/local/apache/bin/httpd && -s /usr/local/apache/modules/libphp.so && -s /usr/local/apache/conf/httpd.conf ]]; then
            Echo_Green "Apache: OK"
            isApache="ok"
        else
            Echo_Red "Error: Apache install failed."
        fi
    else
        if [[ -s /usr/local/apache/bin/httpd && -s /usr/local/apache/modules/libphp5.so && -s /usr/local/apache/conf/httpd.conf ]]; then
            Echo_Green "Apache: OK"
            isApache="ok"
        else
            Echo_Red "Error: Apache install failed."
        fi
    fi
}

Clean_DB_Src_Dir()
{
    echo "Clean database src directory..."
    if [[ "${DBSelect}" =~ ^(1|2|3|4|5|11)$ ]]; then
        rm -rf ${cur_dir}/src/${Mysql_Ver}
    elif [[ "${DBSelect}" =~ ^(6|7|8|9|10|12|13)$ ]]; then
        rm -rf ${cur_dir}/src/${Mariadb_Ver}
    fi
    if [[ "${DBSelect}" = "4" ]]; then
        [[ -d "${cur_dir}/src/${Boost_Ver}" ]] && rm -rf ${cur_dir}/src/${Boost_Ver}
    elif [[ "${DBSelect}" = "5" ]]; then
        [[ -d "${cur_dir}/src/${Boost_New_Ver}" ]] && rm -rf ${cur_dir}/src/${Boost_New_Ver}
    fi
}

Clean_PHP_Src_Dir()
{
    echo "Clean PHP src directory..."
    rm -rf ${cur_dir}/src/${Php_Ver}
}

Clean_Web_Src_Dir()
{
    echo "Clean Web Server src directory..."
    if [ "${Stack}" = "nextlnmp" ]; then
        rm -rf ${cur_dir}/src/${Nginx_Ver}*
    elif [ "${Stack}" = "nextlnmpa" ]; then
        rm -rf ${cur_dir}/src/${Nginx_Ver}*
        rm -rf ${cur_dir}/src/${Apache_Ver}
    elif [ "${Stack}" = "lamp" ]; then
        rm -rf ${cur_dir}/src/${Apache_Ver}
    fi
    [[ -d "${cur_dir}/src/${Openssl_Ver}" ]] && rm -rf ${cur_dir}/src/${Openssl_Ver}
    [[ -d "${cur_dir}/src/${Openssl_New_Ver}" ]] && rm -rf ${cur_dir}/src/${Openssl_New_Ver}
    [[ -d "${cur_dir}/src/${Pcre_Ver}" ]] && rm -rf ${cur_dir}/src/${Pcre_Ver}
    [[ -d "${cur_dir}/src/${LuaNginxModule}" ]] && rm -rf ${cur_dir}/src/${LuaNginxModule}
    [[ -d "${cur_dir}/src/${NgxDevelKit}" ]] && rm -rf ${cur_dir}/src/${NgxDevelKit}
    [[ -d "${cur_dir}/src/${NgxFancyIndex_Ver}" ]] && rm -rf ${cur_dir}/src/${NgxFancyIndex_Ver}
}

Print_Sucess_Info()
{
    Clean_Web_Src_Dir
    local SERVER_IP=$(hostname -I | awk '{print $1}')
    stop_time=$(date +%s)
    local COST_MIN=$(((stop_time-start_time)/60))

    # 中英文混排对齐函数（中文占2列，ASCII占1列，兼容任何locale）
    _pad() {
        local content="$1"
        local total=62
        local total_bytes=$(printf '%s' "$content" | wc -c)
        local ascii_bytes=$(printf '%s' "$content" | LC_ALL=C tr -d '[\200-\377]' | wc -c)
        local non_ascii_bytes=$((total_bytes - ascii_bytes))
        local display_width=$((ascii_bytes + non_ascii_bytes * 2 / 3))
        local pad=$((total - display_width))
        [ $pad -lt 1 ] && pad=1
        printf "|%s%${pad}s|" "$content" ""
    }

    echo ""
    Echo_Green "+==============================================================+"
    Echo_Green "|                                                              |"
    Echo_Green "$(_pad "  NextLNMP v${NEXTLNMP_Ver} 安装成功！耗时 ${COST_MIN} 分钟")"
    Echo_Green "$(_pad "  系统：${DISTRO} Linux · 作者：静水流深")"
    Echo_Green "$(_pad "  中国站长论坛：https://cnwebmasters.com")"
    Echo_Green "|                                                              |"
    Echo_Green "+==============================================================+"
    echo "|"
    echo "|  🌐 访问地址（复制链接到浏览器打开）："
    echo "|     网站首页：http://${SERVER_IP}/"
    echo "|     探针页面：http://${SERVER_IP}/p.php"
    echo "|     phpMyAdmin：http://${SERVER_IP}/phpmyadmin/"
    echo "|"
    echo "|  📁 网站目录：${Default_Website_Dir}"
    echo "|"
    if [ "${DBSelect}" != "0" ]; then
        echo "|  🔑 数据库 root 密码：${DB_Root_Password}"
        echo "|"
    fi
    echo "|  📦 常用命令（复制后回车即可执行）："
    echo "|     nextlnmp start            # 启动所有服务"
    echo "|     nextlnmp stop             # 停止所有服务"
    echo "|     nextlnmp restart          # 重启所有服务"
    echo "|     nextlnmp status           # 查看运行状态"
    echo "|     nextlnmp vhost add        # 添加新站点"
    echo "|     nextlnmp info             # 再次查看本页信息"
    if [ "${DBSelect}" != "0" ]; then
        echo "|     nextlnmp password         # 查看数据库密码"
        echo "|     nextlnmp password --delete  # 记录密码后删除密码文件"
    fi
    echo "|"
    echo "|  📖 文档：https://nextlnmp.cn  💬 QQ群：615298"
    Echo_Green "|                                                              |"
    Echo_Green "+==============================================================+"
    echo ""

    # 保存安装信息到文件，方便日后查看
    INFO_FILE="/root/nextlnmp-info.txt"
    cat > ${INFO_FILE} << INFOEOF
NextLNMP v${NEXTLNMP_Ver} 安装信息
安装时间：$(date '+%Y-%m-%d %H:%M:%S')
系统：${DISTRO} Linux
服务器IP：${SERVER_IP}

访问地址：
  网站首页：http://${SERVER_IP}/
  探针页面：http://${SERVER_IP}/p.php
  phpMyAdmin：http://${SERVER_IP}/phpmyadmin/

网站目录：${Default_Website_Dir}
数据库 root 密码：${DB_Root_Password}

常用命令：
  nextlnmp info             # 查看本文件
  nextlnmp vhost add        # 添加新站点
  nextlnmp password         # 查看数据库密码
  nextlnmp {start|stop|restart|reload|status}

文档：https://nextlnmp.cn
QQ群：615298
INFOEOF
    chmod 600 ${INFO_FILE}
    Echo_Green "📄 安装信息已保存至：${INFO_FILE}（权限600，仅root可读）"
    echo ""
    exit 0
}

Print_Failed_Info()
{
    if [ -s /bin/nextlnmp ]; then
        rm -f /bin/nextlnmp
    fi
    echo ""
    Echo_Red "+==============================================================+"
    Echo_Red "|            ❌ nextLNMP 安装失败                             |"
    Echo_Red "+==============================================================+"
    Echo_Red "请将安装日志反馈给我们："
    Echo_Red "  日志文件：/root/nextlnmp-install.log"
    Echo_Red "  反馈地址：https://nextlnmp.com"
    Echo_Red "  QQ群：615298"
}

Check_nextLNMP_Install()
{
    if [ "${WebServer}" = "caddy" ]; then
        Check_Caddy_Files
    else
        Check_Nginx_Files
    fi
    Check_DB_Files
    Check_PHP_Files
    if [[ "${isNginx}" = "ok" && "${isDB}" = "ok" && "${isPHP}" = "ok" ]]; then
        Print_Sucess_Info
    else
        Print_Failed_Info
    fi
}

Check_nextLNMPA_Install()
{
    Check_Nginx_Files
    Check_DB_Files
    Check_PHP_Files
    Check_Apache_Files
    if [[ "${isNginx}" = "ok" && "${isDB}" = "ok" && "${isPHP}" = "ok"  && "${isApache}" = "ok" ]]; then
        Print_Sucess_Info
    else
        Print_Failed_Info
    fi
}

Check_LAMP_Install()
{
    Check_Apache_Files
    Check_DB_Files
    Check_PHP_Files
    if [[ "${isApache}" = "ok" && "${isDB}" = "ok" && "${isPHP}" = "ok" ]]; then
        Print_Sucess_Info
    else
        Print_Failed_Info
    fi
}
