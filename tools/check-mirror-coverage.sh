#!/usr/bin/env bash
# 镜像覆盖体检：展开安装脚本会请求的全部镜像文件名，逐一 HEAD 实测。
# 用法: bash tools/check-mirror-coverage.sh [镜像地址]
# 退出码: 0=全覆盖, 1=有缺件。CI 定期跑，防"升了版本号没传包"复发。
# 2026-08-24 审计产物：当时 175 个展开 URL 中 88 个 404，全部因此类漂移或从未上传。
# 覆盖说明：php.ini-production-*（软失败落内置模板）与 composer-2.2.phar（有官方兜底）为非致命请求，未列入；
# 无稳定上游的文件（zend/uw-imap/5.2 fpm patch）在 warn 层，只告警不判红。

MIRROR="${1:-https://mirror.nextlnmp.cn}"
FAIL=0
TOTAL=0
MISSING=()
WARNED=()

chk() { # <path> <context>
    TOTAL=$((TOTAL+1))
    local code
    code=$(curl -o /dev/null -m 30 --connect-timeout 10 -skIL -w '%{http_code}' "${MIRROR}/$1")
    if [ "${code}" != "200" ]; then
        FAIL=$((FAIL+1))
        MISSING+=("${code}  $1  (${2})")
    fi
}

# warn 层：确实会被请求、但上游无稳定补货渠道或代码侧已软失败兜底的文件——只告警不判红
warn_chk() { # <path> <context>
    local code
    code=$(curl -o /dev/null -m 30 --connect-timeout 10 -skIL -w '%{http_code}' "${MIRROR}/$1")
    if [ "${code}" != "200" ]; then
        WARNED+=("${code}  $1  (${2})")
    fi
}

# ---- 基础组件（每次安装必经） ----
chk web/libiconv/libiconv-1.17.tar.gz always
chk web/libmcrypt/libmcrypt-2.5.8.tar.gz always
chk web/mcrypt/mcrypt-2.6.8.tar.gz always
chk web/mhash/mhash-0.9.9.9.tar.bz2 always
chk prober/p.tar.gz always
chk lib/jemalloc/jemalloc-5.3.0.tar.bz2 malloc
chk lib/tcmalloc/gperftools-2.9.1.tar.gz malloc
chk lib/libunwind/libunwind-1.2.1.tar.gz malloc
chk web/nginx/nginx-1.30.3.tar.gz nginx
chk web/apache/httpd-2.2.34.tar.bz2 lamp
chk web/apache/httpd-2.4.57.tar.bz2 lamp
chk web/apache/apr-1.7.4.tar.bz2 lamp
chk web/apache/apr-util-1.6.3.tar.bz2 lamp
for pma in phpMyAdmin-4.0.10.20-all-languages phpMyAdmin-4.9.11-all-languages phpMyAdmin-5.2.2-all-languages; do
    chk "datebase/phpmyadmin/${pma}.tar.xz" phpmyadmin
done

# ---- MySQL ----
for v in mysql-5.1.73 mysql-5.5.62 mysql-5.6.51 mysql-5.7.44 mysql-8.0.46 mysql-8.4.9; do
    chk "datebase/mysql/${v}.tar.gz" mysql-src
done
for v in mysql-5.5.62 mysql-5.6.51 mysql-5.7.44; do
    chk "datebase/mysql/${v}-linux-glibc2.12-x86_64.tar.gz" mysql-bin
done
for v in mysql-8.0.46 mysql-8.4.9; do
    chk "datebase/mysql/${v}-linux-glibc2.17-x86_64.tar.xz" mysql8-bin
    chk "datebase/mysql/${v}-linux-glibc2.28-aarch64.tar.xz" mysql8-bin-arm
done

# ---- MariaDB（bin 仅 x86_64；5.5 无 bin 属上游事实，走源码） ----
for v in mariadb-10.4.33 mariadb-10.5.24 mariadb-10.6.27 mariadb-10.11.18 mariadb-11.8.8 mariadb-12.3.2; do
    chk "datebase/mariadb/${v}-linux-systemd-x86_64.tar.gz" mariadb-bin
done

# ---- PHP 源码 + 老版本附件 ----
for v in 5.2.17 5.3.29 5.4.45 5.5.38 5.6.40 7.0.33 7.1.33 7.2.34 7.3.33 7.4.33 8.0.30 8.1.28 8.2.28 8.3.7 8.4.18; do
    chk "web/php/php-${v}.tar.bz2" php-src
done
# php5.2 fpm 补丁与 Zend loader：唯一供源 soft.vpser.net 不保证可达，代码侧已有兜底/软失败 → warn 层
warn_chk web/phpfpm/php-5.2.17-fpm-0.5.14.diff.gz php5.2
for a in x86_64; do
    warn_chk "web/zend/ZendOptimizer-3.3.9-linux-glibc23-${a}.tar.gz" zend-php52
    warn_chk "web/zend/ZendGuardLoader-php-5.3-linux-glibc23-${a}.tar.gz" zend-php53
    warn_chk "web/zend/ZendGuardLoader-70429-PHP-5.4-linux-glibc23-${a}.tar.gz" zend-php54
    warn_chk "web/zend/zend-loader-php5.5-linux-${a}.tar.gz" zend-php55
    warn_chk "web/zend/zend-loader-php5.6-linux-${a}.tar.gz" zend-php56
done
# uw-imap el9 双 rpm：EL9 装 imap 扩展必经，无公网上游可补（需人工放原件），代码侧缺件时明确告警 → warn 层
warn_chk lib/uw-imap/libc-client-2007f-24.el9.x86_64.rpm imap-el9
warn_chk lib/uw-imap/uw-imap-devel-2007f-24.el9.x86_64.rpm imap-el9

# ---- 库与模块 ----
chk lib/autoconf/autoconf-2.13.tar.gz lib
chk lib/boost/boost_1_59_0.tar.bz2 mysql57-src
chk lib/curl/curl-7.62.0.tar.bz2 lib
chk lib/freetype/freetype-2.7.tar.bz2 oldphp
chk lib/freetype/freetype-2.13.0.tar.xz lib
chk lib/icu4c/icu4c-58_3-src.tgz lib
chk lib/icu4c/icu4c-60_3-src.tgz lib
chk lib/libzip/libzip-1.3.2.tar.xz php73-el7
chk lib/nghttp2/nghttp2-1.52.0.tar.xz lib
chk lib/openssl/openssl-1.0.2u.tar.gz lib
chk lib/openssl/openssl-1.1.1w.tar.gz lib
chk web/pcre/pcre-8.45.tar.bz2 lib
chk lib/lua/luajit2-2.1-20230119.tar.gz nginx-lua
chk lib/lua/lua-nginx-module-0.10.26.tar.gz nginx-lua
chk lib/lua/lua-resty-core-0.1.28.tar.gz nginx-lua
chk lib/lua/lua-resty-lrucache-0.13.tar.gz nginx-lua
chk lib/lua/ngx_devel_kit-0.3.3.tar.gz nginx-lua
chk web/nginx/ngx-fancyindex-0.5.2.tar.xz nginx-fancyindex

# ---- 扩展与附加组件 ----
chk web/imagemagick/ImageMagick-7.1.1-8.tar.xz addon
chk web/imagemagick/ImageMagick-6.9.9-27.tar.gz addon-php52
chk web/imagick/imagick-3.7.0.tgz addon
chk web/imagick/imagick-3.1.2.tgz addon-php52
chk web/memcached/memcached-1.6.15.tar.gz addon
chk web/libmemcached/libmemcached-1.0.18.tar.gz addon
chk web/memcache/memcache-3.0.8.tgz addon
chk web/memcache/memcache-4.0.5.2.tgz addon
chk web/memcache/memcache-8.2.tgz addon
chk web/php-memcached/memcached-2.2.0.tgz addon
chk web/php-memcached/memcached-3.1.5.tgz addon
chk web/php-memcached/memcached-3.2.0.tgz addon
chk web/opcache/zendopcache-7.0.5.tgz addon-oldphp
chk web/apcu/apcu-4.0.11.tgz addon
chk web/apcu/apcu-5.1.22.tgz addon
chk web/apcu_bc/apcu_bc-1.0.5.tgz addon
chk web/sodium/libsodium-2.0.23.tgz sodium
chk web/sodium/libsodium-1.0.7.tgz sodium-old
chk web/swoole/swoole-5.1.1.tgz swoole
chk web/swoole/swoole-5.1.8.tgz swoole-php84
chk web/swoole/swoole-4.8.13.tgz swoole-old
chk web/swoole/swoole-4.5.11.tgz swoole-old
chk web/swoole/swoole-4.3.6.tgz swoole-old
chk web/swoole/swoole-1.10.5.tgz swoole-old
chk web/swoole/swoole-1.6.10.tgz swoole-old
# SourceGuardian 实际请求路径：x86_64 走 14.0.0，aarch64(7.4/8.x) 走 14.0.3（见 php_SourceGuardian.sh）
chk web/sourceguardian/14.0.0/loaders.linux-x86_64.zip sourceguardian
chk web/sourceguardian/14.0.3/loaders.linux-aarch64.zip sourceguardian-arm
chk ftp/pure-ftpd/pure-ftpd-1.0.49.tar.bz2 ftp
chk security/fail2ban/fail2ban-1.1.0.tar.gz tools
chk security/denyhosts/denyhosts-3.1.tar.gz tools

# PHP bin 急速包：清单有条目就会被 Download_Files 请求（致命路径），按 sha256sums.txt 动态展开
if [ -f "$(dirname "$0")/../sha256sums.txt" ]; then
    while read -r binpkg; do
        chk "php/${binpkg}" php-bin-fastlane
    done < <(awk '$2 ~ /-bin-.*\.tar\.gz$/ {print $2}' "$(dirname "$0")/../sha256sums.txt")
fi

echo "=========================================="
if [ ${#WARNED[@]} -gt 0 ]; then
    echo "warn 层缺件（不判红，见各条目注释）："
    printf '%s\n' "${WARNED[@]}"
fi
echo "镜像覆盖体检：${TOTAL} 个必需文件，缺 ${FAIL} 个"
if [ ${FAIL} -gt 0 ]; then
    printf '%s\n' "${MISSING[@]}"
    exit 1
fi
echo "全部在架 ✓"
