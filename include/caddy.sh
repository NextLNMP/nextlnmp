#!/usr/bin/env bash

Install_Caddy()
{
    echo "Installing Caddy..."
    cd ${cur_dir}/src

    # Caddy_Ver 形如 caddy-2.7.1，GitHub release 资产名用纯版本号
    local Caddy_Num=${Caddy_Ver#caddy-}
    local Caddy_Arch=""
    case "$(uname -m)" in
        x86_64)  Caddy_Arch="amd64" ;;
        aarch64) Caddy_Arch="arm64" ;;
        armv7l|armv7*) Caddy_Arch="armv7" ;;
        *)
            Echo_Red "Caddy 预编译包不支持当前架构 $(uname -m)，请改用 WebServer='nginx'"
            exit 1
            ;;
    esac

    Download_Files https://github.com/caddyserver/caddy/releases/download/v${Caddy_Num}/caddy_${Caddy_Num}_linux_${Caddy_Arch}.tar.gz caddy_${Caddy_Num}_linux_${Caddy_Arch}.tar.gz
    tar -zxf caddy_${Caddy_Num}_linux_${Caddy_Arch}.tar.gz caddy
    mv caddy /usr/local/bin/
    chmod +x /usr/local/bin/caddy

    # php-fpm 以 www 用户跑 socket；WebServer=caddy 时 nginx.sh 不执行，这里补建
    if ! id www >/dev/null 2>&1; then
        groupadd www
        useradd -s /sbin/nologin -M -g www www
    fi

    # WebServer=caddy 时 nginx.sh/apache.sh 都不执行，站点根目录在这里建（对齐 nginx.sh 行为）
    mkdir -p ${Default_Website_Dir:-/home/wwwroot/default}
    chown -R www:www ${Default_Website_Dir:-/home/wwwroot/default}

    if [ ! -d /etc/caddy ]; then
        mkdir -p /etc/caddy
    fi

    if [ ! -f /etc/caddy/Caddyfile ]; then
        # Caddy v2 语法；注意 nextlnmp vhost 管理目前仅支持 nginx，Caddy 站点请直接编辑本文件
        cat > /etc/caddy/Caddyfile << EOF
:80 {
	root * ${Default_Website_Dir:-/home/wwwroot/default}
	encode gzip
	php_fastcgi unix//tmp/php-cgi.sock
	file_server
}
EOF
    fi

    if ! /usr/local/bin/caddy validate --config /etc/caddy/Caddyfile >/dev/null 2>&1; then
        Echo_Red "Caddyfile 校验失败，请检查 /etc/caddy/Caddyfile"
        exit 1
    fi

    # www 用户无 home，Caddy 的证书/状态存储需要显式可写目录
    mkdir -p /var/lib/caddy
    chown -R www:www /var/lib/caddy

    if [ ! -f /etc/systemd/system/caddy.service ]; then
        cat > /etc/systemd/system/caddy.service << EOF
[Unit]
Description=Caddy web server
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=notify
User=www
Group=www
Environment=XDG_DATA_HOME=/var/lib/caddy
Environment=XDG_CONFIG_HOME=/var/lib/caddy
ExecStart=/usr/local/bin/caddy run --config /etc/caddy/Caddyfile
ExecReload=/usr/local/bin/caddy reload --config /etc/caddy/Caddyfile
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
# php-fpm 的 socket 在 /tmp/php-cgi.sock，PrivateTmp 会让 Caddy 看不见它（PHP 全 502）
PrivateTmp=false
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
    fi

    # init.d 风格 shim：/bin/nextlnmp 等 CLI 用 /etc/init.d/<name> <action> 的调用约定
    cat > /etc/init.d/caddy << 'EOF'
#!/usr/bin/env bash
case "$1" in
    start|stop|restart|reload|status) systemctl "$1" caddy ;;
    *) echo "Usage: $0 {start|stop|restart|reload|status}"; exit 1 ;;
esac
EOF
    chmod +x /etc/init.d/caddy

    systemctl daemon-reload
    systemctl enable caddy
    systemctl start caddy

    sleep 2
    if [ -f /usr/local/bin/caddy ] && systemctl is-active --quiet caddy; then
        echo "Caddy installed successfully!"
    else
        Echo_Red "Caddy install failed! 服务未能启动，请用 journalctl -u caddy 查看原因"
        exit 1
    fi
}

Uninstall_Caddy()
{
    echo "Uninstalling Caddy..."
    systemctl stop caddy
    systemctl disable caddy
    rm -f /etc/systemd/system/caddy.service
    rm -f /usr/local/bin/caddy
    rm -rf /etc/caddy
    echo "Caddy uninstalled successfully!"
}
