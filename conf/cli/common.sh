# ===== NextLNMP CLI 公共函数库（由 tools/build-cli.sh 拼装，勿直接编辑生成物）=====

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

Do_Query()
{
    echo "$1" >/tmp/.mysql.tmp
    chmod 600 /tmp/.mysql.tmp
    Check_DB
    ${MySQL_Bin} --defaults-file=~/.my.cnf </tmp/.mysql.tmp
    return $?
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

Enter_Database_Name()
{
    while :;do
        Echo_Yellow "Enter database name: "
        read database_name
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
        read ftp_account_name
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
        read ftp_account_password
        if [ "${ftp_account_password}" == "" ]; then
            Echo_Red "FTP password can't be empty!"
        else
            break
        fi
    done
    if [ "${vhostdir}" == "" ]; then
        while :;do
            Echo_Yellow "Enter directory for ftp account ${ftp_account_name}: "
            read vhostdir
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
        read dns_ssl_choice
        if [[ "${dns_ssl_choice}" =~ ^1|2$ ]]; then
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
        read domain
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
