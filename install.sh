#!/usr/bin/env bash
# ============================================================================
# NextLNMP 一键安装引导脚本 v1.5.1
# 用法：bash <(curl -sL https://gitee.com/palmmedia/nextlnmp/raw/main/install.sh)
# 项目：https://github.com/NextLNMP/nextlnmp
# 作者：静水流深 · 掌媒科技有限公司
# 授权：GPL-3.0
# ============================================================================

set -euo pipefail

# ── 颜色 ──────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
PLAIN='\033[0m'

# ── 版本与配置（每次发版更新这两个值）────────────────────────────────
NEXTLNMP_VER="1.5.5"
TARBALL_SHA256="1541caeae7915508e54e897f8f1b0152c341f4998f192b5a9a5f32b37c9f5753"

# ── 固定配置 ──────────────────────────────────────────────────────────
INSTALL_DIR="/root/nextlnmp"
TMP_FILE="/tmp/nextlnmp-${NEXTLNMP_VER}.tar.gz"

# ── 下载源（按优先级）────────────────────────────────────────────────
MIRROR_URL="https://mirror.zhangmei.com/nextlnmp-${NEXTLNMP_VER}.tar.gz"
GITEE_URL="https://gitee.com/palmmedia/nextlnmp/releases/download/v${NEXTLNMP_VER}/nextlnmp-${NEXTLNMP_VER}.tar.gz"
GITHUB_URL="https://github.com/NextLNMP/nextlnmp/releases/download/v${NEXTLNMP_VER}/nextlnmp-${NEXTLNMP_VER}.tar.gz"

# ====================================================================
# 步骤 1：root 权限检查
# ====================================================================
check_root() {
    if [[ $EUID -ne 0 ]]; then
        if command -v sudo &>/dev/null; then
            exec sudo bash "$0" "$@"
        fi
        echo ""
        echo "❌ 当前不是 root 用户，没有安装权限"
        echo ""
        echo "👉 请在终端输入以下命令切换到 root 用户："
        echo ""
        echo "   sudo -i"
        echo ""
        echo "   输入后会要求输入密码，输入时屏幕不会显示，输完直接按回车"
        echo ""
        echo "👉 如果提示 sudo 不存在或密码不对："
        echo "   登录你的 VPS 服务商后台（阿里云/腾讯云/搬瓦工/Vultr等）"
        echo "   找到「重置 root 密码」，设置新密码后用 root 账号重新登录"
        echo ""
        echo "切换到 root 后，重新运行本安装命令即可"
        echo ""
        exit 1
    fi
}

# ====================================================================
# 步骤 2：快速判断包管理器
# ====================================================================
detect_pkg_mgr() {
    if command -v yum &>/dev/null; then
        PKG_MGR="yum"
    elif command -v apt-get &>/dev/null; then
        PKG_MGR="apt-get"
    else
        echo ""
        echo "❌ 无法识别你的系统，NextLNMP 支持 CentOS / Ubuntu / Debian"
        echo "👉 如需帮助请加 QQ群：615298"
        exit 1
    fi
}

# ====================================================================
# 步骤 3：安装基础依赖
# ====================================================================
install_deps() {
    echo "正在检查安装环境..."

    local need_install=()

    command -v wget      &>/dev/null || need_install+=(wget)
    command -v tar       &>/dev/null || need_install+=(tar)
    command -v curl      &>/dev/null || need_install+=(curl)
    command -v sha256sum &>/dev/null || need_install+=(coreutils)
    command -v git       &>/dev/null || need_install+=(git)

    if [[ ${#need_install[@]} -eq 0 ]]; then
        echo "✓ 基础工具已就绪"
        return 0
    fi

    echo "正在安装必要工具：${need_install[*]} ..."

    if [[ "${PKG_MGR}" == "yum" ]]; then
        yum install -y "${need_install[@]}" > /dev/null 2>&1
    else
        apt-get update -qq > /dev/null 2>&1
        apt-get install -y "${need_install[@]}" > /dev/null 2>&1
    fi

    for cmd in wget tar curl sha256sum git; do
        if ! command -v "$cmd" &>/dev/null; then
            echo ""
            echo "❌ ${cmd} 安装失败"
            echo "👉 请手动执行：${PKG_MGR} install -y ${cmd}"
            echo "👉 安装成功后重新运行本安装命令即可"
            echo "👉 如需帮助请加 QQ群：615298"
            exit 1
        fi
    done

    echo "✓ 基础工具安装完成"
}

# ====================================================================
# 步骤 4：系统详细识别
# ====================================================================
check_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_ID="${ID,,}"
        OS_VER="${VERSION_ID}"
    elif [[ -f /etc/redhat-release ]]; then
        OS_ID="centos"
        OS_VER=$(grep -oE '[0-9]+' /etc/redhat-release | head -1)
    else
        echo ""
        echo "❌ 无法识别你的操作系统"
        echo ""
        echo "NextLNMP 目前支持以下系统："
        echo "  · CentOS 7 / 8 / 9"
        echo "  · Rocky Linux 8 / 9"
        echo "  · AlmaLinux 8 / 9"
        echo "  · Ubuntu 20.04 / 22.04 / 24.04"
        echo "  · Debian 11 / 12"
        echo ""
        echo "👉 如果你不确定自己的系统版本，执行这条命令查看："
        echo ""
        echo "   cat /etc/os-release"
        echo ""
        echo "👉 把结果截图发到 QQ群 615298，我们帮你看"
        exit 1
    fi

    OS_ARCH=$(uname -m)
    echo "✓ 系统识别：${PRETTY_NAME:-${OS_ID} ${OS_VER}}（${OS_ARCH}）"
}

# ====================================================================
# 步骤 5：显示 LOGO
# ====================================================================
print_logo() {
    clear
    echo ""
    echo "  +===============================================+"
    echo "  |         NextLNMP 一键建站安装程序              |"
    echo "  |         安全可信 · SHA256逐包校验              |"
    echo "  +===============================================+"
    echo "  |  版本：v${NEXTLNMP_VER}                                 |"
    echo "  |  官网：https://cnwebmasters.com               |"
    echo "  |  QQ群：615298                                 |"
    echo "  |  作者：静水流深 · 掌媒科技有限公司               |"
    echo "  +===============================================+"
    echo ""
}

# ====================================================================
# 步骤 6：环境预检（只警告不阻断）
# ====================================================================
check_env() {
    echo ""
    echo "正在检查服务器环境..."

    local mem_mb
    mem_mb=$(free -m | awk '/Mem:/{print $2}')
    if [[ ${mem_mb} -lt 512 ]]; then
        echo ""
        echo "⚠️  内存较低：${mem_mb}MB（建议至少 512MB）"
        echo "   内存太小可能导致编译 PHP/MySQL 时失败"
        echo ""
    else
        echo "✓ 内存：${mem_mb}MB"
    fi

    local disk_gb
    disk_gb=$(df -BG / | awk 'NR==2{print int($4)}')
    if [[ ${disk_gb} -lt 5 ]]; then
        echo ""
        echo "⚠️  磁盘剩余空间较小：${disk_gb}GB（建议至少 5GB）"
        echo ""
    else
        echo "✓ 磁盘可用：${disk_gb}GB"
    fi

    if ss -tlnp 2>/dev/null | grep -q ':80 '; then
        local proc_80
        proc_80=$(ss -tlnp | grep ':80 ' | grep -oP 'users:\(\("\K[^"]+' | head -1)
        echo ""
        echo "⚠️  80 端口被占用（${proc_80:-未知进程}）"
        echo "   安装前建议先停掉占用的服务"
        echo ""
    else
        echo "✓ 80 端口空闲"
    fi

    if ss -tlnp 2>/dev/null | grep -q ':443 '; then
        echo "⚠️  443 端口被占用，安装后 HTTPS 可能冲突"
    else
        echo "✓ 443 端口空闲"
    fi

    echo ""
}

# ====================================================================
# 步骤 7：系统全量更新（静默执行）
# ====================================================================
system_update() {
    echo -e "${BLUE}正在更新系统软件包，请稍候...${PLAIN}"

    if [[ "${PKG_MGR}" == "apt-get" ]]; then
        apt-get update -qq > /dev/null 2>&1 && \
        DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq > /dev/null 2>&1 && \
        echo "✓ 系统软件包已更新" || \
        echo "⚠️  系统更新部分失败，继续安装（通常不影响结果）"
    elif [[ "${PKG_MGR}" == "yum" ]]; then
        yum update -y -q > /dev/null 2>&1 && \
        echo "✓ 系统软件包已更新" || \
        echo "⚠️  系统更新部分失败，继续安装（通常不影响结果）"
    fi
}

# ====================================================================
# 步骤 8：BBR 状态机（从 newbbr.sh 移植，去菜单全自动）
# ====================================================================

# 检测 BBR 是否已启用
check_bbr_status() {
    local param
    param=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}')
    [[ "$param" == "bbr" ]]
}

# 检测内核是否原生支持 BBR（≥4.9）
check_kernel_native_bbr() {
    local kernel_ver
    kernel_ver=$(uname -r | grep -oE '^[0-9]+\.[0-9]+')
    local major minor
    major=$(echo "$kernel_ver" | cut -d. -f1)
    minor=$(echo "$kernel_ver" | cut -d. -f2)
    [[ $major -gt 4 ]] || [[ $major -eq 4 && $minor -ge 9 ]]
}

# 启用 BBR
enable_bbr() {
    echo -e "${BLUE}正在启用 BBR...${PLAIN}"
    # 防止重复写入
    grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf 2>/dev/null || \
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf 2>/dev/null || \
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p > /dev/null 2>&1
    echo -e "${GREEN}✓ BBR 已启用${PLAIN}"
}

# 检测虚拟化（OpenVZ 提示）
check_virt() {
    local virt_type="unknown"
    if command -v systemd-detect-virt &>/dev/null; then
        virt_type=$(systemd-detect-virt 2>/dev/null || echo "unknown")
    fi
    if [[ "$virt_type" == "openvz" ]]; then
        echo ""
        echo -e "${YELLOW}⚠️  检测到 OpenVZ 虚拟化，无法更换内核，BBR 可能无法启用${PLAIN}"
        echo -e "${YELLOW}   建议：更换为 KVM 虚拟化的 VPS${PLAIN}"
        echo ""
    fi
}

# 升级内核（Debian/Ubuntu）
upgrade_kernel_debian() {
    echo -e "${BLUE}正在升级内核（Linux 6.x HWE）...${PLAIN}"
    apt-get update -qq > /dev/null 2>&1

    local pkg=""
    if [[ "$OS_ID" == "ubuntu" ]]; then
        pkg="linux-generic-hwe-$(echo "$OS_VER" | cut -d. -f1).$(echo "$OS_VER" | cut -d. -f2)"
        # 如果找不到 hwe 包就用通用包
        apt-cache show "$pkg" > /dev/null 2>&1 || pkg="linux-image-generic"
    else
        pkg="linux-image-amd64"
    fi

    DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        return 0
    else
        # 兜底：直接升级现有内核相关包
        DEBIAN_FRONTEND=noninteractive apt-get install -y --only-upgrade linux-image-* > /dev/null 2>&1 || true
        return 0
    fi
}

# 升级内核（CentOS 7）
upgrade_kernel_centos() {
    echo -e "${BLUE}正在升级内核（ELRepo ML）...${PLAIN}"

    # 修复 CentOS 死源
    if [[ "$OS_VER" == "7" ]]; then
        mkdir -p /etc/yum.repos.d/backup
        mv /etc/yum.repos.d/CentOS-*.repo /etc/yum.repos.d/backup/ 2>/dev/null || true
        cat > /etc/yum.repos.d/CentOS-Vault.repo <<'EOF'
[base]
name=CentOS-7-Vault-Base
baseurl=https://mirrors.aliyun.com/centos-vault/7.9.2009/os/$basearch/
gpgcheck=0
enabled=1
[updates]
name=CentOS-7-Vault-Updates
baseurl=https://mirrors.aliyun.com/centos-vault/7.9.2009/updates/$basearch/
gpgcheck=0
enabled=1
[extras]
name=CentOS-7-Vault-Extras
baseurl=https://mirrors.aliyun.com/centos-vault/7.9.2009/extras/$basearch/
gpgcheck=0
enabled=1
EOF
        yum clean all > /dev/null 2>&1
    fi

    # 导入 ELRepo GPG
    rpm --import https://mirrors.aliyun.com/elrepo/RPM-GPG-KEY-elrepo.org > /dev/null 2>&1 || \
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org > /dev/null 2>&1 || true

    # 安装 ELRepo 源
    yum install -y https://mirrors.aliyun.com/elrepo/elrepo/el7/x86_64/RPMS/elrepo-release-7.0-6.el7.elrepo.noarch.rpm > /dev/null 2>&1 || \
    yum install -y https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm > /dev/null 2>&1

    yum clean all > /dev/null 2>&1
    yum --enablerepo=elrepo-kernel install -y kernel-ml kernel-ml-devel > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        grub2-set-default 0 > /dev/null 2>&1
        grub2-mkconfig -o /boot/grub2/grub.cfg > /dev/null 2>&1
        return 0
    else
        return 1
    fi
}

# BBR 主状态机
bbr_setup() {
    echo ""
    echo -e "${BLUE}正在检查 BBR 网络加速...${PLAIN}"

    # 已启用，直接跳过
    if check_bbr_status; then
        echo -e "${GREEN}✓ BBR 已启用，跳过配置${PLAIN}"
        return 0
    fi

    check_virt

    # 内核够用，直接启用
    if check_kernel_native_bbr; then
        enable_bbr
        return 0
    fi

    # 内核太旧，需要升级
    echo -e "${YELLOW}当前内核版本 $(uname -r) 不支持 BBR，需要升级内核${PLAIN}"
    echo -e "${BLUE}正在自动升级内核，预计需要 3-10 分钟...${PLAIN}"
    echo ""

    local upgrade_ok=0

    if [[ "$OS_ID" =~ debian|ubuntu ]]; then
        upgrade_kernel_debian && upgrade_ok=1
    elif [[ "$OS_ID" =~ centos|rhel ]]; then
        upgrade_kernel_centos && upgrade_ok=1
    else
        echo -e "${YELLOW}⚠️  当前系统不支持自动升级内核，跳过 BBR 配置${PLAIN}"
        return 0
    fi

    if [[ $upgrade_ok -eq 1 ]]; then
        echo ""
        echo -e "${GREEN}+===================================================+${PLAIN}"
        echo -e "${GREEN}|          ✓ 内核升级完成！                        |${PLAIN}"
        echo -e "${GREEN}+===================================================+${PLAIN}"
        echo -e "${GREEN}|  需要重启服务器才能使用新内核                    |${PLAIN}"
        echo -e "${GREEN}|                                                   |${PLAIN}"
        echo -e "${GREEN}|  👉 请执行以下命令重启：                         |${PLAIN}"
        echo -e "${GREEN}|                                                   |${PLAIN}"
        echo -e "${GREEN}|     reboot                                        |${PLAIN}"
        echo -e "${GREEN}|                                                   |${PLAIN}"
        echo -e "${GREEN}|  重启完成后：                                    |${PLAIN}"
        echo -e "${GREEN}|  按 ↑ 方向键找到上一条安装命令，回车继续安装    |${PLAIN}"
        echo -e "${GREEN}+===================================================+${PLAIN}"
        echo ""
        exit 0
    else
        echo -e "${YELLOW}⚠️  内核升级失败，跳过 BBR 配置，继续安装 NextLNMP${PLAIN}"
        echo -e "${YELLOW}   BBR 可稍后手动配置，不影响建站功能${PLAIN}"
        echo ""
    fi
}

# ====================================================================
# 步骤 9：三源容灾下载
# ====================================================================
download_tarball() {
    local urls=(
        "${MIRROR_URL}"
        "${GITEE_URL}"
        "${GITHUB_URL}"
    )
    local names=("镜像站（国内加速）" "Gitee" "GitHub")

    echo "正在下载 NextLNMP v${NEXTLNMP_VER} 安装包..."
    echo ""

    local downloaded=0

    for i in "${!urls[@]}"; do
        echo "  尝试线路 $((i+1))：${names[$i]} ..."
        if wget -q --timeout=30 --tries=2 -O "${TMP_FILE}" "${urls[$i]}" 2>/dev/null; then
            local fsize
            fsize=$(stat -c%s "${TMP_FILE}" 2>/dev/null || stat -f%z "${TMP_FILE}" 2>/dev/null || echo 0)
            if [[ ${fsize} -gt 102400 ]]; then
                echo "  ✓ 下载成功（$(( fsize / 1024 )) KB）"
                downloaded=1
                break
            else
                echo "  ✗ 文件异常，换下一条线路"
                rm -f "${TMP_FILE}"
            fi
        else
            echo "  ✗ 连接失败，换下一条线路"
        fi
    done

    echo ""

    if [[ ${downloaded} -eq 0 ]]; then
        echo "❌ 三条下载线路全部失败"
        echo ""
        echo "可能的原因："
        echo "  · 服务器无法访问外网"
        echo "  · DNS 解析有问题"
        echo "  · 服务商防火墙限制了出站流量"
        echo ""
        echo "👉 排查命令：ping -c 3 baidu.com"
        echo "👉 如需帮助请加 QQ群 615298"
        exit 1
    fi
}

# ====================================================================
# 步骤 10：SHA256 校验
# ====================================================================
verify_sha256() {
    echo "正在校验安装包完整性..."

    if [[ "${TARBALL_SHA256}" == "TO_BE_FILLED" ]]; then
        echo "⚠️  开发版本，跳过校验"
        return 0
    fi

    local actual
    actual=$(sha256sum "${TMP_FILE}" | awk '{print $1}')

    if [[ "${actual}" == "${TARBALL_SHA256}" ]]; then
        echo "✓ SHA256 校验通过，安装包未被篡改"
    else
        echo ""
        echo "❌ 安装包校验失败！文件可能被篡改或下载不完整"
        echo ""
        echo "期望值：${TARBALL_SHA256}"
        echo "实际值：${actual}"
        echo ""
        echo "👉 重新运行一次安装命令通常可解决"
        echo "👉 如需帮助请加 QQ群 615298"
        rm -f "${TMP_FILE}"
        exit 1
    fi
}

# ====================================================================
# 步骤 11：解压并启动主安装向导
# ====================================================================
extract_and_run() {
    if [[ -d "${INSTALL_DIR}" ]]; then
        local backup="${INSTALL_DIR}.bak.$(date +%Y%m%d%H%M%S)"
        echo "检测到旧版本，自动备份到 ${backup} ..."
        mv "${INSTALL_DIR}" "${backup}"
        echo "✓ 旧版本已备份"
    fi

    echo "正在解压安装包..."
    mkdir -p "${INSTALL_DIR}"

    if tar xzf "${TMP_FILE}" -C "${INSTALL_DIR}" --strip-components=1 2>/dev/null; then
        echo "✓ 解压完成"
    elif tar xzf "${TMP_FILE}" -C "${INSTALL_DIR}" 2>/dev/null; then
        echo "✓ 解压完成"
    else
        echo ""
        echo "❌ 解压失败，安装包可能已损坏"
        echo "👉 重新运行一次安装命令试试"
        echo "👉 如需帮助请加 QQ群 615298"
        rm -f "${TMP_FILE}"
        exit 1
    fi

    rm -f "${TMP_FILE}"

    cd "${INSTALL_DIR}"
    local main_script=""
    for candidate in nextlnmp.sh lnmp.sh; do
        if [[ -f "${candidate}" ]]; then
            main_script="${candidate}"
            break
        fi
    done

    if [[ -z "${main_script}" ]]; then
        echo ""
        echo "❌ 安装包里没找到主程序"
        echo "👉 重新运行一次安装命令"
        echo "👉 如需帮助请加 QQ群 615298"
        exit 1
    fi

    chmod +x "${main_script}"

    echo ""
    echo "==========================================="
    echo "  ✓ 一切就绪，即将启动安装向导"
    echo ""
    echo "  安装目录：${INSTALL_DIR}"
    echo "  技术支持：QQ群 615298"
    echo "==========================================="
    echo ""

    sleep 2

    bash "${INSTALL_DIR}/${main_script}"
}

# ====================================================================
# 主流程
# ====================================================================
main() {
    check_root          # 1. root 权限检查
    detect_pkg_mgr      # 2. 快速判断 yum / apt
    install_deps        # 3. 安装基础依赖（含 git）
    check_os            # 4. 系统识别
    print_logo          # 5. 显示品牌 LOGO
    check_env           # 6. 环境预检
    system_update       # 7. 系统全量更新
    bbr_setup           # 8. BBR 状态机
    download_tarball    # 9. 三源容灾下载
    verify_sha256       # 10. SHA256 校验
    extract_and_run     # 11. 解压并启动主向导
}

main "$@"
