#!/usr/bin/env bash
# ============================================================================
# nextLNMP 一键安装引导脚本 v1.1.0
# 用法：bash <(curl -sL https://gitee.com/palmmedia/nextlnmp/raw/main/install.sh)
# 项目：https://github.com/adsorgcn/nextlnmp
# 作者：静水流深 · 掌媒科技有限公司
# 授权：GPL-3.0
# ============================================================================

set -euo pipefail

# ── 版本与配置（每次发版更新这两个值）─────────────────────────────────
NEXTLNMP_VER="1.1.0"
TARBALL_SHA256="207d89854f14090949e5346bb871cfbe6c1c08709a160f09ed177d58d224291d"

# ── 固定配置 ──────────────────────────────────────────────────────────
INSTALL_DIR="/root/nextlnmp"
TMP_FILE="/tmp/nextlnmp-${NEXTLNMP_VER}.tar.gz"

# ── 下载源（按优先级）────────────────────────────────────────────────
MIRROR_URL="https://mirror.zhangmei.com/nextlnmp-${NEXTLNMP_VER}.tar.gz"
GITEE_URL="https://gitee.com/palmmedia/nextlnmp/releases/download/v${NEXTLNMP_VER}/nextlnmp-${NEXTLNMP_VER}.tar.gz"
GITHUB_URL="https://github.com/adsorgcn/nextlnmp/releases/download/v${NEXTLNMP_VER}/nextlnmp-${NEXTLNMP_VER}.tar.gz"

# ====================================================================
# 步骤 1：root 权限检查
# ====================================================================
check_root() {
    if [[ $EUID -ne 0 ]]; then
        # 有 sudo 就自动提权，用户零感知
        if command -v sudo &>/dev/null; then
            exec sudo bash "$0" "$@"
        fi
        # 没有 sudo，大白话引导
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
        echo "❌ 无法识别你的系统，nextLNMP 支持 CentOS / Ubuntu / Debian"
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

    # 全都有，直接跳过
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

    # 装完再验一遍
    for cmd in wget tar curl sha256sum; do
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
# 步骤 4：显示 LOGO
# ====================================================================
print_logo() {
    clear
    echo ""
    echo "  ╔═══════════════════════════════════════════════╗"
    echo "  ║         nextLNMP 一键建站安装程序              ║"
    echo "  ║         安全可信 · SHA256逐包校验              ║"
    echo "  ╠═══════════════════════════════════════════════╣"
    echo "  ║  版本：v${NEXTLNMP_VER}                                 ║"
    echo "  ║  官网：https://cnwebmasters.com               ║"
    echo "  ║  QQ群：615298                                 ║"
    echo "  ║  作者：静水流深 · 掌媒科技有限公司               ║"
    echo "  ╚═══════════════════════════════════════════════╝"
    echo ""
}

# ====================================================================
# 步骤 5：系统详细识别
# ====================================================================
check_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_ID="${ID,,}"
        OS_VER="${VERSION_ID}"
    elif [[ -f /etc/redhat-release ]]; then
        OS_ID="centos"
        OS_VER=$(grep -oP '\d+' /etc/redhat-release | head -1)
    else
        echo ""
        echo "❌ 无法识别你的操作系统"
        echo ""
        echo "nextLNMP 目前支持以下系统："
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
# 步骤 6：环境预检（只警告不阻断）
# ====================================================================
check_env() {
    echo ""
    echo "正在检查服务器环境..."

    # 内存检查
    local mem_mb
    mem_mb=$(free -m | awk '/Mem:/{print $2}')
    if [[ ${mem_mb} -lt 512 ]]; then
        echo ""
        echo "⚠️  内存较低：${mem_mb}MB（建议至少 512MB）"
        echo "   内存太小可能导致编译 PHP/MySQL 时失败"
        echo "   如果安装中途卡住，可以考虑升级 VPS 配置"
        echo ""
    else
        echo "✓ 内存：${mem_mb}MB"
    fi

    # 磁盘检查
    local disk_gb
    disk_gb=$(df -BG / | awk 'NR==2{print int($4)}')
    if [[ ${disk_gb} -lt 5 ]]; then
        echo ""
        echo "⚠️  磁盘剩余空间较小：${disk_gb}GB（建议至少 5GB）"
        echo "   编译安装 LNMP 大约需要 3-5GB 空间"
        echo "   如果空间不够，可以清理旧文件或升级磁盘"
        echo ""
    else
        echo "✓ 磁盘可用：${disk_gb}GB"
    fi

    # 80端口检查
    if ss -tlnp 2>/dev/null | grep -q ':80 '; then
        local proc_80
        proc_80=$(ss -tlnp | grep ':80 ' | grep -oP 'users:\(\("\K[^"]+' | head -1)
        echo ""
        echo "⚠️  80 端口被占用（${proc_80:-未知进程}）"
        echo "   Nginx 需要使用 80 端口，安装前建议先停掉占用的服务"
        echo "   停止 Apache：systemctl stop httpd"
        echo "   停止 Nginx： systemctl stop nginx"
        echo ""
    else
        echo "✓ 80 端口空闲"
    fi

    # 443端口检查
    if ss -tlnp 2>/dev/null | grep -q ':443 '; then
        echo "⚠️  443 端口被占用，安装后 HTTPS 可能冲突"
    else
        echo "✓ 443 端口空闲"
    fi

    echo ""
}

# ====================================================================
# 步骤 7：三源容灾下载
# ====================================================================
download_tarball() {
    local urls=(
        "${MIRROR_URL}"
        "${GITEE_URL}"
        "${GITHUB_URL}"
    )
    local names=("镜像站（国内加速）" "Gitee" "GitHub")

    echo "正在下载 nextLNMP v${NEXTLNMP_VER} 安装包..."
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
        echo "  · 服务器无法访问外网（检查一下能不能 ping 通 baidu.com）"
        echo "  · DNS 解析有问题"
        echo "  · 服务商的防火墙限制了出站流量"
        echo ""
        echo "👉 排查命令："
        echo ""
        echo "   ping -c 3 baidu.com"
        echo ""
        echo "👉 如果 ping 不通，联系你的 VPS 服务商检查网络"
        echo "👉 如果 ping 得通但还是下载失败，截图发 QQ群 615298"
        exit 1
    fi
}

# ====================================================================
# 步骤 8：SHA256 校验
# ====================================================================
verify_sha256() {
    echo "正在校验安装包完整性..."

    # 开发阶段跳过
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
        echo "👉 最简单的解决办法：重新运行一次安装命令"
        echo "   大部分情况是网络波动导致下载不完整，重跑就好了"
        echo ""
        echo "👉 如果重跑还是失败，说明下载源可能有问题"
        echo "   截图发 QQ群 615298，我们帮你排查"
        echo ""
        rm -f "${TMP_FILE}"
        exit 1
    fi
}

# ====================================================================
# 步骤 9：解压并启动主安装向导
# ====================================================================
extract_and_run() {
    # 检测旧安装目录
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
        echo ""
        echo "👉 重新运行一次安装命令试试，通常重跑就能解决"
        echo "👉 还是不行就截图发 QQ群 615298"
        rm -f "${TMP_FILE}"
        exit 1
    fi

    # 清理临时文件
    rm -f "${TMP_FILE}"

    # 找主安装脚本
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
        echo "❌ 安装包里没找到主程序，可能下载到了错误的文件"
        echo ""
        echo "👉 重新运行一次安装命令"
        echo "👉 还是不行就截图发 QQ群 615298"
        exit 1
    fi

    chmod +x "${main_script}"

    echo ""
    echo "═══════════════════════════════════════════"
    echo "  ✓ 一切就绪，即将启动安装向导"
    echo ""
    echo "  安装目录：${INSTALL_DIR}"
    echo "  技术支持：QQ群 615298"
    echo "═══════════════════════════════════════════"
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
    install_deps         # 3. 安装基础依赖
    print_logo           # 4. 显示品牌 LOGO
    check_os             # 5. 系统详细识别
    check_env            # 6. 环境预检
    download_tarball     # 7. 三源容灾下载
    verify_sha256        # 8. SHA256 校验
    extract_and_run      # 9. 解压并启动主向导
}

main "$@"
