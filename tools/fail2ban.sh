#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install nextlnmp"
    exit 1
fi

. ../nextlnmp.conf
. ../include/main.sh
Get_Dist_Name
Get_Dist_Version

Press_Start

if [ "${PM}" = "yum" ]; then
    for packages in python3 python3-setuptools python3-systemd iptables rsyslog;
    do yum install $packages -y; done
    service rsyslog restart
elif [ "${PM}" = "apt" ]; then
    apt-get update
    for packages in python3 python3-setuptools iptables rsyslog;
    do apt-get install -y $packages; done
    if command -v systemctl >/dev/null 2>&1; then
        systemctl restart rsyslog
    else
        /etc/init.d/rsyslog restart
    fi
fi

echo "Downloading..."
cd ../src
# 1.0.3 是不存在的幻影版本号（上游从未发布过）；1.1.0 才兼容 python3.11+
Try_Download ${Download_Mirror}/security/fail2ban/fail2ban-1.1.0.tar.gz fail2ban-1.1.0.tar.gz || Download_Files https://github.com/fail2ban/fail2ban/archive/refs/tags/1.1.0.tar.gz fail2ban-1.1.0.tar.gz
tar zxf fail2ban-1.1.0.tar.gz && cd fail2ban-1.1.0
echo "Installing fail2ban..."
python3 setup.py install

echo "Copy configure file..."
\cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sed -i '/^#mode   = normal/a \
enabled  = true\
filter   = sshd\
maxretry = 5\
bantime  = 604800' /etc/fail2ban/jail.local

echo "Copy init files..."
if [ ! -d /var/run/fail2ban ];then
    mkdir /var/run/fail2ban
fi
if [ `iptables -h|grep -c "\-w"` -eq 0 ]; then
    sed -i 's/lockingopt =.*/lockingopt =/g' /etc/fail2ban/action.d/iptables-common.conf
fi

\cp build/fail2ban.service /etc/systemd/system/fail2ban.service
if [ "${PM}" = "yum" ]; then
    \cp files/redhat-initd /etc/init.d/fail2ban
    sed -i 's#^before = paths-debian.conf#before = paths-fedora.conf#' /etc/fail2ban/jail.local
    sed -i 's/^Environment="PYTHONNOUSERSITE=1"/#Environment="PYTHONNOUSERSITE=1"/' /etc/systemd/system/fail2ban.service
    sed -i 's/-xf start/-x start/' /etc/systemd/system/fail2ban.service
elif [ "${PM}" = "apt" ]; then
    \cp files/debian-initd /etc/init.d/fail2ban
fi

chmod +x /etc/init.d/fail2ban
cd ..
rm -rf fail2ban-1.1.0

StartUp fail2ban

echo "Start fail2ban..."
/etc/init.d/fail2ban start