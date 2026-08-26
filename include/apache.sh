#!/usr/bin/env bash

Install_Apache_22()
{
    Echo_Blue "[+] Installing ${Apache_Ver}..."
    if [ "${Stack}" = "lamp" ]; then
        getent group www >/dev/null 2>&1 || groupadd www
        id -u www >/dev/null 2>&1 || useradd -s /sbin/nologin -g www www
        mkdir -p ${Default_Website_Dir}
        chmod +w ${Default_Website_Dir}
        mkdir -p /home/wwwlogs
        # 曾经是 777。日志文件是 nginx/httpd 的 master（root）打开的，www 根本不需要
    # 写权限；而一个【非 sticky】的 777 目录不受 fs.protected_symlinks 保护
    # （该保护只覆盖 sticky 的世界可写目录，比如 /tmp）。真机实测：www 在这里
    # 预先建一个指向任意路径的符号链接，root 追加日志时会原样跟随过去——
    # 这是一条 www → root 的任意文件写入。755 即可，读日志不受影响。
        chmod 755 /home/wwwlogs
        chown -R www:www ${Default_Website_Dir}
    fi
    Tar_Cd ${Apache_Ver}.tar.bz2 ${Apache_Ver}
    ./configure --prefix=/usr/local/apache --enable-mods-shared=most --enable-headers --enable-mime-magic --enable-proxy --enable-so --enable-rewrite --with-ssl --enable-ssl --enable-deflate --enable-suexec --with-included-apr --with-expat=builtin
    Make_Install
    cd ${cur_dir}/src
    rm -rf ${cur_dir}/src/${Apache_Ver}

    mv /usr/local/apache/conf/httpd.conf /usr/local/apache/conf/httpd.conf.bak
    if [ "${Stack}" = "lamp" ]; then
        \cp ${cur_dir}/conf/httpd22-lamp.conf /usr/local/apache/conf/httpd.conf
        \cp ${cur_dir}/conf/httpd-vhosts-lamp.conf /usr/local/apache/conf/extra/httpd-vhosts.conf
        \cp ${cur_dir}/conf/httpd22-ssl.conf /usr/local/apache/conf/extra/httpd-ssl.conf
        \cp ${cur_dir}/conf/example/enable-apache-ssl-vhost-example.conf /usr/local/apache/conf/enable-apache-ssl-vhost-example.conf
    elif [ "${Stack}" = "nextlnmpa" ]; then
        \cp ${cur_dir}/conf/httpd22-lnmpa.conf /usr/local/apache/conf/httpd.conf
        \cp ${cur_dir}/conf/httpd-vhosts-lnmpa.conf /usr/local/apache/conf/extra/httpd-vhosts.conf
    fi
    \cp ${cur_dir}/conf/httpd-default.conf /usr/local/apache/conf/extra/httpd-default.conf
    \cp ${cur_dir}/conf/mod_remoteip.conf /usr/local/apache/conf/extra/mod_remoteip.conf

    sed -i 's/ServerAdmin you@example.com/ServerAdmin '${ServerAdmin}'/g' /usr/local/apache/conf/httpd.conf
    sed -i 's/webmaster@example.com/'${ServerAdmin}'/g' /usr/local/apache/conf/extra/httpd-vhosts.conf
    mkdir -p /usr/local/apache/conf/vhost

    if [ "${Stack}" = "nextlnmpa" ]; then
        \cp ${cur_dir}/src/patch/mod_remoteip.c .
        /usr/local/apache/bin/apxs -i -c -n mod_remoteip.so mod_remoteip.c
        sed -i 's/#LoadModule/LoadModule/g' /usr/local/apache/conf/extra/mod_remoteip.conf
    fi

    ln -sf /usr/local/lib/libltdl.so.3 /usr/lib/libltdl.so.3
    mkdir /usr/local/apache/conf/vhost

    if [ "${Default_Website_Dir}" != "/home/wwwroot/default" ]; then
        sed -i "s#/home/wwwroot/default#${Default_Website_Dir}#g" /usr/local/apache/conf/httpd.conf
        sed -i "s#/home/wwwroot/default#${Default_Website_Dir}#g" /usr/local/apache/conf/extra/httpd-vhosts.conf
    fi

    if [[ "${PHPSelect}" =~ ^([6-9]|1[0-5])$ ]]; then
        sed -i '/^LoadModule php5_module/d' /usr/local/apache/conf/httpd.conf
    fi

    \cp ${cur_dir}/init.d/init.d.httpd /etc/init.d/httpd
    \cp ${cur_dir}/init.d/httpd.service /etc/systemd/system/httpd.service
    chmod +x /etc/init.d/httpd
}

Install_Apache_24()
{
    Echo_Blue "[+] Installing ${Apache_Ver}..."
    if [ "${Stack}" = "lamp" ]; then
        getent group www >/dev/null 2>&1 || groupadd www
        id -u www >/dev/null 2>&1 || useradd -s /sbin/nologin -g www www
        mkdir -p ${Default_Website_Dir}
        chmod +w ${Default_Website_Dir}
        mkdir -p /home/wwwlogs
        # 曾经是 777。日志文件是 nginx/httpd 的 master（root）打开的，www 根本不需要
    # 写权限；而一个【非 sticky】的 777 目录不受 fs.protected_symlinks 保护
    # （该保护只覆盖 sticky 的世界可写目录，比如 /tmp）。真机实测：www 在这里
    # 预先建一个指向任意路径的符号链接，root 追加日志时会原样跟随过去——
    # 这是一条 www → root 的任意文件写入。755 即可，读日志不受影响。
        chmod 755 /home/wwwlogs
        chown -R www:www ${Default_Website_Dir}
        Install_Openssl_New
        Install_Nghttp2
    fi
    Tar_Cd ${Apache_Ver}.tar.bz2 ${Apache_Ver}
    cd srclib
    if [ -s "${cur_dir}/src/${APR_Ver}.tar.bz2" ]; then
        echo "${APR_Ver}.tar.bz2 [found]"
        cp ${cur_dir}/src/${APR_Ver}.tar.bz2 .
    else
        Download_Files ${Download_Mirror}/web/apache/${APR_Ver}.tar.bz2 ${APR_Ver}.tar.bz2
    fi
    if [ -s "${cur_dir}/src/${APR_Util_Ver}.tar.bz2" ]; then
        echo "${APR_Util_Ver}.tar.bz2 [found]"
        cp ${cur_dir}/src/${APR_Util_Ver}.tar.bz2 .
    else
        Download_Files ${Download_Mirror}/web/apache/${APR_Util_Ver}.tar.bz2 ${APR_Util_Ver}.tar.bz2
    fi
    tar jxf ${APR_Ver}.tar.bz2
    tar jxf ${APR_Util_Ver}.tar.bz2
    mv ${APR_Ver} apr
    mv ${APR_Util_Ver} apr-util
    cd ..
    if [ "${Stack}" = "lamp" ]; then
        ./configure --prefix=/usr/local/apache --enable-mods-shared=most --enable-headers --enable-mime-magic --enable-proxy --enable-so --enable-rewrite --enable-ssl ${apache_with_ssl} --enable-deflate --with-pcre --with-included-apr --with-apr-util --enable-mpms-shared=all --enable-remoteip --enable-http2 --with-nghttp2=/usr/local/nghttp2
    else
        ./configure --prefix=/usr/local/apache --enable-mods-shared=most --enable-headers --enable-mime-magic --enable-proxy --enable-so --enable-rewrite --enable-ssl --with-ssl --enable-deflate --with-pcre --with-included-apr --with-apr-util --enable-mpms-shared=all --enable-remoteip
    fi
    Make_Install
    cd ${cur_dir}/src
    rm -rf ${cur_dir}/src/${Apache_Ver}

    mv /usr/local/apache/conf/httpd.conf /usr/local/apache/conf/httpd.conf.bak
    if [ "${Stack}" = "lamp" ]; then
        \cp ${cur_dir}/conf/httpd24-lamp.conf /usr/local/apache/conf/httpd.conf
        \cp ${cur_dir}/conf/httpd-vhosts-lamp.conf /usr/local/apache/conf/extra/httpd-vhosts.conf
        \cp ${cur_dir}/conf/httpd24-ssl.conf /usr/local/apache/conf/extra/httpd-ssl.conf
        \cp ${cur_dir}/conf/example/enable-apache-ssl-vhost-example.conf /usr/local/apache/conf/enable-apache-ssl-vhost-example.conf
    elif [ "${Stack}" = "nextlnmpa" ]; then
        \cp ${cur_dir}/conf/httpd24-lnmpa.conf /usr/local/apache/conf/httpd.conf
        \cp ${cur_dir}/conf/httpd-vhosts-lnmpa.conf /usr/local/apache/conf/extra/httpd-vhosts.conf
    fi
    \cp ${cur_dir}/conf/httpd-default.conf /usr/local/apache/conf/extra/httpd-default.conf
    \cp ${cur_dir}/conf/mod_remoteip.conf /usr/local/apache/conf/extra/mod_remoteip.conf
    
    sed -i 's/ServerAdmin you@example.com/ServerAdmin '${ServerAdmin}'/g' /usr/local/apache/conf/httpd.conf
    sed -i 's/webmaster@example.com/'${ServerAdmin}'/g' /usr/local/apache/conf/extra/httpd-vhosts.conf
    mkdir /usr/local/apache/conf/vhost

    sed -i 's/NameVirtualHost .*//g' /usr/local/apache/conf/extra/httpd-vhosts.conf
    if [ "${Default_Website_Dir}" != "/home/wwwroot/default" ]; then
        sed -i "s#/home/wwwroot/default#${Default_Website_Dir}#g" /usr/local/apache/conf/httpd.conf
        sed -i "s#/home/wwwroot/default#${Default_Website_Dir}#g" /usr/local/apache/conf/extra/httpd-vhosts.conf
    fi

    if [[ "${PHPSelect}" =~ ^([6-9]|1[0-5])$ ]]; then
        sed -i '/^LoadModule php5_module/d' /usr/local/apache/conf/httpd.conf
    fi

    \cp ${cur_dir}/init.d/init.d.httpd /etc/init.d/httpd
    \cp ${cur_dir}/init.d/httpd.service /etc/systemd/system/httpd.service
    chmod +x /etc/init.d/httpd
}
