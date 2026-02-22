# nextLNMP

<div align="center">

![Version](https://img.shields.io/badge/version-1.1.1-blue.svg)
![License](https://img.shields.io/badge/license-GPL--3.0-green.svg)
![System](https://img.shields.io/badge/system-CentOS%20|%20Ubuntu%20|%20Debian-orange.svg)
![PHP](https://img.shields.io/badge/PHP-5.6~8.4-purple.svg)

**安全、干净、可信赖的 LNMP 一键安装方案**

所有源码包从官方上游获取，SHA256 逐包校验，杜绝供应链投毒

[快速开始](#-快速开始) · [为什么需要 nextLNMP](#-为什么需要-nextlnmp) · [功能特性](#-功能特性) · [技术支持](#-技术支持)

</div>

---

## 📖 项目介绍

国内最流行的 LNMP 一键安装脚本，你一定用过或者听过。

但你可能不知道的是：**它已经被收购了。**

原作者早已不再维护，域名和下载站易主，新的运营方身份不明。你从那个下载站拉下来的源码包，到底有没有被动过手脚？没有人知道，因为**整个下载过程没有任何校验机制**。

这不是阴谋论，这是供应链安全的基本常识。

nextLNMP 就是为了解决这个问题而生的：

- **所有源码包从官方上游获取** — php.net、nginx.org、cdn.mysql.com，不经过任何第三方
- **SHA256 逐包校验** — 每个包下载后自动比对哈希，被篡改立即终止安装
- **校验清单公开可审计** — 任何人都可以独立验证
- **自建镜像站，HTTPS 加密传输** — 你下载的每一个字节都是可追溯的

**一句话：** 同样的功能，但你能信任它。

## ⚡ 快速开始

**方式一：一行命令安装（推荐）**

自动检测网络，三源容灾，哪个快用哪个：

```bash
bash <(curl -sL https://gitee.com/palmmedia/nextlnmp/raw/main/install.sh)
```

**方式二：从 Gitee 下载安装（国内快）**

```bash
wget https://gitee.com/palmmedia/nextlnmp/releases/download/v1.1.1/nextlnmp-1.1.1.tar.gz && tar zxf nextlnmp-1.1.1.tar.gz && cd nextlnmp-1.1.1 && bash install.sh
```

**方式三：从 GitHub 下载安装**

```bash
wget https://github.com/adsorgcn/nextlnmp/releases/download/v1.1.1/nextlnmp-1.1.1.tar.gz && tar zxf nextlnmp-1.1.1.tar.gz && cd nextlnmp-1.1.1 && bash install.sh
```

三种方式装出来的东西完全一样，选哪个都行。

根据菜单提示选择 PHP、MySQL 版本，剩下的交给脚本。全程无需手动干预，编译安装完成后自动启动服务。

## 🛡️ 为什么需要 nextLNMP

### 安全对比

| 对比项 | 某流行同类工具 | nextLNMP |
|--------|---------------|----------|
| **源码来源** | ❌ 私有镜像站，已易主，来源不透明 | ✅ 官方上游（php.net / nginx.org / cdn.mysql.com） |
| **下载校验** | ❌ 零校验，下什么装什么 | ✅ SHA256 逐包校验，篡改立即终止 |
| **校验清单** | ❌ 无 | ✅ 公开可审计 |
| **代码透明** | ❌ 下载站闭源 | ✅ 完整开源，GPL-3.0 协议 |
| **镜像站** | ❌ 域名归属不明 | ✅ 自建镜像站，HTTPS 加密 |
| **维护状态** | ❌ 原作者已离场 | ✅ 持续维护更新 |

### 版本够新

- **PHP 8.4.18** — 首发支持，2024年11月发布的最新大版本
- **MySQL 8.4** — LTS 长期支持版本
- **Nginx 1.26** — 稳定分支最新版
- 同时保留 PHP 5.6 ~ 8.3、MySQL 5.1 ~ 8.0 全版本可选，老项目无缝迁移

### 老用户零学习成本

用过同类工具的站长，上手 nextLNMP 没有任何门槛。安装流程、目录结构、管理命令，都是你熟悉的方式。

唯一的区别：这次你可以放心用了。

## ✨ 功能特性

### 🚀 安装模式

| 模式 | 说明 | 适用场景 |
|------|------|---------|
| **LNMP** | Nginx + MySQL + PHP | 绝大多数网站（WordPress、Laravel、ThinkPHP） |
| **LNMPA** | Nginx + Apache + MySQL + PHP | 需要 .htaccess 的项目 |
| **LAMP** | Apache + MySQL + PHP | 传统 Apache 环境 |

### 📦 支持的软件版本

| 软件 | 可选版本 |
|------|---------|
| **Nginx** | 1.26.0 |
| **PHP** | 5.6 / 7.0 / 7.1 / 7.2 / 7.3 / 7.4 / 8.0 / 8.1 / 8.2 / 8.3 / **8.4** |
| **MySQL** | 5.1 / 5.5 / 5.6 / 5.7 / 8.0 / 8.4 |
| **MariaDB** | 5.5 / 10.4 / 10.5 / 10.6 / 10.11 |
| **phpMyAdmin** | 4.0 / 4.9 / 5.2 |
| **Apache** | 2.2 / 2.4（LNMPA/LAMP 模式） |

### 🔧 PHP 扩展

开箱即支持：OPcache / Redis / Memcached / ImageMagick / Swoole / APCu / ionCube / Sodium

### 🛠️ 管理工具

```bash
# 服务管理
nextlnmp start|stop|restart|status

# 升级组件（Nginx/PHP/MySQL 独立升级）
bash upgrade.sh

# 虚拟主机管理
bash addons.sh

# 数据库备份
bash tools/backup.sh

# 重置 MySQL 密码
bash tools/reset_mysql_root_password.sh

# Nginx 日志切割
bash tools/cut_nginx_logs.sh
```

### 🌐 系统支持

| 系统 | 版本 | 状态 |
|------|------|------|
| **CentOS** | 7 / 8 / 9 | ✅ 支持 |
| **RHEL** | 7 / 8 / 9 | ✅ 支持 |
| **Ubuntu** | 20.04 / 22.04 / 24.04 | ✅ 支持 |
| **Debian** | 10 / 11 / 12 | ✅ 支持 |

**系统要求：** 内存 ≥ 512MB，磁盘 ≥ 5GB

## 🔒 安全机制详解

nextLNMP 的安全不是一句口号，是工程化落地的完整方案：

```
用户执行 install.sh
    ↓
检测镜像站连通性（HTTPS）
    ↓
下载 sha256sums.txt（校验清单，60个包全覆盖）
    ↓
逐个下载源码包
    ↓
每个包下载后，计算 SHA256 并与清单比对
    ↓
✅ 匹配 → 继续安装
❌ 不匹配 → 删除可疑文件，立即终止
```

**镜像站：** `https://mirror.zhangmei.com`

- ✅ 部署于阿里云国内节点，采用企业级 CDN 加速分发架构，全程 HTTPS 加密传输，下载速度与稳定性均经过生产环境验证
- ✅ 仅允许下载源码包格式（.tar.gz / .tar.bz2 / .tar.xz / .tgz）
- ✅ 禁止目录遍历，防止信息泄露
- ✅ 60 个源码包，全部可溯源至官方发布页
- ✅ sha256sums.txt 公开访问，任何人可独立审计

## 📂 目录结构

```
nextlnmp-1.1.1/
├── install.sh          # 安装入口
├── nextlnmp.conf       # 配置文件（镜像源地址等）
├── upgrade.sh          # 升级脚本
├── uninstall.sh        # 卸载脚本
├── addons.sh           # 扩展管理（虚拟主机、FTP 等）
├── include/            # 核心安装脚本
│   ├── main.sh         # 公共函数（含 SHA256 校验逻辑）
│   ├── version.sh      # 所有软件版本号定义
│   ├── init.sh         # 系统初始化与依赖安装
│   ├── nginx.sh        # Nginx 编译安装
│   ├── php.sh          # PHP 编译安装
│   ├── mysql.sh        # MySQL 编译安装
│   └── ...
├── conf/               # Nginx/Apache/PHP 配置模板
├── init.d/             # systemd 服务文件
├── tools/              # 备份、日志切割等运维工具
└── src/                # 编译补丁文件
```

## ❓ 常见问题

<details>
<summary><b>Q1: nextLNMP 和某流行工具有什么区别？</b></summary>

功能上几乎一样，核心区别在于安全：

- nextLNMP 所有源码包从 php.net、nginx.org 等官方上游获取
- 每个包下载后 SHA256 校验，防篡改
- 代码完全开源，GPL-3.0 协议
- 某流行工具的下载站已易主，无校验机制

如果你在乎服务器安全，nextLNMP 是更好的选择。
</details>

<details>
<summary><b>Q2: 从旧工具迁移到 nextLNMP 需要重装吗？</b></summary>

如果你已经用其他工具装好了环境，不需要重装。nextLNMP 主要面向新服务器部署。

已有环境可以继续用，但如果你要新开服务器，强烈建议用 nextLNMP。
</details>

<details>
<summary><b>Q3: 支持 PHP 8.4 吗？</b></summary>

支持。nextLNMP v1.0.0 首发支持 PHP 8.4.18，这是目前最新的稳定版本。

安装时选择菜单中的第 15 项即可。
</details>

<details>
<summary><b>Q4: 镜像站在哪里？可靠吗？</b></summary>

镜像站 `mirror.zhangmei.com` 部署于阿里云国内节点，采用企业级 CDN 加速分发架构，全程 HTTPS 加密传输，下载速度与稳定性均经过生产环境验证。

所有文件均从官方上游获取后存放，SHA256 校验清单公开可查。你也可以自行从官方下载同版本源码包，对比哈希值独立验证。
</details>

<details>
<summary><b>Q5: 可以用于生产环境吗？</b></summary>

可以。nextLNMP 的安装逻辑经过长期验证，稳定可靠。SHA256 校验机制进一步保障了生产环境的安全性。

建议：
- 先在测试环境验证
- 选择业务低峰期操作
- 安装前做好数据备份
</details>

<details>
<summary><b>Q6: 开源版和商业版有什么区别？</b></summary>

nextLNMP 采用 GPL-3.0 + 商业双授权模式：

- **开源版（GPL-3.0）**：个人站长、独立开发者免费使用，需遵守 GPL-3.0 协议条款
- **商业授权**：企业集成、云服务商、主机面板厂商批量部署，需向掌媒科技购买商业授权

如需商业授权，请通过 QQ群 615298 联系。
</details>

## 🔄 更新日志

### v1.1.0 (2026-02-22)
- 🚀 新增一行 `curl` 安装命令，复制粘贴即装
- 🔄 三源容灾下载（镜像站 → Gitee → GitHub），自动切换最快源
- 🔒 安装包 SHA256 完整性校验，防篡改
- 🖥️ 系统环境预检（内存 / 磁盘 / 端口），只警告不阻断
- 🛡️ root 权限检查，无权限大白话引导提权
- 📦 包管理器自动识别（yum / apt-get），基础依赖自动安装
- 🔄 旧版本自动备份，升级无忧
- 🇨🇳 全中文错误提示，出错告诉你怎么解决

### v1.0.0 (2026-02-22)
- 🎉 首次发布
- ✅ 全部源码包从官方上游获取，SHA256 逐包校验
- ✅ 自建 HTTPS 镜像站，60 个源码包全覆盖
- ✅ 新增 PHP 8.4.18 支持
- ✅ 简化镜像检测逻辑，移除冗余回退代码
- ✅ 全新品牌，GPL-3.0 + 商业双授权

## 📞 技术支持

- **QQ群：** 615298
- **作者：** 静水流深
- **网站：** [中国站长](https://cnwebmasters.com)
- **问题反馈：** [Gitee Issues](https://gitee.com/palmmedia/nextlnmp/issues) · [GitHub Issues](https://github.com/adsorgcn/nextlnmp/issues)

## 🤝 相关项目

同系列开源工具，覆盖 Linux 服务器从检测到部署的全链路：

| 项目 | 用途 | 链接 |
|------|------|------|
| **VPSCheck** | VPS 全能检测（流媒体/AI/回程/跑分） | [GitHub](https://github.com/adsorgcn/vpscheck) · [Gitee](https://gitee.com/palmmedia/vpscheck) |
| **BBR 一键加速** | Google BBR 拥塞控制一键开启 | [GitHub](https://github.com/adsorgcn/bbr-script) · [Gitee](https://gitee.com/palmmedia/bbr-script) |
| **nextLNMP** | 安全可信的 LNMP 一键安装（本项目） | [GitHub](https://github.com/adsorgcn/nextlnmp) · [Gitee](https://gitee.com/palmmedia/nextlnmp) |

**推荐部署流程：** VPSCheck 检测 → BBR 加速 → nextLNMP 部署

## 📜 开源协议

本项目采用 **GPL-3.0 + 商业双授权**模式：

- 个人站长、独立开发者：[GPL-3.0](LICENSE) 免费使用
- 企业/云服务商/主机商集成：需向 **掌媒科技有限公司** 购买商业授权

参考案例：MySQL、MariaDB、Qt 均采用相同授权模式。

Copyright © 2026 掌媒科技有限公司. All rights reserved.

---

<div align="center">

**如果这个项目对你有帮助，请给个 ⭐ Star 支持一下！**

👉 [Gitee](https://gitee.com/palmmedia/nextlnmp) · [GitHub](https://github.com/adsorgcn/nextlnmp)

Made with ❤️ by 静水流深 | 掌媒科技有限公司

</div>

### v1.1.1 (2026-02-22)
- 新增 GitHub Actions 自动化发版，推 tag 即出 Release，无需手动打包
- 新增 .gitignore，杜绝 tarball 误入库
- 清理仓库历史遗留问题（submodule 残留、误提交文件）
- install.sh 中 SHA256 改由 CI 自动回写，发版更安全可靠
