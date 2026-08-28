#!/usr/bin/env bash

Backup_MariaDB()
{
    echo "Starting backup all databases..."
    echo "If the database is large, the backup time will be longer."
    /usr/local/mariadb/bin/mysqldump --defaults-file=~/.my.cnf --all-databases > /root/mariadb_all_backup${Upgrade_Date}.sql
    if [ $? -eq 0 ]; then
        echo "MariaDB databases backup successfully.";
    else
        echo "MariaDB databases backup failed,Please backup databases manually!"
        exit 1
    fi
    nextlnmp stop

    mv /usr/local/mariadb /usr/local/oldmariadb${Upgrade_Date}
    mv /etc/init.d/mariadb /usr/local/oldmariadb${Upgrade_Date}/init.d.mariadb.bak.${Upgrade_Date}
    mv /etc/my.cnf /usr/local/oldmariadb${Upgrade_Date}/my.cnf.mariadb.bak.${Upgrade_Date}
    if [ "${MariaDB_Data_Dir}" != "/usr/local/mariadb/var" ]; then
        mv ${MariaDB_Data_Dir} ${MariaDB_Data_Dir}${Upgrade_Date}
    fi
    if echo "${mariadb_version}" | grep -Eqi '^5.5.' &&  echo "${cur_mariadb_version}" | grep -Eqi '^10.';then
        sed -i 's/STATS_PERSISTENT=0//g' /root/mariadb_all_backup${Upgrade_Date}.sql
    fi
}

# —— CPU 兼容性实测（12c 轮真机实锤后补）——
# 11.8.8 通用包的客户端在老 CPU 上 SIGILL：服务端能跑、init 脚本的
# mysqladmin ping 每秒崩一次、systemd 90 秒超时把健康的服务杀掉、恢复
# 步骤连不上库。装机流程早有 MariaDB_Bin_Smoke_Test / MariaDB_Client_Usable
# 两道检测（按信号判定 128+N），升级流程一直没接。客户端那刀必须连上
# 活服务端才测得出，所以绕开 init/systemd 直接拉起 mariadbd 试一把。
MariaDB_Upgrade_CPU_Probe()
{
    MariaDB_Bin_Smoke_Test || return 1
    /usr/local/mariadb/bin/mysqld_safe --defaults-file=/etc/my.cnf >/dev/null 2>&1 &
    local _i _ok=n _pidf
    for _i in $(seq 1 30); do
        [ -S /tmp/mysql.sock ] && break
        sleep 1
    done
    if MariaDB_Client_Usable; then _ok=y; fi
    _pidf=$(ls ${MariaDB_Data_Dir}/*.pid 2>/dev/null | head -1)
    [ -n "${_pidf}" ] && kill "$(cat ${_pidf})" 2>/dev/null
    for _i in $(seq 1 30); do
        pgrep -x mariadbd >/dev/null 2>&1 || pgrep -x mysqld >/dev/null 2>&1 || break
        sleep 1
    done
    [ "${_ok}" = "y" ]
}

Rollback_MariaDB()
{
    # 解压/安装新版失败时调用：把 Backup_MariaDB 搬走的东西原样搬回去。
    # 此刻备份 SQL 和旧目录都完好，动作是确定性的。
    Echo_Red "开始回滚到原 MariaDB..."
    cd /
    rm -rf /usr/local/mariadb
    mv /usr/local/oldmariadb${Upgrade_Date} /usr/local/mariadb
    mv /usr/local/mariadb/init.d.mariadb.bak.${Upgrade_Date} /etc/init.d/mariadb
    mv /usr/local/mariadb/my.cnf.mariadb.bak.${Upgrade_Date} /etc/my.cnf
    if [ "${MariaDB_Data_Dir}" != "/usr/local/mariadb/var" ] && [ -d "${MariaDB_Data_Dir}${Upgrade_Date}" ]; then
        rm -rf ${MariaDB_Data_Dir}
        mv ${MariaDB_Data_Dir}${Upgrade_Date} ${MariaDB_Data_Dir}
    fi
    if [ -x /bin/nextlnmp ]; then
        /bin/nextlnmp start
    else
        /etc/init.d/mariadb start
    fi
    if /usr/local/mariadb/bin/mysql --defaults-file=~/.my.cnf -e "SELECT 1" >/dev/null 2>&1; then
        Echo_Green "回滚完成：原库已恢复运行，数据未受影响。"
    else
        Echo_Red "回滚后数据库未能启动，请手工检查："
        Echo_Red "  备份 SQL：/root/mariadb_all_backup${Upgrade_Date}.sql"
        Echo_Red "  错误日志：${MariaDB_Data_Dir}/mariadb.err"
    fi
}

Upgrade_MariaDB()
{
    Check_DB
    if [ "${Is_MySQL}" = "y" ]; then
        Echo_Red "Current database was MySQL, Can't run MariaDB upgrade script."
        exit 1
    fi

    Verify_DB_Password

    cur_mariadb_version=`/usr/local/mariadb/bin/mysql_config --version`
    mariadb_version=""
    echo "Current MariaDB Version:${cur_mariadb_version}"
    echo "You can get version number from https://downloads.mariadb.org/"
    Echo_Yellow "Please enter MariaDB Version you want."
    read -p "(example: 10.0.35 ): " mariadb_version
    if [ "${mariadb_version}" = "" ]; then
        echo "Error: You must input MariaDB Version!!"
        exit 1
    fi

    if echo "${mariadb_version}" | grep -Eqi '^10.6.';then
        if [[ "${DB_ARCH}" = "x86_64" ]]; then
            read -p "Using Generic Binaries [y/n]: " Bin
            case "${Bin}" in
            [yY][eE][sS]|[yY])
                echo "You will install mariadb-${mariadb_version} Using Generic Binaries."
                Bin="y"
                ;;
            [nN][oO]|[nN])
                echo "You will install mariadb-${mariadb_version} from Source."
                Bin="n"
                ;;
            *)
                echo "You will install mariadb-${mariadb_version} Using Generic Binaries."
                Bin="y"
                ;;
            esac
        else
            Bin="n"
        fi
    else
        if [[ "${DB_ARCH}" = "x86_64" || "${DB_ARCH}" = "i686" ]]; then
            read -p "Using Generic Binaries [y/n]: " Bin
            case "${Bin}" in
            [yY][eE][sS]|[yY])
                echo "You will install mariadb-${mariadb_version} Using Generic Binaries."
                Bin="y"
                ;;
            [nN][oO]|[nN])
                echo "You will install mariadb-${mariadb_version} from Source."
                Bin="n"
                ;;
            *)
                echo "You will install mariadb-${mariadb_version} Using Generic Binaries."
                Bin="y"
                ;;
            esac
        else
            Bin="n"
        fi
    fi

    #do you want to install the InnoDB Storage Engine?
    echo "==========================="

    InstallInnodb="y"
    Echo_Yellow "Do you want to install the InnoDB Storage Engine?"
    read -p "(Default yes, if you want please enter: y , if not please enter: n): " InstallInnodb

    case "${InstallInnodb}" in
    [yY][eE][sS]|[yY])
        echo "You will install the InnoDB Storage Engine"
        InstallInnodb="y"
        ;;
    [nN][oO]|[nN])
        echo "You will NOT install the InnoDB Storage Engine!"
        InstallInnodb="n"
        ;;
    *)
        echo "No input, The InnoDB Storage Engine will enable."
        InstallInnodb="y"
    esac

    echo "====================================================================="
    echo "You will upgrade MariaDB V${cur_mariadb_version} to V${mariadb_version}"
    echo "====================================================================="

    if [ -s /usr/local/include/jemalloc/jemalloc.h ] && lsof -n|grep "libjemalloc.so"|grep -q "mysqld"; then
        MariaDBMAOpt=''
    elif [ -s /usr/local/include/gperftools/tcmalloc.h ] && lsof -n|grep "libtcmalloc.so"|grep -q "mysqld"; then
        MariaDBMAOpt="-DCMAKE_EXE_LINKER_FLAGS='-ltcmalloc' -DWITH_SAFEMALLOC=OFF"
    else
        MariaDBMAOpt=''
    fi

    Press_Start

    echo "============================check files=================================="
    cd ${cur_dir}/src
    if [ "${Bin}" = "y" ]; then
        MariaDB_FileName="mariadb-${mariadb_version}-linux-systemd-${DB_ARCH}"
    else
        MariaDB_FileName="mariadb-${mariadb_version}"
    fi
    if [ -s ${MariaDB_FileName}.tar.gz ]; then
        echo "${MariaDB_FileName}.tar.gz [found]"
    else
        echo "Notice: ${MariaDB_FileName}.tar.gz not found!!!download now......"
        if [ "${MariaDB_FileName}" = "mariadb-${mariadb_version}" ]; then
            MariaDB_Archive_Sub="source"
        else
            MariaDB_Archive_Sub="bintar-linux-systemd-${DB_ARCH}"
        fi
        Try_Download https://downloads.mariadb.org/rest-api/mariadb/${mariadb_version}/${MariaDB_FileName}.tar.gz ${MariaDB_FileName}.tar.gz || \
        Try_Download https://archive.mariadb.org/mariadb-${mariadb_version}/${MariaDB_Archive_Sub}/${MariaDB_FileName}.tar.gz ${MariaDB_FileName}.tar.gz
        if [ $? -eq 0 ]; then
            echo "Download ${MariaDB_FileName}.tar.gz successfully!"
        else
            echo "You enter MariaDB Version was:"${mariadb_version}
            Echo_Red "Error! You entered a wrong version number or can't download from mariadb mirror, please check!"
            sleep 5
            exit 1
        fi
    fi
    echo "============================check files=================================="

    if [ "${Bin}" = "y" ]; then
        Upgrade_Disk_Preflight "${MariaDB_FileName}.tar.gz" "${MariaDB_Data_Dir}" 512
    else
        Upgrade_Disk_Preflight "${MariaDB_FileName}.tar.gz" "${MariaDB_Data_Dir}" 3072
    fi

    Backup_MariaDB

    if [ "${Bin}" = "y" ]; then
        Echo_Blue "[+] Starting upgrade mariadb-${mariadb_version} Using Generic Binaries..."
        Tar_Cd ${MariaDB_FileName}.tar.gz || { Rollback_MariaDB; exit 1; }
        mkdir /usr/local/mariadb
        mv ${MariaDB_FileName}/* /usr/local/mariadb/
        if [ ! -x /usr/local/mariadb/bin/mariadbd ] && [ ! -x /usr/local/mariadb/bin/mysqld ]; then
            Echo_Red "新版文件不完整（没有服务端二进制）"
            Rollback_MariaDB; exit 1
        fi
    else
        Echo_Blue "[+] Starting upgrade mariadb-${mariadb_version} Using Source code..."
        Tar_Cd mariadb-${mariadb_version}.tar.gz mariadb-${mariadb_version} || { Rollback_MariaDB; exit 1; }
        MariaDB_WITHSSL
        if echo "${mariadb_version}" | grep -Eq '^(10\.([5-9]|1[0-9])\.|1[1-9]\.)';then
            cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mariadb -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_READLINE=1 -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 -DWITHOUT_TOKUDB=1
        elif echo "${mariadb_version}" | grep -Eqi '^10.4.';then
            patch -p1 < ${cur_dir}/src/patch/mariadb_10.4_install_db.patch
            cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mariadb -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_READLINE=1 -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 -DWITHOUT_TOKUDB=1
        elif echo "${mariadb_version}" | grep -Eqi '^10.[123].';then
            cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mariadb -DWITH_ARIA_STORAGE_ENGINE=1 -DWITH_XTRADB_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_READLINE=1 -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 -DWITHOUT_TOKUDB=1 ${MariaDBWITHSSL}
        else
            cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mariadb -DWITH_ARIA_STORAGE_ENGINE=1 -DWITH_XTRADB_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_READLINE=1 -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 ${MariaDBWITHSSL}
        fi
        Make_Install
    fi

    groupadd mariadb
    useradd -s /sbin/nologin -M -g mariadb mariadb

cat > /etc/my.cnf<<EOF
[client]
#password	= your_password
port		= 3306
socket		= /tmp/mysql.sock

[mysqld]
port		= 3306
socket		= /tmp/mysql.sock
user    = mariadb
basedir = /usr/local/mariadb
datadir = ${MariaDB_Data_Dir}
log_error = ${MariaDB_Data_Dir}/mariadb.err
pid-file = ${MariaDB_Data_Dir}/mariadb.pid
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
thread_cache_size = 8
query_cache_size = 8M
tmp_table_size = 16M

#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535

log-bin=mysql-bin
binlog_format=mixed
server-id	= 1
expire_logs_days = 10

default_storage_engine = InnoDB
#innodb_file_per_table = 1
#innodb_data_home_dir = ${MariaDB_Data_Dir}
#innodb_data_file_path = ibdata1:10M:autoextend
#innodb_log_group_home_dir = ${MariaDB_Data_Dir}
#innodb_buffer_pool_size = 16M
#innodb_log_file_size = 5M
#innodb_log_buffer_size = 8M
#innodb_flush_log_at_trx_commit = 1
#innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout

${MySQLMAOpt}
EOF
    if [ "${InstallInnodb}" = "y" ]; then
        sed -i 's/^#innodb/innodb/g' /etc/my.cnf
    else
        sed -i '/^default_storage_engine/d' /etc/my.cnf
        sed -i '/skip-external-locking/i\default_storage_engine = MyISAM\nloose-skip-innodb' /etc/my.cnf
    fi
    MySQL_Opt
    if [ -d "${MariaDB_Data_Dir}" ]; then
        rm -rf ${MariaDB_Data_Dir}/*
    else
        mkdir -p ${MariaDB_Data_Dir}
    fi
    chown -R mariadb:mariadb /usr/local/mariadb
    /usr/local/mariadb/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mariadb --datadir=${MariaDB_Data_Dir} --user=mariadb
    chown -R mariadb:mariadb ${MariaDB_Data_Dir}
    \cp /usr/local/mariadb/support-files/mysql.server /etc/init.d/mariadb
    chmod 755 /etc/init.d/mariadb

    if ! MariaDB_Upgrade_CPU_Probe; then
        Rollback_MariaDB; exit 1
    fi

    Mariadb_Sec_Setting
    /etc/init.d/mariadb start

    echo "Restore backup databases..."
    # 这是整个升级里最关键的一步。原来返回值完全不判，而收尾只看三个文件在不在，
    # 于是恢复失败也照样打印绿色 "upgrade completed"——用户以为升级成功，
    # 实际数据一条都没回来，而且不会有人再去看那个备份文件。
    /usr/local/mariadb/bin/mysql --defaults-file=~/.my.cnf < /root/mariadb_all_backup${Upgrade_Date}.sql || {
        Echo_Red "恢复备份失败！数据尚未导入新库。"
        Echo_Red "备份仍在，请勿删除："
        Echo_Red "  SQL  ：/root/mariadb_all_backup${Upgrade_Date}.sql"
        Echo_Red "  原目录：/usr/local/oldmariadb${Upgrade_Date}"
        Echo_Red "现在自动回滚到原版本。"
        Rollback_MariaDB
        exit 1
    }
    echo "Repair databases..."
    # 不把密码放到命令行上：ps 是全机可见的，同机任何用户在这条命令跑着的
    # 几秒里 ps aux 一眼就能看到 root 密码；而且 -p${var} 没加引号，密码含
    # 空格或 * ? [ ] 时还会被分词/通配掉，报"密码错误"却查不出原因。
    # 同一批脚本里其它调用早就在用 --defaults-file=~/.my.cnf（Make_TempMycnf
    # 已经生成好），这里跟上。
    /usr/local/mariadb/bin/mysql_upgrade --defaults-file=~/.my.cnf

    /etc/init.d/mariadb stop
    TempMycnf_Clean
    cd ${cur_dir} && rm -rf ${cur_dir}/src/mariadb-${mariadb_version}

    nextlnmp start
    if [[ -s /usr/local/mariadb/bin/mysql && -s /usr/local/mariadb/bin/mysqld_safe && -s /etc/my.cnf ]]; then
        Echo_Green "======== upgrade MariaDB completed ======"
    else
        Echo_Red "======== upgrade MariaDB failed ======"
        Echo_Red "upgrade MariaDB log: /root/upgrade_mariadb${Upgrade_Date}.log"
        echo "You upload upgrade_mariadb${Upgrade_Date}.log to nextLNMP Forum for help."
    fi
}
