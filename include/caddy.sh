#!/usr/bin/env bash

Install_Caddy()
{
    echo "Installing Caddy..."
    cd ${cur_dir}/src
    Download_Files https://github.com/caddyserver/caddy/releases/download/v${Caddy_Ver}/caddy_${Caddy_Ver}_linux_amd64.tar.gz caddy_${Caddy_Ver}_linux_amd64.tar.gz
    tar -zxvf caddy_${Caddy_Ver}_linux_amd64.tar.gz
    mv caddy /usr/local/bin/
    chmod +x /usr/local/bin/caddy

    if [ ! -d /etc/caddy ]; then
        mkdir -p /etc/caddy
    fi

    if [ ! -f /etc/caddy/Caddyfile ]; then
        cat > /etc/caddy/Caddyfile << EOF
:80 {
    root /home/wwwroot/default
    index index.html index.htm index.php
    php_fastcgi unix /tmp/php-cgi.sock
    gzip
}
EOF
    fi

    if [ ! -f /etc/systemd/system/caddy.service ]; then
        cat > /etc/systemd/system/caddy.service << EOF
[Unit]
Description=Caddy web server
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=www
Group=www
ExecStart=/usr/local/bin/caddy run --config /etc/caddy/Caddyfile
ExecReload=/usr/local/bin/caddy reload --config /etc/caddy/Caddyfile
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
    fi

    systemctl daemon-reload
    systemctl enable caddy
    systemctl start caddy

    if [ -f /usr/local/bin/caddy ]; then
        echo "Caddy installed successfully!"
    else
        echo "Caddy install failed!"
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