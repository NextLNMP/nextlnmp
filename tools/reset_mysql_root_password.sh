#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script!"
    exit 1
fi

echo "+-------------------------------------------------------------------+"
echo "|   Reset MySQL/MariaDB root Password for nextLNMP, by nextLNMP team|"
echo "+-------------------------------------------------------------------+"
echo "|       A tool to reset MySQL/MariaDB root password for nextLNMP        |"
echo "+-------------------------------------------------------------------+"
echo "|       For more information please visit https://nextlnmp.com          |"
echo "+-------------------------------------------------------------------+"
echo "|           Usage: ./reset_mysql_root_password.sh                   |"
echo "+-------------------------------------------------------------------+"

if [ -s /usr/local/mariadb/bin/mysql ]; then
    DB_Name="mariadb"
    DB_Ver=`/usr/local/mariadb/bin/mysql_config --version`
elif [ -s /usr/local/mysql/bin/mysql ]; then
    DB_Name="mysql"
    DB_Ver=`/usr/local/mysql/bin/mysql_config --version`
else
    echo "MySQL/MariaDB not found!"
    exit 1
fi

while :;do
    DB_Root_Password=""
    read -p "Enter New ${DB_Name} root password: " DB_Root_Password
    if [ "${DB_Root_Password}" = "" ]; then
        echo "Error: Password can't be NULL!!"
    else
        break
    fi
done

echo "Stoping ${DB_Name}..."
/etc/init.d/${DB_Name} stop
echo "Starting ${DB_Name} with skip grant tables"
/usr/local/${DB_Name}/bin/mysqld_safe --skip-grant-tables >/dev/null 2>&1 &
sleep 5
echo "update ${DB_Name} root password..."
# MySQL 5.7/8.x（含 8.4）与 MariaDB 10.2+/11.x/12.x 均支持 ALTER USER；更老版本才走 UPDATE mysql.user
if echo "${DB_Ver}" | grep -Eqi '^8\.|^5\.7\.|^10\.([2-9]|1[0-9])\.|^1[1-9]\.'; then
    /usr/local/${DB_Name}/bin/mysql -u root << EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_Root_Password}';
EOF
else
    /usr/local/${DB_Name}/bin/mysql -u root << EOF
update mysql.user set password = Password('${DB_Root_Password}') where User = 'root';
EOF
fi

if [ $? -eq 0 ]; then
    echo "Password reset succesfully. Now killing mysqld softly"
    # MariaDB 10.5+ 的进程名是 mariadbd，两个名字都要杀，否则免密实例会一直挂着
    if command -v killall >/dev/null 2>&1; then
        killall mysqld mariadbd 2>/dev/null
    else
        kill `pidof mysqld mariadbd` 2>/dev/null
    fi
    sleep 5
    echo "Restarting the actual ${DB_Name} service"
    /etc/init.d/${DB_Name} start
    echo "Password successfully reset to '${DB_Root_Password}'"
else
    echo "Reset ${DB_Name} root password failed!"
fi
