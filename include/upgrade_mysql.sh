#!/usr/bin/env bash

Backup_MySQL()
{
    echo "Starting backup all databases..."
    echo "If the database is large, the backup time will be longer."
    /usr/local/mysql/bin/mysqldump --defaults-file=~/.my.cnf --all-databases > /root/mysql_all_backup${Upgrade_Date}.sql
    if [ $? -eq 0 ]; then
        echo "MySQL databases backup successfully.";
    else
        echo "MySQL databases backup failed,Please backup databases manually!"
        exit 1
    fi
    nextlnmp stop
    mv /usr/local/mysql /usr/local/oldmysql${Upgrade_Date}
    mv /etc/init.d/mysql /usr/local/oldmysql${Upgrade_Date}/init.d.mysql.bak.${Upgrade_Date}
    mv /etc/my.cnf /usr/local/oldmysql${Upgrade_Date}/my.cnf.bak.${Upgrade_Date}
    if [ "${MySQL_Data_Dir}" != "/usr/local/mysql/var" ]; then
        mv ${MySQL_Data_Dir} ${MySQL_Data_Dir}${Upgrade_Date}
    fi
    if echo "${mysql_version}" | grep -Eqi '^5.5.' &&  echo "${cur_mysql_version}" | grep -Eqi '^5.6.';then
        sed -i 's/STATS_PERSISTENT=0//g' /root/mysql_all_backup${Upgrade_Date}.sql
    fi
}

Rollback_MySQL()
{
    # 解压/安装新版失败时调用：把 Backup_MySQL 搬走的东西原样搬回去。
    Echo_Red "开始回滚到原 MySQL..."
    cd /
    rm -rf /usr/local/mysql
    mv /usr/local/oldmysql${Upgrade_Date} /usr/local/mysql
    mv /usr/local/mysql/init.d.mysql.bak.${Upgrade_Date} /etc/init.d/mysql
    mv /usr/local/mysql/my.cnf.bak.${Upgrade_Date} /etc/my.cnf
    if [ "${MySQL_Data_Dir}" != "/usr/local/mysql/var" ] && [ -d "${MySQL_Data_Dir}${Upgrade_Date}" ]; then
        rm -rf ${MySQL_Data_Dir}
        mv ${MySQL_Data_Dir}${Upgrade_Date} ${MySQL_Data_Dir}
    fi
    if [ -x /bin/nextlnmp ]; then
        /bin/nextlnmp start
    else
        /etc/init.d/mysql start
    fi
    if /usr/local/mysql/bin/mysql --defaults-file=~/.my.cnf -e "SELECT 1" >/dev/null 2>&1; then
        Echo_Green "回滚完成：原库已恢复运行，数据未受影响。"
    else
        Echo_Red "回滚后数据库未能启动，请手工检查："
        Echo_Red "  备份 SQL：/root/mysql_all_backup${Upgrade_Date}.sql"
    fi
}

Upgrade_MySQL51()
{
    Tar_Cd mysql-${mysql_version}.tar.gz mysql-${mysql_version} || { Rollback_MySQL; exit 1; }
    MySQL_Gcc7_Patch
    if [ $InstallInnodb = "y" ]; then
        ./configure --prefix=/usr/local/mysql --with-extra-charsets=complex --enable-thread-safe-client --enable-assembler --with-mysqld-ldflags=-all-static --with-charset=utf8 --enable-thread-safe-client --with-big-tables --with-readline --with-ssl --with-embedded-server --enable-local-infile --with-plugins=innobase ${MySQL51MAOpt}
    else
        ./configure --prefix=/usr/local/mysql --with-extra-charsets=complex --enable-thread-safe-client --enable-assembler --with-mysqld-ldflags=-all-static --with-charset=utf8 --enable-thread-safe-client --with-big-tables --with-readline --with-ssl --with-embedded-server --enable-local-infile ${MySQL51MAOpt}
    fi
    sed -i '/set -ex;/,/done/d' Makefile
    Make_Install

    groupadd mysql
    useradd -s /sbin/nologin -M -g mysql mysql

cat > /etc/my.cnf<<EOF
[client]
#password	= your_password
port		= 3306
socket		= /tmp/mysql.sock

[mysqld]
port		= 3306
socket		= /tmp/mysql.sock
datadir = ${MySQL_Data_Dir}
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
#innodb_data_home_dir = ${MySQL_Data_Dir}
#innodb_data_file_path = ibdata1:10M:autoextend
#innodb_log_group_home_dir = ${MySQL_Data_Dir}
#innodb_buffer_pool_size = 16M
#innodb_additional_mem_pool_size = 2M
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
EOF
    if [ "${InstallInnodb}" = "y" ]; then
        sed -i 's/^#innodb/innodb/g' /etc/my.cnf
    else
        sed -i '/^default_storage_engine/d' /etc/my.cnf
        sed -i '/skip-external-locking/i\default_storage_engine = MyISAM\nloose-skip-innodb' /etc/my.cnf
    fi
    MySQL_Opt
    if [ -d "${MySQL_Data_Dir}" ]; then
        rm -rf ${MySQL_Data_Dir}/*
    else
        mkdir -p ${MySQL_Data_Dir}
    fi
    chown -R mysql:mysql ${MySQL_Data_Dir}
    /usr/local/mysql/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=${MySQL_Data_Dir} --user=mysql

    cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib
/usr/local/lib
EOF
    ldconfig
    ln -sf /usr/local/mysql/lib/mysql /usr/lib/mysql
    ln -sf /usr/local/mysql/include/mysql /usr/include/mysql
}

Upgrade_MySQL55()
{
    if [ "${Bin}" = "y" ]; then
        Echo_Blue "Starting upgrade MySQL ${mysql_version} Using Generic Binaries..."
        Tar_Cd ${mysql_src} || { Rollback_MySQL; exit 1; }
        mkdir /usr/local/mysql
        mv mysql-${mysql_version}-linux-glibc2.12-${DB_ARCH}/* /usr/local/mysql/
    else
        Echo_Blue "Starting upgrade MySQL ${mysql_version} Using Source code..."
        if [ "${isOpenSSL3}" = "y" ]; then
            MySQL_WITH_SSL='-DWITH_SSL=bundled'
        else
            MySQL_WITH_SSL=''
        fi
        Tar_Cd mysql-${mysql_version}.tar.gz mysql-${mysql_version} || { Rollback_MySQL; exit 1; }
        MySQL_ARM_Patch
        if  g++ -dM -E -x c++ /dev/null | grep -F __cplusplus | cut -d' ' -f3 | grep -Eqi "^2017|202[0-9]"; then
            sed -i '1s/^/set(CMAKE_CXX_STANDARD 11)\n/' CMakeLists.txt
        fi
        if echo "${Rocky_Version}" | grep -Eqi "^9"; then
            sed -i 's@^INCLUDE(cmake/abi_check.cmake)@#INCLUDE(cmake/abi_check.cmake)@' CMakeLists.txt
        fi
        cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DSYSCONFDIR=/etc -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_READLINE=1 -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 ${MySQL_WITH_SSL}
        Make_Install
    fi

    groupadd mysql
    useradd -s /sbin/nologin -M -g mysql mysql

    cat > /etc/my.cnf<<EOF
[client]
#password	= your_password
port		= 3306
socket		= /tmp/mysql.sock

[mysqld]
port		= 3306
socket		= /tmp/mysql.sock
datadir = ${MySQL_Data_Dir}
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
#innodb_data_home_dir = ${MySQL_Data_Dir}
#innodb_data_file_path = ibdata1:10M:autoextend
#innodb_log_group_home_dir = ${MySQL_Data_Dir}
#innodb_buffer_pool_size = 16M
#innodb_additional_mem_pool_size = 2M
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
    if [ -d "${MySQL_Data_Dir}" ]; then
        rm -rf ${MySQL_Data_Dir}/*
    else
        mkdir -p ${MySQL_Data_Dir}
    fi
    chown -R mysql:mysql ${MySQL_Data_Dir}
    /usr/local/mysql/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=${MySQL_Data_Dir} --user=mysql

    cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib
/usr/local/lib
EOF
    ldconfig
    ln -sf /usr/local/mysql/lib/mysql /usr/lib/mysql
    ln -sf /usr/local/mysql/include/mysql /usr/include/mysql
}

Upgrade_MySQL56()
{
    if [ "${Bin}" = "y" ]; then
        Echo_Blue "Starting upgrade MySQL ${mysql_version} Using Generic Binaries..."
        Tar_Cd ${mysql_src} || { Rollback_MySQL; exit 1; }
        mkdir /usr/local/mysql
        mv mysql-${mysql_version}-linux-glibc2.12-${DB_ARCH}/* /usr/local/mysql/
    else
        Echo_Blue "Starting upgrade MySQL ${mysql_version} Using Source code..."
        if [ "${isOpenSSL3}" = "y" ]; then
            Install_Openssl_New
            MySQL_WITH_SSL='-DWITH_SSL=/usr/local/openssl1.1.1'
        else
            MySQL_WITH_SSL=''
        fi
        Tar_Cd mysql-${mysql_version}.tar.gz mysql-${mysql_version} || { Rollback_MySQL; exit 1; }
        if  g++ -dM -E -x c++ /dev/null | grep -F __cplusplus | cut -d' ' -f3 | grep -Eqi "^2017|202[0-9]"; then
            sed -i '1s/^/set(CMAKE_CXX_STANDARD 11)\n/' CMakeLists.txt
        fi
        if echo "${Rocky_Version}" | grep -Eqi "^9"; then
            sed -i 's@^INCLUDE(cmake/abi_check.cmake)@#INCLUDE(cmake/abi_check.cmake)@' CMakeLists.txt
        fi
        cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DSYSCONFDIR=/etc -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 ${MySQL_WITH_SSL}
        Make_Install
    fi

    groupadd mysql
    useradd -s /sbin/nologin -M -g mysql mysql

cat > /etc/my.cnf<<EOF
[client]
#password   = your_password
port        = 3306
socket      = /tmp/mysql.sock

[mysqld]
port        = 3306
socket      = /tmp/mysql.sock
datadir = ${MySQL_Data_Dir}
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
performance_schema_max_table_instances = 500

explicit_defaults_for_timestamp = true
#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535

log-bin=mysql-bin
binlog_format=mixed
server-id   = 1
expire_logs_days = 10

#loose-innodb-trx=0
#loose-innodb-locks=0
#loose-innodb-lock-waits=0
#loose-innodb-cmp=0
#loose-innodb-cmp-per-index=0
#loose-innodb-cmp-per-index-reset=0
#loose-innodb-cmp-reset=0
#loose-innodb-cmpmem=0
#loose-innodb-cmpmem-reset=0
#loose-innodb-buffer-page=0
#loose-innodb-buffer-page-lru=0
#loose-innodb-buffer-pool-stats=0
#loose-innodb-metrics=0
#loose-innodb-ft-default-stopword=0
#loose-innodb-ft-inserted=0
#loose-innodb-ft-deleted=0
#loose-innodb-ft-being-deleted=0
#loose-innodb-ft-config=0
#loose-innodb-ft-index-cache=0
#loose-innodb-ft-index-table=0
#loose-innodb-sys-tables=0
#loose-innodb-sys-tablestats=0
#loose-innodb-sys-indexes=0
#loose-innodb-sys-columns=0
#loose-innodb-sys-fields=0
#loose-innodb-sys-foreign=0
#loose-innodb-sys-foreign-cols=0

default_storage_engine = InnoDB
#innodb_data_home_dir = ${MySQL_Data_Dir}
#innodb_data_file_path = ibdata1:10M:autoextend
#innodb_log_group_home_dir = ${MySQL_Data_Dir}
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
        sed -i '/skip-external-locking/i\innodb = OFF\nignore-builtin-innodb\nskip-innodb\ndefault_storage_engine = MyISAM\ndefault_tmp_storage_engine = MyISAM' /etc/my.cnf
        sed -i 's/^#loose-innodb/loose-innodb/g' /etc/my.cnf
    fi
    MySQL_Opt
    if [ -d "${MySQL_Data_Dir}" ]; then
        rm -rf ${MySQL_Data_Dir}/*
    else
        mkdir -p ${MySQL_Data_Dir}
    fi
    chown -R mysql:mysql ${MySQL_Data_Dir}
    /usr/local/mysql/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=${MySQL_Data_Dir} --user=mysql

    cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib
/usr/local/lib
EOF

    ldconfig
    ln -sf /usr/local/mysql/lib/mysql /usr/lib/mysql
    ln -sf /usr/local/mysql/include/mysql /usr/include/mysql
}

Upgrade_MySQL57()
{
    if [ "${Bin}" = "y" ]; then
        Echo_Blue "Starting upgrade MySQL ${mysql_version} Using Generic Binaries..."
        Tar_Cd ${mysql_src} || { Rollback_MySQL; exit 1; }
        mkdir /usr/local/mysql
        mv mysql-${mysql_version}-linux-glibc2.12-${DB_ARCH}/* /usr/local/mysql/
    else
        Echo_Blue "Starting upgrade MySQL ${mysql_version} Using Source code..."
        if [ "${isOpenSSL3}" = "y" ]; then
            Install_Openssl_New
            MySQL_WITH_SSL='-DWITH_SSL=/usr/local/openssl1.1.1'
        else
            MySQL_WITH_SSL=''
        fi
        Tar_Cd ${mysql_src} mysql-${mysql_version} || { Rollback_MySQL; exit 1; }
        Install_Boost
        if echo "${Rocky_Version}" | grep -Eqi "^9"; then
            sed -i 's@^INCLUDE(cmake/abi_check.cmake)@#INCLUDE(cmake/abi_check.cmake)@' CMakeLists.txt
        fi
        cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DSYSCONFDIR=/etc -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 ${MySQL_WITH_SSL} ${MySQL_WITH_BOOST}
        Make_Install
    fi

    groupadd mysql
    useradd -s /sbin/nologin -M -g mysql mysql

cat > /etc/my.cnf<<EOF
[client]
#password   = your_password
port        = 3306
socket      = /tmp/mysql.sock

[mysqld]
port        = 3306
socket      = /tmp/mysql.sock
datadir = ${MySQL_Data_Dir}
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
performance_schema_max_table_instances = 500

explicit_defaults_for_timestamp = true
#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535

log-bin=mysql-bin
binlog_format=mixed
server-id   = 1
expire_logs_days = 10
early-plugin-load = ""

default_storage_engine = InnoDB
innodb_data_home_dir = ${MySQL_Data_Dir}
innodb_data_file_path = ibdata1:10M:autoextend
innodb_log_group_home_dir = ${MySQL_Data_Dir}
innodb_buffer_pool_size = 16M
innodb_log_file_size = 5M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer_size = 2M
write_buffer_size = 2M

[mysqlhotcopy]
interactive-timeout

${MySQLMAOpt}
EOF

    MySQL_Opt
    if [ -d "${MySQL_Data_Dir}" ]; then
        rm -rf ${MySQL_Data_Dir}/*
    else
        mkdir -p ${MySQL_Data_Dir}
    fi
    chown -R mysql:mysql /usr/local/mysql/
    /usr/local/mysql/bin/mysqld --initialize-insecure --basedir=/usr/local/mysql --datadir=${MySQL_Data_Dir} --user=mysql
    chown -R mysql:mysql ${MySQL_Data_Dir}

    cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib
/usr/local/lib
EOF

    ldconfig
    ln -sf /usr/local/mysql/lib/mysql /usr/lib/mysql
    ln -sf /usr/local/mysql/include/mysql /usr/include/mysql
}

Upgrade_MySQL80()
{
    if [ "${Bin}" = "y" ]; then
        Echo_Blue "Starting upgrade MySQL ${mysql_version} Using Generic Binaries..."
        Tar_Cd ${mysql_src} || { Rollback_MySQL; exit 1; }
        mkdir /usr/local/mysql
        mv mysql-${mysql_version}-linux-glibc${mysql8_glibc_ver}-${DB_ARCH}/* /usr/local/mysql/
    else
        Echo_Blue "Starting upgrade MySQL ${mysql_version} Using Source code..."
        Tar_Cd ${mysql_src} mysql-${mysql_version} || { Rollback_MySQL; exit 1; }
        Install_Boost
        mkdir build && cd build
        cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DSYSCONFDIR=/etc -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 ${MySQL_WITH_BOOST}
        Make_Install
    fi

    groupadd mysql
    useradd -s /sbin/nologin -M -g mysql mysql

cat > /etc/my.cnf<<EOF
[client]
#password   = your_password
port        = 3306
socket      = /tmp/mysql.sock

[mysqld]
port        = 3306
socket      = /tmp/mysql.sock
datadir = ${MySQL_Data_Dir}
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
tmp_table_size = 16M
performance_schema_max_table_instances = 500

explicit_defaults_for_timestamp = true
#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535
default_authentication_plugin = mysql_native_password

log-bin=mysql-bin
binlog_format=mixed
server-id   = 1
binlog_expire_logs_seconds = 864000
early-plugin-load = ""

default_storage_engine = InnoDB
innodb_data_home_dir = ${MySQL_Data_Dir}
innodb_data_file_path = ibdata1:10M:autoextend
innodb_log_group_home_dir = ${MySQL_Data_Dir}
innodb_buffer_pool_size = 16M
innodb_log_file_size = 5M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer_size = 2M
write_buffer_size = 2M

[mysqlhotcopy]
interactive-timeout

${MySQLMAOpt}
EOF

    MySQL_Opt
    if [ -d "${MySQL_Data_Dir}" ]; then
        rm -rf ${MySQL_Data_Dir}/*
    else
        mkdir -p ${MySQL_Data_Dir}
    fi
    chown -R mysql:mysql /usr/local/mysql/
    /usr/local/mysql/bin/mysqld --initialize-insecure --basedir=/usr/local/mysql --datadir=${MySQL_Data_Dir} --user=mysql
    chown -R mysql:mysql ${MySQL_Data_Dir}

    cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib
/usr/local/lib
EOF

    ldconfig
    ln -sf /usr/local/mysql/lib/mysql /usr/lib/mysql
    ln -sf /usr/local/mysql/include/mysql /usr/include/mysql
}

Upgrade_MySQL84()
{
    if [ "${Bin}" = "y" ]; then
        Echo_Blue "Starting upgrade MySQL ${mysql_version} Using Generic Binaries..."
        Tar_Cd ${mysql_src} || { Rollback_MySQL; exit 1; }
        mkdir /usr/local/mysql
        mv ${mysql_src%.tar.xz}/* /usr/local/mysql/
    else
        Echo_Blue "Starting upgrade MySQL ${mysql_version} Using Source code..."
        Tar_Cd ${mysql_src} mysql-${mysql_version} || { Rollback_MySQL; exit 1; }
        Install_Boost
        mkdir build && cd build
        cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DSYSCONFDIR=/etc -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 ${MySQL_WITH_BOOST}
        Make_Install
    fi

    groupadd mysql
    useradd -s /sbin/nologin -M -g mysql mysql

cat > /etc/my.cnf<<EOF
[client]
#password   = your_password
port        = 3306
socket      = /tmp/mysql.sock

[mysqld]
port        = 3306
socket      = /tmp/mysql.sock
datadir = ${MySQL_Data_Dir}
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
tmp_table_size = 16M
performance_schema_max_table_instances = 500

explicit_defaults_for_timestamp = true
#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535
mysql_native_password=ON

log-bin=mysql-bin
binlog_format=mixed
server-id   = 1
binlog_expire_logs_seconds = 864000
early-plugin-load = ""

default_storage_engine = InnoDB
innodb_data_home_dir = ${MySQL_Data_Dir}
innodb_data_file_path = ibdata1:10M:autoextend
innodb_log_group_home_dir = ${MySQL_Data_Dir}
innodb_buffer_pool_size = 16M
innodb_log_file_size = 5M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer_size = 2M
write_buffer_size = 2M

[mysqlhotcopy]
interactive-timeout

${MySQLMAOpt}
EOF

    MySQL_Opt
    if [ -d "${MySQL_Data_Dir}" ]; then
        rm -rf ${MySQL_Data_Dir}/*
    else
        mkdir -p ${MySQL_Data_Dir}
    fi
    chown -R mysql:mysql /usr/local/mysql/
    /usr/local/mysql/bin/mysqld --initialize-insecure --basedir=/usr/local/mysql --datadir=${MySQL_Data_Dir} --user=mysql
    chown -R mysql:mysql ${MySQL_Data_Dir}

    cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib
/usr/local/lib
EOF

    ldconfig
    ln -sf /usr/local/mysql/lib/mysql /usr/lib/mysql
    ln -sf /usr/local/mysql/include/mysql /usr/include/mysql
}

Restore_Start_MySQL()
{
    chgrp -R mysql /usr/local/mysql/.
    \cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
    chmod 755 /etc/init.d/mysql

    ldconfig

    MySQL_Sec_Setting
    /etc/init.d/mysql start

    echo "Restore backup databases..."
    # 这是整个升级里最关键的一步。原来返回值完全不判，而收尾只看三个文件在不在，
    # 于是恢复失败也照样打印绿色 "upgrade completed"——用户以为升级成功，
    # 实际数据一条都没回来，而且不会有人再去看那个备份文件。
    /usr/local/mysql/bin/mysql --defaults-file=~/.my.cnf < /root/mysql_all_backup${Upgrade_Date}.sql || {
        Echo_Red "恢复备份失败！数据尚未导入新库。"
        Echo_Red "备份仍在，请勿删除："
        Echo_Red "  SQL  ：/root/mysql_all_backup${Upgrade_Date}.sql"
        Echo_Red "  原目录：/usr/local/oldmysql${Upgrade_Date}"
        Echo_Red "可先修复问题后手工导入，或把原目录搬回去回滚。"
        exit 1
    }
    echo "Repair databases..."
    MySQL_Ver_Com=$(${cur_dir}/include/version_compare 8.0.16 ${mysql_version})
    if [ "${MySQL_Ver_Com}" != "1" ]; then
        /etc/init.d/mysql stop
        echo "Upgring MySQL..."
        /usr/local/mysql/bin/mysqld --user=mysql --upgrade=FORCE &
        echo "Waiting for upgrade to start..."
        sleep 180
        /usr/local/mysql/bin/mysqladmin --defaults-file=~/.my.cnf shutdown
    else
        # 不把密码放到命令行上：ps 是全机可见的，同机任何用户在这条命令跑着的
        # 几秒里 ps aux 一眼就能看到 root 密码；而且 -p${var} 没加引号，密码含
        # 空格或 * ? [ ] 时还会被分词/通配掉，报"密码错误"却查不出原因。
        # 同一批脚本里其它调用早就在用 --defaults-file=~/.my.cnf（Make_TempMycnf
        # 已经生成好），这里跟上。
        /usr/local/mysql/bin/mysql_upgrade --defaults-file=~/.my.cnf
    fi

    /etc/init.d/mysql stop
    TempMycnf_Clean
    cd ${cur_dir} && rm -rf ${cur_dir}/src/mysql-${mysql_version}

    nextlnmp start
    if [[ -s /usr/local/mysql/bin/mysql && -s /usr/local/mysql/bin/mysqld_safe && -s /etc/my.cnf ]]; then
        Echo_Green "======== upgrade MySQL completed ======"
    else
        Echo_Red "======== upgrade MySQL failed ======"
        Echo_Red "upgrade MySQL log: /root/upgrade_mysq${Upgrade_Date}.log"
        echo "You upload upgrade_mysq${Upgrade_Date}.log to nextLNMP Forum for help."
    fi
}

Upgrade_MySQL()
{
    Check_DB
    if [ "${Is_MySQL}" = "n" ]; then
        Echo_Red "Current database was MariaDB, Can't run MySQL upgrade script."
        exit 1
    fi

    Verify_DB_Password

    cur_mysql_version=`/usr/local/mysql/bin/mysql_config --version`
    mysql_version=""
    echo "Current MYSQL Version:${cur_mysql_version}"
    echo "You can get version number from http://dev.mysql.com/downloads/mysql/"
    Echo_Yellow "Please input MySQL Version you want."
    read -p "(example: 5.5.60 ): " mysql_version
    if [ "${mysql_version}" = "" ]; then
        echo "Error: You must input MySQL Version!!"
        exit 1
    fi

    if [ "${mysql_version}" == "${cur_mysql_version}" ]; then
        echo "Error: The upgrade MYSQL Version is the same as the old Version!!"
        exit 1
    fi

    if [[ "${DB_ARCH}" = "x86_64" || "${DB_ARCH}" = "i686" ]] && echo "${mysql_version}" | grep -Eqi '^5.[5-7].';then
        read -p "Using Generic Binaries [y/n]: " Bin
        case "${Bin}" in
        [yY][eE][sS]|[yY])
            echo "You will install MySQL ${mysql_version} Using Generic Binaries."
            Bin="y"
            ;;
        [nN][oO]|[nN])
            echo "You will install MySQL ${mysql_version} Source code."
            Bin="n"
            ;;
        *)
            echo "Default install MySQL ${mysql_version} Using Generic Binaries."
            Bin="y"
            ;;
        esac
    elif [[ "${DB_ARCH}" = "x86_64" || "${DB_ARCH}" = "i686" || "${DB_ARCH}" = "aarch64" ]] && echo "${mysql_version}" | grep -Eqi '^8.';then
        read -p "Using Generic Binaries [y/n]: " Bin
        case "${Bin}" in
        [yY][eE][sS]|[yY])
            echo "You will install MySQL ${mysql_version} Using Generic Binaries."
            Bin="y"
            ;;
        [nN][oO]|[nN])
            echo "You will install MySQL ${mysql_version} Source code."
            Bin="n"
            ;;
        *)
            echo "Default install MySQL ${mysql_version} Using Generic Binaries."
            Bin="y"
            ;;
        esac
    else
        Bin="n"
    fi

    #do you want to install the InnoDB Storage Engine?
    echo "==========================="

    InstallInnodb="y"
    Echo_Yellow "Do you want to install the InnoDB Storage Engine?"
    read -p "(Default yes,if you want please enter: y , if not please enter: n): " InstallInnodb

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
        ;;
    esac

    mysql_short_version=`echo ${mysql_version} | cut -d. -f1-2`

    echo "=================================================="
    echo "You will upgrade MySQL Version to ${mysql_version}"
    echo "=================================================="

    if [ -s /usr/local/include/jemalloc/jemalloc.h ] && lsof -n|grep "libjemalloc.so"|grep -q "mysqld"; then
        MySQL51MAOpt='--with-mysqld-ldflags=-ljemalloc'
        MySQL55MAOpt="-DCMAKE_EXE_LINKER_FLAGS='-ljemalloc' -DWITH_SAFEMALLOC=OFF"
    elif [ -s /usr/local/include/gperftools/tcmalloc.h ] && lsof -n|grep "libtcmalloc.so"|grep -q "mysqld"; then
        MySQL51MAOpt='--with-mysqld-ldflags=-ltcmalloc'
        MySQL55MAOpt="-DCMAKE_EXE_LINKER_FLAGS='-ltcmalloc' -DWITH_SAFEMALLOC=OFF"
    else
        MySQL51MAOpt=''
        MySQL55MAOpt=''
    fi

    Press_Start

    echo "============================check files=================================="
    cd ${cur_dir}/src
    if [[ "${Bin}" = "y" && "${mysql_short_version}" =~ ^8\.[04]$ ]]; then
        # x86 走 2.17；aarch64 官方只发 glibc2.28 命名（与 init.sh 对齐）
        [ "${DB_ARCH}" = "aarch64" ] && mysql8_glibc_ver="2.28" || mysql8_glibc_ver="2.17"
        mysql_src="mysql-${mysql_version}-linux-glibc${mysql8_glibc_ver}-${DB_ARCH}.tar.xz"
    elif [[ "${Bin}" = "y" && "${mysql_short_version}" =~ ^5.[5-7]$ ]]; then
        mysql_src="mysql-${mysql_version}-linux-glibc2.12-${DB_ARCH}.tar.gz"
    else
        if [[ "${mysql_short_version}" = "5.7" || "${mysql_short_version}" = "8.0" ]]; then
            mysql_src="mysql-boost-${mysql_version}.tar.gz"
        else
            mysql_src="mysql-${mysql_version}.tar.gz"
        fi
    fi
    if [ -s "${mysql_src}" ]; then
        echo "${mysql_src} [found]"
    else
        if Try_Download http://cdn.mysql.com/Downloads/MySQL-${mysql_short_version}/${mysql_src} ${mysql_src}; then
            echo "Download ${mysql_src} successfully!"
        elif Try_Download https://cdn.mysql.com/archives/mysql-${mysql_short_version}/${mysql_src} ${mysql_src}; then
            echo "Download ${mysql_src} successfully!"
        else
            echo "You enter MySQL Version was: ${mysql_version}"
            Echo_Red "Error! You entered a wrong version number, please check!"
            sleep 5
            exit 1
        fi
    fi
    Check_Openssl
    if [ "${Bin}" != "y" ]; then
        Echo_Blue "Install dependent packages..."
        . ${cur_dir}/include/only.sh
        DB_Dependent
    fi
    echo "============================check files=================================="

    # 版本必须在【备份之前】拦下来。Backup_MySQL 是 mv 走 /usr/local/mysql、
    # /etc/init.d/mysql、/etc/my.cnf 和数据目录；一旦跑过再发现没有对应的升级
    # 分支，下面那串 if/elif 一个都不匹配、函数静默返回，用户手上就只剩一台被
    # 拆干净的机器，屏幕上一个字的错都没有。
    # 上面的下载步骤挡不住这种情况：8.1 / 8.2 / 9.x 是真实存在、能正常下到源码包
    # 的版本，只是本脚本没有对应分支，正好走到这一步才出事。
    case "${mysql_short_version}" in
        5.1|5.5|5.6|5.7|8.0|8.4) ;;
        *)
            Echo_Red "不支持升级到 MySQL ${mysql_version}。"
            Echo_Red "本脚本支持的大版本：5.1 / 5.5 / 5.6 / 5.7 / 8.0 / 8.4"
            Echo_Red "已中止，现有数据库未做任何改动。"
            exit 1
            ;;
    esac

    if [ "${Bin}" = "y" ]; then
        Upgrade_Disk_Preflight "${mysql_src}" "${MySQL_Data_Dir}" 512
    else
        Upgrade_Disk_Preflight "${mysql_src}" "${MySQL_Data_Dir}" 3072
    fi

    Backup_MySQL
    if [ "${mysql_short_version}" = "5.1" ]; then
        Upgrade_MySQL51
    elif [ "${mysql_short_version}" = "5.5" ]; then
        Upgrade_MySQL55
    elif [ "${mysql_short_version}" = "5.6" ]; then
        Upgrade_MySQL56
    elif [ "${mysql_short_version}" = "5.7" ]; then
        Upgrade_MySQL57
    elif [ "${mysql_short_version}" = "8.0" ]; then
        Upgrade_MySQL80
    elif [ "${mysql_short_version}" = "8.4" ]; then
        Upgrade_MySQL84
    else
        # 上面的 case 已经拦过，理论上到不了这里。留着是防止将来加版本时
        # 只改一处、另一处漏改——那样又会退回"备份完再静默落空"。
        Echo_Red "内部错误：MySQL ${mysql_short_version} 没有对应的升级分支。"
        Echo_Red "旧库已备份，请勿删除："
        Echo_Red "  SQL  ：/root/mysql_all_backup${Upgrade_Date}.sql"
        Echo_Red "  原目录：/usr/local/oldmysql${Upgrade_Date}"
        exit 1
    fi
    Restore_Start_MySQL
}
