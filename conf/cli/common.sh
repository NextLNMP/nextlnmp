#@ NextLNMP CLI 公共函数库：三个栈共享的唯一副本。改这里，然后跑 bash tools/build-cli.sh
#@ 生成物 conf/nextlnmp{,a}/conf/nextlamp 同样入库（保证单文件自包含），CI 校验两者一致。
Check_DB()
{
    if [[ -s /usr/local/mariadb/bin/mysql && -s /usr/local/mariadb/bin/mysqld_safe && -s /etc/my.cnf ]]; then
        MySQL_Bin="/usr/local/mariadb/bin/mysql"
        MySQL_Ver=`/usr/local/mariadb/bin/mysql_config --version`
    elif [[ -s /usr/local/mysql/bin/mysql && -s /usr/local/mysql/bin/mysqld_safe && -s /etc/my.cnf ]]; then
        MySQL_Bin="/usr/local/mysql/bin/mysql"
        MySQL_Ver=`/usr/local/mysql/bin/mysql_config --version`
    else
        MySQL_Bin="None"
    fi
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

# 这些临时文件里带明文数据库密码，绝不能放 /tmp：
#   ① /tmp 世界可写，固定文件名可被普通用户抢先建成符号链接，root 一写就被劫持；
#   ② 每个站点的 open_basedir 恰好放行了 /tmp/，任何一个被挂马的 PHP 站点
#      都能在建站/删站的窗口里读到新数据库的账号密码。
# 改用 root 私有目录（/root 本身 700，不存在抢建问题）。
NLX_TMPDIR="/root/.nextlnmp-tmp"
Nlx_Tmp_Init()
{
    [ -d "${NLX_TMPDIR}" ] || mkdir -p "${NLX_TMPDIR}"
    chmod 700 "${NLX_TMPDIR}"
}

Do_Query()
{
    Nlx_Tmp_Init
    echo "$1" >${NLX_TMPDIR}/.mysql.tmp
    chmod 600 ${NLX_TMPDIR}/.mysql.tmp
    Check_DB
    ${MySQL_Bin} --defaults-file=~/.my.cnf <${NLX_TMPDIR}/.mysql.tmp
    return $?
}

TempMycnf_Clean()
{
    if [ -s ~/.my.cnf ]; then
        rm -f ~/.my.cnf
    fi
    if [ -s ${NLX_TMPDIR}/.mysql.tmp ]; then
        rm -f ${NLX_TMPDIR}/.mysql.tmp
    fi
}

Enter_Database_Name()
{
    while :;do
        Echo_Yellow "Enter database name: "
        read database_name || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
        if [ "${database_name}" == "" ]; then
            Echo_Red "Database Name can't be empty!"
        else
            break
        fi
    done
}

Enter_Ftp_Name()
{
    while :;do
        Echo_Yellow "Enter ftp account name: "
        read ftp_account_name || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
        if [ "${ftp_account_name}" == "" ]; then
            Echo_Red "FTP account name can't be empty!"
        else
            break
        fi
    done
}

Add_Ftp_Menu()
{
    Enter_Ftp_Name
    while :;do
        Echo_Yellow "Enter password for ftp account ${ftp_account_name}: "
        read ftp_account_password || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
        if [ "${ftp_account_password}" == "" ]; then
            Echo_Red "FTP password can't be empty!"
        else
            break
        fi
    done
    if [ "${vhostdir}" == "" ]; then
        while :;do
            Echo_Yellow "Enter directory for ftp account ${ftp_account_name}: "
            read vhostdir || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
            if [ "${vhostdir}" == "" ]; then
                Echo_Red "Directory can't be empty!"
            else
                break
            fi
        done
    fi
}

Check_Pureftpd()
{
    if [ ! -f /usr/local/pureftpd/sbin/pure-ftpd ]; then
        Echo_Red "Pureftpd was not installed!"
        exit 1
    fi
}

Show_Ftp()
{
    List_Ftp
    Enter_Ftp_Name
    echo "Your ftp account ${ftp_account_name} details:"
    /usr/local/pureftpd/bin/pure-pw show ${ftp_account_name}
    [ $? -eq 0 ] && echo "Ok." || echo "failed."
}

Add_DNS_SSL_Select_Menu()
{
    echo "1: Use Let's Encrypt to create SSL Certificate and Key"
    echo "2: Use ZeroSSL to create SSL Certificate and Key"
        while :;do
        Echo_Yellow "Enter 1 or 2: "
        read dns_ssl_choice || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
        if [[ "${dns_ssl_choice}" =~ ^(1|2)$ ]]; then
            Check_Acme_EMail
            break
        else
            Echo_Red "Please Enter 1 or 2!"
        fi
    done
}

Add_DNS_SSL_Only_Info_Menu()
{
    Add_DNS_SSL_Select_Menu

    domain=""
    while :;do
        Echo_Yellow "Please enter domain(example: nextlnmp.com): "
        read domain || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
        if [ "${domain}" != "" ] && [[ "$domain" = "${domain%[[:space:]]*}" ]]; then
            echo " Your domain: ${domain}"
            break
        else
            Echo_Red "Domain name can't be empty or contain spaces!"
        fi
    done

    Echo_Yellow "Enter more domain name(example: *.nextlnmp.com): "
    read moredomain
    if [ "${moredomain}" != "" ]; then
        echo " domain list: ${moredomain}"
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
  echo -n $(Color_Text "$1" "33")
}

Echo_Blue()
{
  echo $(Color_Text "$1" "34")
}

Sleep_Sec()
{
    seconds=$1
    while [ "${seconds}" -ge "0" ];do
      echo -ne "\r     \r"
      echo -n ${seconds}
      seconds=$(($seconds - 1))
      sleep 1
    done
    echo -ne "\r"
}

Add_Database()
{
    # MySQL 8.x（含 8.4）已删除 GRANT ... IDENTIFIED BY 旧语法；MariaDB 版本号不以 8 开头，不受影响
    if echo "${MySQL_Ver}" | grep -Eqi '^8\.';then
        Nlx_Tmp_Init
        cat >${NLX_TMPDIR}/.add_mysql.sql<<EOF
CREATE USER '${database_name}'@'localhost' IDENTIFIED BY '${mysql_password}';
CREATE USER '${database_name}'@'127.0.0.1' IDENTIFIED BY '${mysql_password}';
GRANT USAGE ON *.* TO '${database_name}'@'localhost';
GRANT USAGE ON *.* TO '${database_name}'@'127.0.0.1';
CREATE DATABASE IF NOT EXISTS \`${database_name}\`;
GRANT ALL PRIVILEGES ON \`${database_name}\`.* TO '${database_name}'@'localhost';
GRANT ALL PRIVILEGES ON \`${database_name}\`.* TO '${database_name}'@'127.0.0.1';
FLUSH PRIVILEGES;
EOF

    else
        Nlx_Tmp_Init
        cat >${NLX_TMPDIR}/.add_mysql.sql<<EOF
CREATE USER '${database_name}'@'localhost' IDENTIFIED BY '${mysql_password}';
CREATE USER '${database_name}'@'127.0.0.1' IDENTIFIED BY '${mysql_password}';
GRANT USAGE ON *.* TO '${database_name}'@'localhost' IDENTIFIED BY '${mysql_password}';
GRANT USAGE ON *.* TO '${database_name}'@'127.0.0.1' IDENTIFIED BY '${mysql_password}';
CREATE DATABASE IF NOT EXISTS \`${database_name}\`;
GRANT ALL PRIVILEGES ON \`${database_name}\`.* TO '${database_name}'@'localhost';
GRANT ALL PRIVILEGES ON \`${database_name}\`.* TO '${database_name}'@'127.0.0.1';
FLUSH PRIVILEGES;
EOF

    fi
    ${MySQL_Bin} --defaults-file=~/.my.cnf < ${NLX_TMPDIR}/.add_mysql.sql
    [ $? -eq 0 ] && echo "Add database Successfully." || echo "Add database failed!"
    rm -f ${NLX_TMPDIR}/.add_mysql.sql
}

Add_Ftp()
{
    www_uid=`id -u www`
    www_gid=`id -g www`
    if [ ! -d "${vhostdir}" ]; then
        mkdir -p ${vhostdir}
        chown www:www -R ${vhostdir}
    fi
    cat >/tmp/pass${ftp_account_name}<<EOF
${ftp_account_password}
${ftp_account_password}
EOF
    /usr/local/pureftpd/bin/pure-pw useradd ${ftp_account_name} -f /usr/local/pureftpd/etc/pureftpd.passwd -u ${www_uid} -g ${www_gid} -d ${vhostdir} -m < /tmp/pass${ftp_account_name}
    [ $? -eq 0 ] && echo "Created FTP User: ${ftp_account_name} Successfully." || echo "FTP User: ${ftp_account_name} already exists!"
    rm -f /tmp/pass${ftp_account_name}
}

Edit_Database()
{
    while :;do
        Echo_Yellow "Enter database username: "
        read database_username || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
        if [ "${database_username}" == "" ]; then
            Echo_Red "Database Username can't be empty!"
        else
            break
        fi
    done
    while :;do
        Echo_Yellow "Enter NEW Password: "
        read database_username_passwd || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
        if [ "${database_username_passwd}" == "" ]; then
            Echo_Red "Database Password can't be empty!"
        else
            break
        fi
    done

    if echo "${MySQL_Ver}" | grep -Eq '^(10\.([4-9]|[1-9][0-9])|1[1-9])\.'; then
        # MariaDB 10.4+ 的 mysql.user 是视图，直接 UPDATE 会失败，走 SET PASSWORD
        Do_Query "SET PASSWORD FOR '${database_username}'@'127.0.0.1' = PASSWORD('${database_username_passwd}');"
        Do_Query "SET PASSWORD FOR '${database_username}'@'localhost' = PASSWORD('${database_username_passwd}');"
    elif echo "${MySQL_Ver}" | grep -Eqi '^5.7.';then
        Do_Query "UPDATE mysql.user SET authentication_string=PASSWORD('${database_username_passwd}') WHERE User='${database_username}' AND Host IN ('localhost', '127.0.0.1', '::1');"
    elif echo "${MySQL_Ver}" | grep -Eqi '^8\.';then
        Do_Query "SET PASSWORD FOR '${database_username}'@'127.0.0.1' = '${database_username_passwd}';"
        Do_Query "SET PASSWORD FOR '${database_username}'@'localhost' = '${database_username_passwd}';"
    else
        Do_Query "UPDATE mysql.user SET Password=PASSWORD('${database_username_passwd}') WHERE User='${database_username}' AND Host IN ('localhost', '127.0.0.1', '::1');"
    fi
    [ $? -eq 0 ] && echo "Edit user password Successfully." || echo "Edit user password databases failed!"
    Do_Query "FLUSH PRIVILEGES;"
}

List_Database()
{
    ${MySQL_Bin} --defaults-file=~/.my.cnf -e "SHOW DATABASES;"
    [ $? -eq 0 ] && echo "List all databases Successfully." || echo "List all databases failed!"
}

List_Ftp()
{
    /usr/local/pureftpd/bin/pure-pw list -f /usr/local/pureftpd/etc/pureftpd.passwd
    [ $? -eq 0 ] && echo "List FTP User Successfully." || echo "Read database failed."
}

Del_Database()
{
    List_Database
    Enter_Database_Name
    if [[ "${database_name}" == "information_schema" || "${database_name}" == "mysql" || "${database_name}" == "performance_schema" ]]; then
        echo "MySQL System Database can't be delete!"
        exit 1
    fi
    echo "Your will delete database and MySQL user with same name: ${database_name}"
    echo "Sleep 10s, Press ctrl+c to cancel..."
    Sleep_Sec 10
    Nlx_Tmp_Init
    cat >${NLX_TMPDIR}/.del.mysql.sql<<EOF
DROP USER '${database_name}'@'127.0.0.1';
DROP USER '${database_name}'@'localhost';
DROP DATABASE \`${database_name}\`;
FLUSH PRIVILEGES;
EOF
    ${MySQL_Bin} --defaults-file=~/.my.cnf < ${NLX_TMPDIR}/.del.mysql.sql
    [ $? -eq 0 ] && echo "Delete database: ${database_name} Successfully." || echo "Delete database: ${database_name} failed!"
    rm -f ${NLX_TMPDIR}/.del.mysql.sql
}

Edit_Ftp()
{
    List_Ftp
    Enter_Ftp_Name
    Echo_Yellow "Enter password for ftp account ${ftp_account_name}: "
    read ftp_account_password
    if [ "${ftp_account_password}" != "" ]; then
        cat >/tmp/pass${ftp_account_name}<<EOF
${ftp_account_password}
${ftp_account_password}
EOF
        /usr/local/pureftpd/bin/pure-pw passwd ${ftp_account_name} -f /usr/local/pureftpd/etc/pureftpd.passwd -m < /tmp/pass${ftp_account_name}
        [ $? -eq 0 ] && echo "FTP User: ${ftp_account_name} change password Successfully." || echo "FTP User: ${ftp_account_name} change password failed!"
        rm -f /tmp/pass${ftp_account_name}
    else
        echo "FTP password will not change."
    fi
    Echo_Yellow "Enter directory for ftp account ${ftp_account_name}: "
    read vhostdir
    if [ "${vhostdir}" != "" ]; then
        www_uid=`id -u www`
        www_gid=`id -g www`
        if [ ! -d "${vhostdir}" ]; then
            mkdir -p ${vhostdir}
            chown www:www -R ${vhostdir}
        fi
        /usr/local/pureftpd/bin/pure-pw usermod ${ftp_account_name} -f /usr/local/pureftpd/etc/pureftpd.passwd -u ${www_uid} -g ${www_gid} -d ${vhostdir} -m
        [ $? -eq 0 ] && echo "FTP User: ${ftp_account_name} change directory Successfully." || echo "FTP User: ${ftp_account_name} change directory failed!"
    else
        echo "Directory will not change."
    fi
}

Del_Ftp()
{
    List_Ftp
    Enter_Ftp_Name
    echo "Your will delete ftp user ${ftp_account_name}"
    echo "Sleep 3s,Press ctrl+c to cancel..."
    Sleep_Sec 3
    /usr/local/pureftpd/bin/pure-pw userdel ${ftp_account_name} -f /usr/local/pureftpd/etc/pureftpd.passwd -m
    [ $? -eq 0 ] && echo "FTP User: ${ftp_account_name} deleted Successfully." || echo "FTP User: ${ftp_account_name} not exists!"
}

Function_Ftp()
{
    case "$1" in
        [aA][dD][dD])
            Add_Ftp_Menu
            Add_Ftp
            ;;
        [lL][iI][sS][tT])
            List_Ftp
            ;;
        [dD][eE][lL])
            Del_Ftp
            ;;
        [eE][dD][iI][tT])
            Edit_Ftp
            ;;
        [eE][xX][iI][tT])
            exit 1
            ;;
        [sS][hH][oO][wW])
            Show_Ftp
            ;;
        *)
            echo "Usage: nextlnmp ftp {add|list|del}"
            exit 1
            ;;
    esac
}

Function_Vhost()
{
    case "$1" in
        [aA][dD][dD])
            Add_VHost
            ;;
        [lL][iI][sS][tT])
            List_VHost
            ;;
        [dD][eE][lL])
            Del_VHost
            ;;
        [eE][xX][iI][tT])
            exit 1
            ;;
        *)
            echo "Usage: nextlnmp vhost {add|list|del}"
            exit 1
            ;;
    esac
}

Function_Database()
{
    case "$1" in
        [aA][dD][dD])
            Add_Database_Menu
            Add_Database
            ;;
        [lL][iI][sS][tT])
            List_Database
            ;;
        [dD][eE][lL])
            Del_Database
            ;;
        [eE][dD][iI][tT])
            Edit_Database
            ;;
        [eE][xX][iI][tT])
            exit 1
            ;;
        *)
            echo "Usage: nextlnmp database {add|list|del}"
            exit 1
            ;;
    esac
}

Check_Acme_EMail()
{
    if [ ! -s /usr/local/acme.sh/account.conf ] || ! cat /usr/local/acme.sh/account.conf | grep -Eq "^ACCOUNT_EMAIL="; then
        default_email="letsencrypt@nextlnmp.cn"
        echo ""
        Echo_Yellow "请输入接收 SSL 证书到期提醒的邮箱："
        echo "（直接回车使用默认：${default_email}，证书到期通知将发至 NextLNMP 官方）"
        read -e email_address
        if [ "${email_address}" == "" ]; then
            email_address="${default_email}"
        fi
        while :;do
            if [[ "${email_address}" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                echo "使用邮箱：${email_address}"
                break
            else
                Echo_Red "邮箱格式不正确，请重新输入："
                read -e email_address || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
            fi
        done
    fi
}

Return_301_Menu()
{
    echo ""
    Echo_Yellow "是否将 HTTP 自动跳转到 HTTPS？（推荐开启，直接回车默认开启）[Y/n] "
    read -e using_301
    if [[ "${using_301}" == "n" || "${using_301}" == "N" ]]; then
        echo "不设置 301 跳转。"
        using_301="n"
    else
        echo ""
        echo "已设置：http://${domain} 自动跳转至 https://${domain}"
        using_301="y"
    fi
}

# 「连不上数据库」和「密码错了」是两回事。原来一律报「密码错误，请重新输入！」
# 并无限重问：数据库没启动的用户输什么都不对，也不会被告知该去启动服务；
# 加上 read 不判 EOF，非交互场景下就是 100% CPU 的死循环。
DB_Conn_Failed()
{
    # 用 . 代替撇号，避开 shell 引号地狱（Can't / Cannot 都能覆盖）
    echo "$1" | grep -Eqi "Can.t connect|Cannot connect|connect to (local )?server|\b(2002|2003)\b|No such file or directory"
}

Verify_DB_Password()
{
    Check_DB
    if [ "${MySQL_Bin}" = "None" ]; then
        Echo_Red "没有检测到已安装的 MySQL/MariaDB，无法验证密码。"
        exit 1
    fi
    if [ -f /root/.nextlnmp_db_password ]; then
        DB_Root_Password=$(cat /root/.nextlnmp_db_password)
        Make_TempMycnf "${DB_Root_Password}"
        Do_Query "" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "已自动读取数据库 root 密码。"
            return
        fi
    fi
    status=1
    while [ $status -eq 1 ]; do
        Echo_Yellow "请输入数据库 root 密码："
        read -e DB_Root_Password || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
        Make_TempMycnf "${DB_Root_Password}"
        db_err=$(Do_Query "" 2>&1 >/dev/null)
        status=$?
        if [ $status -ne 0 ]; then
            if DB_Conn_Failed "${db_err}"; then
                Echo_Red "连不上数据库服务，这不是密码问题："
                Echo_Red "  ${db_err}"
                Echo_Red "请先确认数据库已启动（nextlnmp restart，或 /etc/init.d/mysql start），再重试。"
                exit 1
            fi
            Echo_Red "密码错误，请重新输入！"
        fi
    done
    echo "数据库 root 密码验证通过。"
}

Add_Database_Menu()
{
    # 由域名派生库名；nextlnmp database add 独立调用时没有 ${domain}，退回随机名，
    # 否则提示里承诺的"自动生成"会是空串，用户回车反被拒绝（真机装测实测）
    auto_db_name=$(echo "${domain}" | sed 's/\.//g' | sed 's/-//g' | cut -c1-16)
    if [ -z "${auto_db_name}" ]; then
        auto_db_name="db$(< /dev/urandom tr -dc 'a-z0-9' | head -c8)"
    fi
    echo ""
    echo "请输入数据库名（直接回车使用自动生成的：${auto_db_name}）："
    read -e database_name || database_name=""
    if [ "${database_name}" == "" ]; then
        database_name="${auto_db_name}"
    fi
    while [ "${database_name}" == "" ]; do
        Echo_Red "数据库名不能为空，请重新输入："
        # read 失败=标准输入已关闭（管道/脚本调用），此时必须退出循环，
        # 否则空转烧 CPU（真机实测 35% CPU 停不下来）
        read -e database_name || { database_name="${auto_db_name}"; break; }
    done
    echo "数据库名：${database_name}"
    auto_password=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c16)
    echo ""
    echo "请输入数据库密码（直接回车自动生成随机密码）："
    read -e mysql_password || mysql_password=""
    if [ "${mysql_password}" == "" ]; then
        mysql_password="${auto_password}"
    fi
    Echo_Green "数据库密码：${mysql_password}"
}

List_VHost()
{
    echo "当前虚拟主机列表："
    ls ${Vhost_Dir}/ | grep ".conf$" | sed 's/.conf//g'
}

Add_SSL()
{
    if [ "${ssl_choice}" == "1" ]; then
        Create_SSL_Config
    elif echo "${ssl_choice}" | grep -Eqi "^[2-4]$"; then
        letsdomain=""
        if [ "${moredomain}" != "" ]; then
            letsdomain="-d ${domain}"
            for i in ${moredomain};do
                letsdomain=${letsdomain}" -d ${i}"
            done
        else
            letsdomain="-d ${domain}"
        fi
        if [ ! -s "${Vhost_Dir}/${domain}.conf" ]; then
            Add_VHost_Config
        fi
        if [ ! -d "${vhostdir}" ]; then
            mkdir -p "${vhostdir}"
        fi

        if [[ "${vhostdir}" == "" || "${letsdomain}" == "" ]]; then
            Echo_Red "Two parameters are needed!"
            exit 1
        fi
        if [ ! -d "${vhostdir}" ]; then
            Echo_Red "${vhostdir} does not exist or is not a directory!"
            exit
        fi

        Install_Check_Acme.sh

        if [ -s ${Web_SSL_Dir}/${domain}/fullchain.cer ]; then
            echo "Removing exist domain certificate..."
            rm -rf ${Web_SSL_Dir}/${domain}
        fi

        if [ "${ssl_choice}" == "2" ]; then
            echo "Generate ssl certificate using Let's Encrypt..."
            /usr/local/acme.sh/acme.sh ${acme_sh_sudo} --server letsencrypt --issue ${letsdomain} -w ${vhostdir} -k 2048 --reloadcmd "${Web_Initd} reload"
        elif [ "${ssl_choice}" == "3" ]; then
            echo "Generate ssl certificate using BuyPass..."
            /usr/local/acme.sh/acme.sh ${acme_sh_sudo} --server buypass --issue ${letsdomain} -w ${vhostdir} -k 2048 --days 170 --reloadcmd "${Web_Initd} reload"
        elif [ "${ssl_choice}" == "4" ]; then
            echo "Generate ssl certificate using ZeroSSL..."
            /usr/local/acme.sh/acme.sh ${acme_sh_sudo} --server zerossl --issue ${letsdomain} -w ${vhostdir} -k 2048 --reloadcmd "${Web_Initd} reload"
        fi
        lets_status=$?

        ssl_certificate="${Web_SSL_Dir}/${domain}/fullchain.cer"
        ssl_certificate_key="${Web_SSL_Dir}/${domain}/${domain}.key"
        if [ "${lets_status}" = 0 ]; then
            Create_SSL_Config
            Echo_Green " Generate SSL Certificate successfully."
        else
            Echo_Red " Generate SSL Certificate failed!"
        fi
    fi
}

Add_Dns_SSL()
{
    provider=$1
    if [ "${provider}" != "" ]; then
        dns_provider="dns_${provider}"
    else
        Echo_Red "The dns manual mode can not renew automatically, you must renew it manually."
    fi

    Add_SSL_Info_Menu
    Add_DNS_SSL_Select_Menu
    Return_301_Menu
    Install_Check_Acme.sh

    if [[ ! -s /usr/local/acme.sh/dnsapi/dns_${provider}.sh && "${provider}" != "" ]]; then
        echo "DNS Provider: ${provider} not found."
        exit 1
    fi

    if [ -s ${Web_SSL_Dir}/${domain}/fullchain.cer ]; then
        echo "Removing exist domain certificate..."
        rm -rf ${Web_SSL_Dir}/${domain}
    fi

    letsdomain=""
    if [ "${moredomain}" != "" ]; then
        letsdomain="-d ${domain}"
        for i in ${moredomain};do
            letsdomain=${letsdomain}" -d ${i}"
        done
    else
        letsdomain="-d ${domain}"
    fi

    if echo "${letsdomain}" | grep -q '\*\.' && echo "${letsdomain}" | grep -qi 'www\.'; then
        Echo_Red "wildcard SSL certificate DO NOT allow add www. subdomain."
        exit 1
    fi

    if [ "${dns_ssl_choice}" == "1" ]; then
        ca_server="letsencrypt"
    elif [ "${dns_ssl_choice}" == "2" ]; then
        ca_server="zerossl"
    fi

    echo "Generate ssl certificate using ${ca_server}..."
    if [ "${provider}" != "" ]; then
        /usr/local/acme.sh/acme.sh ${acme_sh_sudo} --server ${ca_server} --issue ${letsdomain} -k 2048 --dns ${dns_provider} --reloadcmd "${Web_Initd} reload"
        lets_status=$?
    else
        /usr/local/acme.sh/acme.sh ${acme_sh_sudo} --server ${ca_server} --issue ${letsdomain} -k 2048 --dns --yes-I-know-dns-manual-mode-enough-go-ahead-please
        Echo_Yellow "Please add the above TXT record to the domain in 120 seconds!!!"
        echo
        Sleep_Sec 120
        /usr/local/acme.sh/acme.sh ${acme_sh_sudo} --renew ${letsdomain} --yes-I-know-dns-manual-mode-enough-go-ahead-please
        lets_status=$?
    fi
    if [ "${lets_status}" = 0 ] || [[ "${provider}" = "" && "${lets_status}" = 1 && -s "${Web_SSL_Dir}/${domain}/fullchain.cer" ]]; then
        if [ ! -d "${vhostdir}" ]; then
            echo "Create Virtual Host directory......"
            mkdir -p ${vhostdir}
            echo "set permissions of Virtual Host directory......"
            chmod -R 755 ${vhostdir}
            chown -R www:www ${vhostdir}
        fi

        if [ ! -s "${Vhost_Dir}/${domain}.conf" ]; then
            Add_VHost_Config
        fi
        ssl_certificate="${Web_SSL_Dir}/${domain}/fullchain.cer"
        ssl_certificate_key="${Web_SSL_Dir}/${domain}/${domain}.key"
        Create_SSL_Config
        Echo_Blue "------------------ SSL Certificate information as follows ------------------"
        Echo_Blue "| Domain: ${domain} ${moredomain}"
        Echo_Blue "| SSL Certificate: ${Web_SSL_Dir}/${domain}/fullchain.cer"
        Echo_Blue "| SSL Certificate Key: ${Web_SSL_Dir}/${domain}/${domain}.key"
        Echo_Blue "------------------------------------ ---------------------------------------"
        Echo_Green " Generate SSL Certificate successfully."
    else
        Echo_Red " Generate SSL Certificate failed!"
    fi
}

Add_Dns_SSL_Only()
{
    provider=$1
    if [ "${provider}" != "" ]; then
        dns_provider="dns_${provider}"
    else
        Echo_Red "The dns manual mode can not renew automatically, you must renew it manually."
    fi

    Add_DNS_SSL_Only_Info_Menu
    Install_Check_Acme.sh

    if [[ ! -s /usr/local/acme.sh/dnsapi/dns_${provider}.sh && "${provider}" != "" ]]; then
        echo "DNS Provider: ${provider} not found."
        exit 1
    fi

    if [ -s ${Web_SSL_Dir}/${domain}/fullchain.cer ]; then
        echo "Removing exist domain certificate..."
        rm -rf ${Web_SSL_Dir}/${domain}
    fi

    letsdomain=""
    if [ "${moredomain}" != "" ]; then
        letsdomain="-d ${domain}"
        for i in ${moredomain};do
            letsdomain=${letsdomain}" -d ${i}"
        done
    else
        letsdomain="-d ${domain}"
    fi

    if echo "${letsdomain}" | grep -q '\*\.' && echo "${letsdomain}" | grep -qi 'www\.'; then
        Echo_Red "wildcard SSL certificate DO NOT allow add www. subdomain."
        exit 1
    fi

    if [ "${dns_ssl_choice}" == "1" ]; then
        ca_server="letsencrypt"
    elif [ "${dns_ssl_choice}" == "2" ]; then
        ca_server="zerossl"
    fi

    echo "Starting create SSL Certificate use ${ca_server}..."
    if [ "${provider}" != "" ]; then
        /usr/local/acme.sh/acme.sh ${acme_sh_sudo} --server ${ca_server} --issue ${letsdomain} -k 2048 --dns ${dns_provider} --reloadcmd "${Web_Initd} reload"
        lets_status=$?
    else
        /usr/local/acme.sh/acme.sh ${acme_sh_sudo} --server ${ca_server} --issue ${letsdomain} -k 2048 --dns --yes-I-know-dns-manual-mode-enough-go-ahead-please
        Echo_Yellow "Please add the above TXT record to the domain in 120 seconds!!!"
        echo
        Sleep_Sec 120
        /usr/local/acme.sh/acme.sh ${acme_sh_sudo} --renew ${letsdomain} --yes-I-know-dns-manual-mode-enough-go-ahead-please
        lets_status=$?
    fi
    if [ "${lets_status}" = 0 ] || [[ "${provider}" = "" && "${lets_status}" = 1 && -s "${Web_SSL_Dir}/${domain}/fullchain.cer" ]]; then
        Echo_Blue "------------------ SSL Certificate information as follows ------------------"
        Echo_Blue "| Domain: ${domain} ${moredomain}"
        Echo_Blue "| SSL Certificate: ${Web_SSL_Dir}/${domain}/fullchain.cer"
        Echo_Blue "| SSL Certificate Key: ${Web_SSL_Dir}/${domain}/${domain}.key"
        Echo_Blue "------------------------------------ ---------------------------------------"
        Echo_Green " Generate SSL Certificate successfully."
    else
        Echo_Red " Generate SSL Certificate failed!"
    fi
}

Install_Check_Acme.sh()
{
    if [ -s /usr/local/acme.sh/acme.sh ]; then
        echo "/usr/local/acme.sh/acme.sh [found]"
        if ! cat /usr/local/acme.sh/account.conf | grep -Eq "^ACCOUNT_EMAIL="; then
            /usr/local/acme.sh/acme.sh --register-account -m ${email_address}
        fi
    else
        cd /tmp
        [[ -f latest.tar.gz ]] && rm -f latest.tar.gz
        wget https://soft.lnmp.com/lib/acme.sh/latest.tar.gz -O latest.tar.gz --prefer-family=IPv4 --no-check-certificate ||         wget https://github.com/acmesh-official/acme.sh/archive/refs/heads/master.tar.gz -O latest.tar.gz --no-check-certificate
        tar zxf latest.tar.gz
        cd acme.sh-*
        ./acme.sh --install ${acme_sh_sudo} --log --home /usr/local/acme.sh --certhome ${Web_SSL_Dir} -m ${email_address}
        cd ..
        rm -f latest.tar.gz
        rm -rf acme.sh-*
        sed -i 's/cat "\$CERT_PATH"$/#cat "\$CERT_PATH"/g' /usr/local/acme.sh/acme.sh
        cat >/usr/local/acme.sh/upgrade.sh<<EOF
#!/bin/bash

. "/usr/local/acme.sh/acme.sh.env"
/usr/local/acme.sh/acme.sh --upgrade
sed -i 's/cat "\\\$CERT_PATH"\$/#cat "\\\$CERT_PATH"/g' /usr/local/acme.sh/acme.sh
sed -i 's/DEFAULT_ACCOUNT_KEY_LENGTH=ec-256/DEFAULT_ACCOUNT_KEY_LENGTH=2048/g' /usr/local/acme.sh/acme.sh
sed -i 's/DEFAULT_DOMAIN_KEY_LENGTH=ec-256/DEFAULT_DOMAIN_KEY_LENGTH=2048/g' /usr/local/acme.sh/acme.sh
EOF

        chmod +x /usr/local/acme.sh/upgrade.sh
        #if crontab -l|grep -q "/usr/local/acme.sh/upgrade.sh"; then
        #    echo "acme.sh upgrade crontab rule is exist."
        #else
        #    echo "Add acme.sh upgrade crontab rule..."
        #    (crontab -l ; echo '0 3 */7 * * /usr/local/acme.sh/upgrade.sh') | crontab -
        #fi
        if command -v yum >/dev/null 2>&1; then
            yum -y update nss
            yum -y install ca-certificates
            service crond restart
            chkconfig crond on
        elif command -v apt-get >/dev/null 2>&1; then
            /etc/init.d/cron restart
            update-rc.d cron defaults
        fi
    fi

    . "/usr/local/acme.sh/acme.sh.env"
}

Add_SSL_Menu()
{
    if [ "${info}" == "n" ]; then
        Add_SSL_Info_Menu
    fi
    echo "1: Use your own SSL Certificate and Key"
    echo "2: Use Let's Encrypt to create SSL Certificate and Key"
    echo "3: Use BuyPass to create SSL Certificate and Key"
    echo "4: Use ZeroSSL to create SSL Certificate and Key"
    while :;do
        Echo_Yellow "Enter 1, 2, 3 or 4: "
        read ssl_choice || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
        if [ "${ssl_choice}" == "1" ]; then
            while :;do
                Echo_Yellow "Please enter full path to SSL Certificate file: "
                read ssl_certificate || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
                if [ "${ssl_certificate}" == "" ]; then
                    Echo_Red "SSL Certificate file cannot be empty!"
                else
                    break
                fi
            done
            while :;do
                Echo_Yellow "Please enter full path to SSL Certificate Key file: "
                read ssl_certificate_key || { Echo_Red "读到输入结束（EOF）：本命令需要交互输入，请在终端下运行。"; exit 1; }
                if [ "${ssl_certificate_key}" == "" ]; then
                    Echo_Red "SSL Certificate Key file cannot be empty!"
                else
                    break
                fi
            done
            if [ "${Stack_Web}" = "apache" ]; then
                Echo_Yellow "Please enter full path to SSL Chain file（直接回车表示不设置）: "
                read ssl_chain
                if [ "${ssl_chain}" = "" ]; then
                    Echo_Yellow "SSL Chain file will not set."
                    Conf_SSLChain="#SSLCertificateChainFile /path/to/your/chain.pem"
                else
                    Conf_SSLChain="SSLCertificateChainFile ${ssl_chain}"
                fi
            fi
            break
        elif [[ "${ssl_choice}" =~ ^(2|3|4)$ ]]; then
            Check_Acme_EMail
            break
        else
            Echo_Red "Please Enter 1, 2, 3 or 4!"
        fi
    done

    Return_301_Menu
}
