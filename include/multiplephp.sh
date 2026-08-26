#!/usr/bin/env bash

Install_Multiplephp()
{
    Get_Dist_Name
    Check_DB
    Check_Stack
    Get_Dist_Version
    . include/upgrade_php.sh

    if [ "${Get_Stack}" != "nextlnmp" ]; then
        echo "Multiple PHP Versions ONLY for nextLNMP Stack!"
        exit 1
    fi

#which PHP Version do you want to install?
    echo "==========================="

    PHPSelect=""
    #@ 菜单/路径/分发全部由 MPHP_VERSIONS 驱动（conf/cli/php-select.sh 单一事实源）
    #@ 新增 PHP 版本 = 版本表加一项 + 写一个 Install_MPHP<版本> 函数，此处无需改动
    MPHP_LIST=(${MPHP_VERSIONS})
    Echo_Yellow "You have ${#MPHP_LIST[@]} options for your PHP install."
    for i in "${!MPHP_LIST[@]}"; do
        echo "$((i + 1)): Install ${PHP_Info[$i]}"
    done
    read -p "Enter your choice (1-${#MPHP_LIST[@]}): " PHPSelect

    if ! [ "${PHPSelect}" -ge 1 ] 2>/dev/null || [ "${PHPSelect}" -gt "${#MPHP_LIST[@]}" ] 2>/dev/null; then
        echo "No enter,You Must enter one option."
        exit 1
    fi
    MPHP_Ver="${MPHP_LIST[$((PHPSelect - 1))]}"
    MPHP_Path="/usr/local/php${MPHP_Ver}"
    echo "You will install ${PHP_Info[$((PHPSelect - 1))]}"
    if [ "${MPHP_Ver}" = "5.2" ]; then
        #@ PHP 5.2 的 mysql 扩展需要现成的数据库头文件，装之前先确认数据库在
        Check_DB
        if [ "${DB_Name}" == "None" ];then
            Echo_Red "MySQL or MariaDB not found,can't install PHP 5.2!"
            exit 1
        fi
    fi

    Press_Install
    if [ -d "${MPHP_Path}" ]; then
        echo "${Php_Ver} already exists!"
        exit 1
    fi
    Check_PHP_Option
    cat /etc/issue
    cat /etc/*-release
    Install_PHP_Dependent
    Check_Openssl

    #@ 函数名与日志名同样由版本推导，杜绝「加了版本忘了加分发分支」
    "Install_MPHP${MPHP_Ver}" 2>&1 | tee "/root/install-mphp${MPHP_Ver}.log"
}

Install_MPHP5.2()
{
    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Download_Files ${Download_Mirror}/web/phpfpm/php-5.2.17-fpm-0.5.14.diff.gz php-5.2.17-fpm-0.5.14.diff.gz

    nextlnmp stop

    if [[ -s /usr/local/autoconf-2.13/bin/autoconf && -s /usr/local/autoconf-2.13/bin/autoheader ]]; then
        Echo_Green "Autconf 2.13...ok"
    else
        Install_Autoconf
    fi

    ln -s /usr/lib/libevent-1.4.so.2 /usr/local/lib/libevent-1.4.so.2
    ln -s /usr/lib/libltdl.so /usr/lib/libltdl.so.3

    cd ${cur_dir}/src
    rm -rf php-5.2.17

    echo "Start install ${Php_Ver}....."
    Export_PHP_Autoconf
    tar jxf ${Php_Ver}.tar.bz2
    gzip -cd php-5.2.17-fpm-0.5.14.diff.gz | patch -d ${Php_Ver} -p1
    cd ${Php_Ver}
    patch -p1 < ${cur_dir}/src/patch/php-5.2.17-max-input-vars.patch
    patch -p0 < ${cur_dir}/src/patch/php-5.2.17-xml.patch
    patch -p1 < ${cur_dir}/src/patch/debian_patches_disable_SSLv2_for_openssl_1_0_0.patch
    ./buildconf --force
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --with-mysql=${MySQL_Dir} --with-mysqli=${MySQL_Config} --with-pdo-mysql=${MySQL_Dir} --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --enable-discard-path --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization ${with_curl} --enable-mbregex --enable-fastcgi --enable-fpm --enable-force-cgi-redirect --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --with-mime-magic
    PHP_Make_Install

    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-dist ${MPHP_Path}/etc/php.ini

    # php extensions
    sed -i 's#extension_dir = "./"#extension_dir = "'${MPHP_Path}'/lib/php/extensions/no-debug-non-zts-20060613/"\n#' ${MPHP_Path}/etc/php.ini
    sed -i 's#output_buffering = Off#output_buffering = On#' ${MPHP_Path}/etc/php.ini
    sed -i 's/post_max_size = 8M/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag = Off/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/; cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/; cgi.fix_pathinfo=0/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time = 30/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsocket/g' ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}/src
    if [ "${Is_ARM}" != "y" ]; then
        if ! Try_Download ${Download_Mirror}/web/zend/ZendOptimizer-3.3.9-linux-glibc23-${ARCH}.tar.gz ZendOptimizer-3.3.9-linux-glibc23-${ARCH}.tar.gz; then
            Echo_Yellow "Zend loader 组件不可用，跳过安装（仅影响运行 Zend 加密程序，PHP 本体不受影响）"
        else
        Tar_Cd ZendOptimizer-3.3.9-linux-glibc23-${ARCH}.tar.gz
        mkdir -p /usr/local/zend/
        \cp ZendOptimizer-3.3.9-linux-glibc23-${ARCH}/data/5_2_x_comp/ZendOptimizer.so /usr/local/zend/ZendOptimizer5.2.so

        cat >${MPHP_Path}/conf.d/002-zendoptimizer.ini<<EOF
[Zend Optimizer]
zend_optimizer.optimization_level=1
zend_extension="/usr/local/zend/ZendOptimizer5.2.so"
EOF
        fi
    fi

    rm -f ${MPHP_Path}/etc/php-fpm.conf
    \cp ${cur_dir}/conf/php-fpm5.2.conf ${MPHP_Path}/etc/php-fpm.conf
    \cp ${cur_dir}/conf/enable-php5.2.conf /usr/local/nginx/conf/enable-php5.2.conf
    \cp ${cur_dir}/init.d/init.d.php-fpm5.2 /etc/init.d/php-fpm5.2
    chmod +x /etc/init.d/php-fpm5.2

    sed -i "s#/usr/local/php/#${MPHP_Path}/#g" ${MPHP_Path}/etc/php-fpm.conf
    sed -i 's#php-cgi.sock#php-cgi5.2.sock#g' ${MPHP_Path}/etc/php-fpm.conf
    sed -i "s#/usr/local/php/#${MPHP_Path}/#g" /etc/init.d/php-fpm5.2
    sed -i 's@# Provides:          php-fpm@# Provides:          php-fpm5.2@g' /etc/init.d/php-fpm5.2

    StartUp php-fpm5.2

    sleep 2

    nextlnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver}"
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp5.2.log from your server, and upload install-mphp5.2.log to nextLNMP Forum."
    fi
}

Install_MPHP5.3()
{
    nextlnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Echo_Blue "[+] Installing ${Php_Ver}..."
    Tar_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    patch -p1 < ${cur_dir}/src/patch/php-5.3-multipart-form-data.patch
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization ${with_curl} --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext ${with_fileinfo} ${PHP_Buildin_Option} ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/register_long_arrays =.*/;register_long_arrays = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/magic_quotes_gpc =.*/;magic_quotes_gpc = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}/src
    if [ "${Is_ARM}" != "y" ]; then
        echo "Install ZendGuardLoader for PHP 5.3..."
        if ! Try_Download ${Download_Mirror}/web/zend/ZendGuardLoader-php-5.3-linux-glibc23-${ARCH}.tar.gz ZendGuardLoader-php-5.3-linux-glibc23-${ARCH}.tar.gz; then
            Echo_Yellow "Zend loader 组件不可用，跳过安装（仅影响运行 Zend 加密程序，PHP 本体不受影响）"
        else
        Tar_Cd ZendGuardLoader-php-5.3-linux-glibc23-${ARCH}.tar.gz
        mkdir -p /usr/local/zend/
        \cp ZendGuardLoader-php-5.3-linux-glibc23-${ARCH}/php-5.3.x/ZendGuardLoader.so /usr/local/zend/ZendGuardLoader5.3.so

        echo "Write ZendGuardLoader to php.ini..."
        cat >${MPHP_Path}/conf.d/002-zendguardloader.ini<<EOF
[Zend ZendGuard Loader]
zend_extension=/usr/local/zend/ZendGuardLoader5.3.so
zend_loader.enable=1
zend_loader.disable_licensing=0
zend_loader.obfuscation_level_support=3
zend_loader.license_path=
EOF
        fi
    fi

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi5.3.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm5.3
    chmod +x /etc/init.d/php-fpm5.3
    sed -i 's@# Provides:          php-fpm@# Provides:          php-fpm5.3@g' /etc/init.d/php-fpm5.3

    StartUp php-fpm5.3

    \cp ${cur_dir}/conf/enable-php5.3.conf /usr/local/nginx/conf/enable-php5.3.conf

    sleep 2

    nextlnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp5.3.log from your server, and upload install-mphp5.3.log to nextLNMP Forum."
    fi
}

Install_MPHP5.4()
{
    nextlnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Echo_Blue "[+] Installing ${Php_Ver}..."
    Tar_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization ${with_curl} --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext ${with_fileinfo} --enable-intl --with-xsl ${PHP_Buildin_Option} ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}/src
    if [ "${Is_ARM}" != "y" ]; then
        echo "Install ZendGuardLoader for PHP 5.4..."
        if ! Try_Download ${Download_Mirror}/web/zend/ZendGuardLoader-70429-PHP-5.4-linux-glibc23-${ARCH}.tar.gz ZendGuardLoader-70429-PHP-5.4-linux-glibc23-${ARCH}.tar.gz; then
            Echo_Yellow "Zend loader 组件不可用，跳过安装（仅影响运行 Zend 加密程序，PHP 本体不受影响）"
        else
        Tar_Cd ZendGuardLoader-70429-PHP-5.4-linux-glibc23-${ARCH}.tar.gz
        mkdir -p /usr/local/zend/
        \cp ZendGuardLoader-70429-PHP-5.4-linux-glibc23-${ARCH}/php-5.4.x/ZendGuardLoader.so /usr/local/zend/ZendGuardLoader5.4.so

        echo "Write ZendGuardLoader to php.ini..."
        cat >${MPHP_Path}/conf.d/002-zendguardloader.ini<<EOF
[Zend ZendGuard Loader]
zend_extension=/usr/local/zend/ZendGuardLoader5.4.so
zend_loader.enable=1
zend_loader.disable_licensing=0
zend_loader.obfuscation_level_support=3
zend_loader.license_path=
EOF
        fi
    fi

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi5.4.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm5.4
    chmod +x /etc/init.d/php-fpm5.4
    sed -i 's@# Provides:          php-fpm@# Provides:          php-fpm5.4@g' /etc/init.d/php-fpm5.4

    StartUp php-fpm5.4

    \cp ${cur_dir}/conf/enable-php5.4.conf /usr/local/nginx/conf/enable-php5.4.conf

    sleep 2

    nextlnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp5.4.log from your server, and upload install-mphp5.4.log to nextLNMP Forum."
    fi
}

Install_MPHP5.5()
{
    nextlnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Echo_Blue "[+] Installing ${Php_Ver}..."
    Tar_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    if [ "${ARCH}" = "aarch64" ]; then
        patch -p1 < ${cur_dir}/src/patch/php-5.5-5.6-asm-aarch64.patch
    fi
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization ${with_curl} --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext ${with_fileinfo} --enable-opcache --enable-intl --with-xsl ${PHP_Buildin_Option} ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    # php extensions
    echo "Modify php.ini..."
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}/src
    if [ "${Is_ARM}" != "y" ]; then
        echo "Install ZendGuardLoader for PHP 5.5..."
        if ! Try_Download ${Download_Mirror}/web/zend/zend-loader-php5.5-linux-${ARCH}.tar.gz zend-loader-php5.5-linux-${ARCH}.tar.gz; then
            Echo_Yellow "Zend loader 组件不可用，跳过安装（仅影响运行 Zend 加密程序，PHP 本体不受影响）"
        else
        Tar_Cd zend-loader-php5.5-linux-${ARCH}.tar.gz
        mkdir -p /usr/local/zend/
        \cp zend-loader-php5.5-linux-${ARCH}/ZendGuardLoader.so /usr/local/zend/ZendGuardLoader5.5.so

        echo "Write ZendGuardLoader to php.ini..."
        cat >${MPHP_Path}/conf.d/002-zendguardloader.ini<<EOF
[Zend ZendGuard Loader]
zend_extension=/usr/local/zend/ZendGuardLoader5.5.so
zend_loader.enable=1
zend_loader.disable_licensing=0
zend_loader.obfuscation_level_support=3
zend_loader.license_path=
EOF
        fi
    fi

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi5.5.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm5.5
    chmod +x /etc/init.d/php-fpm5.5
    sed -i 's@# Provides:          php-fpm@# Provides:          php-fpm5.5@g' /etc/init.d/php-fpm5.5

    StartUp php-fpm5.5

    \cp ${cur_dir}/conf/enable-php5.5.conf /usr/local/nginx/conf/enable-php5.5.conf

    sleep 2

    nextlnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp5.5.log from your server, and upload install-mphp5.5.log to nextLNMP Forum."
    fi
}

Install_MPHP5.6()
{
    nextlnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Echo_Blue "[+] Installing ${Php_Ver}"
    Tar_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    if [ "${ARCH}" = "aarch64" ]; then
        patch -p1 < ${cur_dir}/src/patch/php-5.5-5.6-asm-aarch64.patch
    fi
    if command -v pkg-config >/dev/null 2>&1 && pkg-config --modversion icu-i18n | grep -Eqi '^6[1-9]|[7-9][0-9]'; then
        patch -p1 < ${cur_dir}/src/patch/php-5.6-intl.patch
    fi
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization ${with_curl} --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext ${with_fileinfo} --enable-opcache --enable-intl --with-xsl ${PHP_Buildin_Option} ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}/src
    if [ "${Is_ARM}" != "y" ]; then
        echo "Install ZendGuardLoader for PHP 5.6..."
        if ! Try_Download ${Download_Mirror}/web/zend/zend-loader-php5.6-linux-${ARCH}.tar.gz zend-loader-php5.6-linux-${ARCH}.tar.gz; then
            Echo_Yellow "Zend loader 组件不可用，跳过安装（仅影响运行 Zend 加密程序，PHP 本体不受影响）"
        else
        Tar_Cd zend-loader-php5.6-linux-${ARCH}.tar.gz
        mkdir -p /usr/local/zend/
        \cp zend-loader-php5.6-linux-${ARCH}/ZendGuardLoader.so /usr/local/zend/ZendGuardLoader5.6.so

        echo "Write ZendGuardLoader to php.ini..."
        cat >${MPHP_Path}/conf.d/002-zendguardloader.ini<<EOF
[Zend ZendGuard Loader]
zend_extension=/usr/local/zend/ZendGuardLoader5.6.so
zend_loader.enable=1
zend_loader.disable_licensing=0
zend_loader.obfuscation_level_support=3
zend_loader.license_path=
EOF
        fi
    fi

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi5.6.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm5.6
    chmod +x /etc/init.d/php-fpm5.6
    sed -i 's@# Provides:          php-fpm@# Provides:          php-fpm5.6@g' /etc/init.d/php-fpm5.6

    StartUp php-fpm5.6

    \cp ${cur_dir}/conf/enable-php5.6.conf /usr/local/nginx/conf/enable-php5.6.conf

    sleep 2

    nextlnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp5.6.log from your server, and upload install-mphp5.6.log to nextLNMP Forum."
    fi
}

Install_MPHP7.0()
{
    nextlnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Echo_Blue "[+] Installing ${Php_Ver}"
    Tar_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    if command -v pkg-config >/dev/null 2>&1 && pkg-config --modversion icu-i18n | grep -Eqi '^6[1-9]|[7-9][0-9]'; then
        patch -p1 < ${cur_dir}/src/patch/php-7.0-intl.patch
    fi
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization ${with_curl} --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext ${with_fileinfo} --enable-opcache --with-xsl ${PHP_Buildin_Option} ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}/src
    echo "Install ZendGuardLoader for PHP 7..."
    echo "unavailable now."

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi7.0.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm7.0
    chmod +x /etc/init.d/php-fpm7.0
    sed -i 's@# Provides:          php-fpm@# Provides:          php-fpm7.0@g' /etc/init.d/php-fpm7.0

    StartUp php-fpm7.0

    \cp ${cur_dir}/conf/enable-php7.0.conf /usr/local/nginx/conf/enable-php7.0.conf

    sleep 2

    nextlnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp7.0.log from your server, and upload install-mphp7.0.log to nextLNMP Forum."
    fi
}

Install_MPHP7.1()
{
    nextlnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Echo_Blue "[+] Installing ${Php_Ver}"
    Tar_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    PHP_Openssl3_Patch
    PHP_ICU70_Patch
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization ${with_curl} --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext ${with_fileinfo} --enable-opcache --with-xsl ${PHP_Buildin_Option} ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}/src
    echo "Install ZendGuardLoader for PHP 7.1..."
    echo "unavailable now."

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi7.1.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm7.1
    chmod +x /etc/init.d/php-fpm7.1
    sed -i 's@# Provides:          php-fpm@# Provides:          php-fpm7.1@g' /etc/init.d/php-fpm7.1

    StartUp php-fpm7.1

    \cp ${cur_dir}/conf/enable-php7.1.conf /usr/local/nginx/conf/enable-php7.1.conf

    sleep 2

    nextlnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp7.1.log from your server, and upload install-mphp7.1.log to nextLNMP Forum."
    fi
}

Install_MPHP7.2()
{
    nextlnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Echo_Blue "[+] Installing ${Php_Ver}"
    Tar_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    PHP_Openssl3_Patch
    PHP_ICU70_Patch
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization ${with_curl} --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --enable-ftp --with-gd ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext ${with_fileinfo} --enable-opcache --with-xsl ${PHP_Buildin_Option} ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}/src
    echo "Install ZendGuardLoader for PHP 7.2..."
    echo "unavailable now."

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi7.2.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm7.2
    chmod +x /etc/init.d/php-fpm7.2
    sed -i 's@# Provides:          php-fpm@# Provides:          php-fpm7.2@g' /etc/init.d/php-fpm7.2

    StartUp php-fpm7.2

    \cp ${cur_dir}/conf/enable-php7.2.conf /usr/local/nginx/conf/enable-php7.2.conf

    sleep 2

    nextlnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp7.2.log from your server, and upload install-mphp7.2.log to nextLNMP Forum."
    fi
}

Install_MPHP7.3()
{
    nextlnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Echo_Blue "[+] Installing ${Php_Ver}"
    Tar_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    PHP_Openssl3_Patch
    PHP_ICU70_Patch
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization ${with_curl} --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --enable-ftp --with-gd ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --without-libzip --enable-soap --with-gettext ${with_fileinfo} --enable-opcache --with-xsl ${PHP_Buildin_Option} ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}/src
    echo "Install ZendGuardLoader for PHP 7.3..."
    echo "unavailable now."

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi7.3.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm7.3
    chmod +x /etc/init.d/php-fpm7.3
    sed -i 's@# Provides:          php-fpm@# Provides:          php-fpm7.3@g' /etc/init.d/php-fpm7.3

    StartUp php-fpm7.3

    \cp ${cur_dir}/conf/enable-php7.3.conf /usr/local/nginx/conf/enable-php7.3.conf

    sleep 2

    nextlnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp7.3.log from your server, and upload install-mphp7.3.log to nextLNMP Forum."
    fi
}

Install_MPHP7.4()
{
    nextlnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Install_Libzip
    Echo_Blue "[+] Installing ${Php_Ver}"
    Tar_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    PHP_Openssl3_Patch
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype=/usr/local/freetype --with-jpeg --with-png --with-zlib --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization ${with_curl} --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --enable-ftp --enable-gd ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --with-zip --without-libzip --enable-soap --with-gettext ${with_fileinfo} --enable-opcache --with-xsl --with-pear --with-webp ${PHP_Buildin_Option} ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}/src
    echo "Install ZendGuardLoader for PHP 7.4..."
    echo "unavailable now."

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi7.4.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm7.4
    chmod +x /etc/init.d/php-fpm7.4
    sed -i 's@# Provides:          php-fpm@# Provides:          php-fpm7.4@g' /etc/init.d/php-fpm7.4

    StartUp php-fpm7.4

    \cp ${cur_dir}/conf/enable-php7.4.conf /usr/local/nginx/conf/enable-php7.4.conf

    sleep 2

    nextlnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp7.4.log from your server, and upload install-mphp7.4.log to nextLNMP Forum."
    fi
}

Install_MPHP8.0()
{
    nextlnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Install_Libzip
    Echo_Blue "[+] Installing ${Php_Ver}"
    Tar_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    PHP_Openssl3_Patch
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv=/usr/local --with-freetype=/usr/local/freetype --with-jpeg --with-zlib --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem ${with_curl} --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --enable-ftp --enable-gd ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-zip --enable-soap --with-gettext ${with_fileinfo} --enable-opcache --with-xsl --with-pear --with-webp ${PHP_Buildin_Option} ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}/src
    echo "Install ZendGuardLoader for PHP 8.0..."
    echo "unavailable now."

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi8.0.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm8.0
    chmod +x /etc/init.d/php-fpm8.0
    sed -i 's@# Provides:          php-fpm@# Provides:          php-fpm8.0@g' /etc/init.d/php-fpm8.0

    StartUp php-fpm8.0

    \cp ${cur_dir}/conf/enable-php8.0.conf /usr/local/nginx/conf/enable-php8.0.conf

    sleep 2

    nextlnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp8.0.log from your server, and upload install-mphp8.0.log to nextLNMP Forum."
    fi
}

Install_MPHP8.1()
{
    nextlnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Install_Libzip
    Echo_Blue "[+] Installing ${Php_Ver}"
    Tar_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv=/usr/local --with-freetype=/usr/local/freetype --with-jpeg --with-zlib --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem ${with_curl} --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --enable-ftp --enable-gd ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-zip --enable-soap --with-gettext ${with_fileinfo} --enable-opcache --with-xsl --with-pear --with-webp ${PHP_Buildin_Option} ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}/src
    echo "Install ZendGuardLoader for PHP 8.1..."
    echo "unavailable now."

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi8.1.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm8.1
    chmod +x /etc/init.d/php-fpm8.1
    sed -i 's@# Provides:          php-fpm@# Provides:          php-fpm8.1@g' /etc/init.d/php-fpm8.1

    StartUp php-fpm8.1

    \cp ${cur_dir}/conf/enable-php8.1.conf /usr/local/nginx/conf/enable-php8.1.conf

    sleep 2

    nextlnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp8.1.log from your server, and upload install-mphp8.1.log to nextLNMP Forum."
    fi
}

Install_MPHP8.2()
{
    nextlnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Install_Libzip
    Echo_Blue "[+] Installing ${Php_Ver}"
    Tar_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv=/usr/local --with-freetype=/usr/local/freetype --with-jpeg --with-zlib --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem ${with_curl} --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --enable-ftp --enable-gd ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-zip --enable-soap --with-gettext ${with_fileinfo} --enable-opcache --with-xsl --with-pear --with-webp ${PHP_Buildin_Option} ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}/src
    echo "Install ZendGuardLoader for PHP 8.2..."
    echo "unavailable now."

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi8.2.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm8.2
    chmod +x /etc/init.d/php-fpm8.2
    sed -i 's@# Provides:          php-fpm@# Provides:          php-fpm8.2@g' /etc/init.d/php-fpm8.2

    StartUp php-fpm8.2

    \cp ${cur_dir}/conf/enable-php8.2.conf /usr/local/nginx/conf/enable-php8.2.conf

    sleep 2

    nextlnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp8.2.log from your server, and upload install-mphp8.2.log to nextLNMP Forum."
    fi
}

Install_MPHP8.3()
{
    nextlnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Install_Libzip
    Echo_Blue "[+] Installing ${Php_Ver}"
    Tar_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv=/usr/local --with-freetype=/usr/local/freetype --with-jpeg --with-zlib --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem ${with_curl} --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --enable-ftp --enable-gd ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-zip --enable-soap --with-gettext ${with_fileinfo} --enable-opcache --with-xsl --with-pear --with-webp ${PHP_Buildin_Option} ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}/src
    echo "Install ZendGuardLoader for PHP 8.3..."
    echo "unavailable now."

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi8.3.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm8.3
    chmod +x /etc/init.d/php-fpm8.3
    sed -i 's@# Provides:          php-fpm@# Provides:          php-fpm8.3@g' /etc/init.d/php-fpm8.3

    StartUp php-fpm8.3

    \cp ${cur_dir}/conf/enable-php8.3.conf /usr/local/nginx/conf/enable-php8.3.conf

    sleep 2

    nextlnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp8.3.log from your server, and upload install-mphp8.3.log to nextLNMP Forum."
    fi
}

Install_MPHP8.4()
{
    nextlnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Install_Libzip
    Echo_Blue "[+] Installing ${Php_Ver}"
    Tar_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv=/usr/local --with-freetype=/usr/local/freetype --with-jpeg --with-zlib --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem ${with_curl} --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --enable-ftp --enable-gd ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-zip --enable-soap --with-gettext ${with_fileinfo} --enable-opcache --with-xsl --with-pear --with-webp ${PHP_Buildin_Option} ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}/src
    echo "Install ZendGuardLoader for PHP 8.4..."
    echo "unavailable now."

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi8.4.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm8.4
    chmod +x /etc/init.d/php-fpm8.4
    sed -i 's@# Provides:          php-fpm@# Provides:          php-fpm8.4@g' /etc/init.d/php-fpm8.4

    StartUp php-fpm8.4

    \cp ${cur_dir}/conf/enable-php8.4.conf /usr/local/nginx/conf/enable-php8.4.conf

    sleep 2

    nextlnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp8.4.log from your server, and upload install-mphp8.4.log to nextLNMP Forum."
    fi
}
