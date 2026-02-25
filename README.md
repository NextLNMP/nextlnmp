# NextLNMP

<div align="center">

![Version](https://img.shields.io/badge/version-1.5.6-blue.svg)
![License](https://img.shields.io/badge/license-GPL--3.0-green.svg)
![System](https://img.shields.io/badge/system-CentOS%20|%20Ubuntu%20|%20Debian-orange.svg)
![PHP](https://img.shields.io/badge/PHP-5.6~8.4-purple.svg)

**安全、干净、可信赖的 LNMP 一键安装方案**

所有源码包从官方上游获取，SHA256 逐包校验，杜绝供应链投毒

[快速开始](#-快速开始) · [为什么需要 NextLNMP](#-为什么需要-nextlnmp) · [功能特性](#-功能特性) · [推荐服务器](#-推荐服务器) · [技术支持](#-技术支持)

</div>

---

## 📖 项目介绍

军哥的 LNMP 一键安装包，是中国站长圈一代人的共同记忆。

从 2005 年开始，无数个人站长、小团队靠着那一行命令，在自己的服务器上搭起了第一个网站。它足够简单、足够稳定，十几年来口碑相传，几乎成了 Linux 建站的代名词。这份贡献，值得被认真致敬。

但时代变了。

原作者已退出，项目转手易主。下载站域名归属不明，源码包来自何处无从追溯，整个安装过程没有任何完整性校验——你装进服务器的东西，没有人能保证它是干净的。2024 年前后，国内已有多起 LNMP 类工具供应链投毒事件被曝光，服务器在安装环境的那一刻就已沦陷。

与此同时，AI 时代带来了新的可能。工程工具可以被重新设计，流程可以被重新审视，很多过去靠经验积累的东西，现在可以用更系统的方式重建。

**NextLNMP 就是在这个背景下诞生的。**

我们从零重写，不是为了另起炉灶，而是为了给这件事一个值得信任的答案。

---

### 为什么不用宝塔？

宝塔面板在可视化和插件生态上做得不错，但它解决不了一些根本性的问题：

| | 宝塔面板 | NextLNMP |
|---|---|---|
| **实名安装** | ❌ 强制手机号注册，否则功能受限 | ✅ 无需注册，无需实名，服务器是你的 |
| **系统占用** | ❌ 常驻后台进程，持续占用内存和 CPU | ✅ 零后台进程，装完不留任何守护程序 |
| **源码来源** | ❌ 软件包来源不透明，"纯净版"内容无从核实 | ✅ 全部来自官方上游（php.net / nginx.org / cdn.mysql.com） |
| **完整性校验** | ❌ 无 SHA256 校验 | ✅ 逐包 SHA256 校验，篡改立即终止 |
| **代码可审计** | ❌ 核心模块闭源 | ✅ 完整开源，GPL-3.0 协议 |
| **隐私风险** | ❌ 面板与宝塔服务器保持通信 | ✅ 纯本地运行，无任何外联行为 |

宝塔的纯净版，你依然不知道里面装了什么。NextLNMP 的每一行代码，你都可以在 GitHub 上读到。

---

### NextLNMP 能做什么

- 🚀 **急速安装**：Ubuntu 22.04 / Debian 12 推荐系统，PHP Binary 预编译包直接解压，全程约 **5 分钟**完成 LNMP 环境部署
- 🛡️ **安全可信**：所有源码包 SHA256 逐包校验，自建 HTTPS 镜像站，校验清单公开可审计
- 🧠 **智能推荐**：自动检测硬件配置，推荐最佳 PHP / MySQL / 内存分配器组合
- ⚙️ **自动优化**：安装后根据内存自动调整 MySQL my.cnf，开箱即用
- 🌐 **BBR 加速**：自动检测内核版本，一键启用 BBR 拥塞控制，提升网络吞吐
- 📋 **信息持久化**：安装完成后关键信息自动保存，随时 `nextlnmp info` 查看密码和访问地址
- 🔄 **零学习成本**：目录结构、管理命令与同类工具完全兼容，老用户无缝切换
- 📦 **版本丰富**：PHP 5.6 ~ 8.4、MySQL 5.1 ~ 8.4 全版本可选，新老项目全覆盖
- 🖥️ **即将支持**：一键迁移工具、可视化管理界面（规划中）

---

### 架构支持

| 架构 | 状态 | 说明 |
|------|------|------|
| **x86_64** | ✅ 完整支持 | 急速安装模式（Binary 包，< 1分钟）+ 源码编译双模式 |
| **ARM64 / aarch64** | 🔄 源码编译支持 | 自动回退源码编译，功能完整，约 30 分钟 |
| **ARM64 急速模式** | 🗓️ 规划中 | ARM64 Binary 预编译包，有机器即上线 |

> 腾讯云、阿里云、AWS 的 ARM 实例（如 Graviton）均可正常安装，使用源码编译模式。

## ⚡ 快速开始

**方式一：一行命令安装（推荐）**

自动检测网络，三源容灾，哪个快用哪个：

```bash
bash <(curl -sL https://gitee.com/palmmedia/nextlnmp/raw/main/install.sh)
```

**方式二：从 Gitee 下载安装（国内快）**

```bash
wget https://gitee.com/palmmedia/nextlnmp/releases/download/v1.5.6/nextlnmp-1.5.6.tar.gz && tar zxf nextlnmp-1.5.6.tar.gz && cd nextlnmp-1.5.6 && bash install.sh
```

**方式三：从 GitHub 下载安装**

```bash
wget https://github.com/NextLNMP/nextlnmp/releases/download/v1.5.6/nextlnmp-1.5.6.tar.gz && tar zxf nextlnmp-1.5.6.tar.gz && cd nextlnmp-1.5.6 && bash install.sh
```

三种方式装出来的东西完全一样，选哪个都行。

根据菜单提示选择 PHP、MySQL 版本，剩下的交给脚本。全程无需手动干预，编译安装完成后自动启动服务。

## 🛡️ 为什么需要 NextLNMP

### 安全对比

| 对比项 | 某流行同类工具 | NextLNMP |
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

用过同类工具的站长，上手 NextLNMP 没有任何门槛。安装流程、目录结构、管理命令，都是你熟悉的方式。

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

# 查看安装信息（密码、访问地址、目录）
nextlnmp info

# 查看/删除数据库密码
nextlnmp password
nextlnmp password --delete

# 虚拟主机管理
nextlnmp vhost add

# 升级组件（Nginx/PHP/MySQL 独立升级）
bash upgrade.sh

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

> 🚀 **急速安装推荐：** Ubuntu 22.04 LTS / Debian 12 享受 PHP Binary 预编译包，安装时间 **< 1分钟**，全程约 **5分钟** 完成 NextLNMP 部署。其他系统自动回退源码编译。

**系统要求：** 内存 ≥ 512MB，磁盘 ≥ 5GB

## 🔒 安全机制详解

NextLNMP 的安全不是一句口号，是工程化落地的完整方案：

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

- ✅ 部署于阿里云国内节点，全程 HTTPS 加密传输
- ✅ 仅允许下载源码包格式（.tar.gz / .tar.bz2 / .tar.xz / .tgz）
- ✅ 禁止目录遍历，防止信息泄露
- ✅ 60 个源码包，全部可溯源至官方发布页
- ✅ sha256sums.txt 公开访问，任何人可独立审计

## 🖥️ 推荐服务器

新手最大的困惑往往不是怎么装，而是**该买哪家服务器**。以下是根据不同使用场景的真实推荐，买错了机器后面一堆麻烦。

---

### 🇨🇳 国内建站（需要备案）

**阿里云轻量应用服务器** — 首推新手

> 阿里云是国内云计算头部厂商，稳定性和售后保障行业最好。轻量应用服务器性价比高，2核2G配置足够跑 WordPress / Typecho / 小型商城。新人专享价格极具优势，国内建站首选。

👉 [阿里云新人专享：2核2G，200M峰值带宽，￥38/年起](https://www.aliyun.com/minisite/goods?userCode=o2dbvmex)

---

**腾讯云** — 微信生态首选

> 如果你的业务涉及微信公众号、小程序、企业微信，腾讯云与微信生态打通最深，COS 对象存储、CDN、短信服务配合使用体验最佳。

👉 [腾讯云特惠：云服务器、COS、CDN 等云产品热卖中](https://cloud.tencent.com/act/cps/redirect?redirect=2446&cps_key=42de16263794923a5b0c19c60790f9e3&from=console)

---

### 🌍 海外建站（无需备案）

**Vultr** — 新手友好，按小时计费

> 全球多节点，洛杉矶/新加坡/日本均有机房，支持支付宝付款，按小时计费随时删机不浪费。界面简单，新手上手快。**必须通过邀请链接注册，新用户可获得 300 美元免费额度**（需绑定信用卡或 PayPal，30天内使用）。

👉 [Vultr 注册领 300 美元：通过此邀请链接才可获得](https://www.vultr.com/?ref=9631926-9J)

---

**搬瓦工** — 中国线路最稳定

> 老牌海外 VPS 商，DC5 SLA 机房三网 CN2 GIA 优质线路，延迟低、不丢包，适合对中国访问速度有要求的海外站。每两周可免费换一次 IP，硬件性能强悍，99.99% SLA 在线时间保证。
>
> 最新优惠码：**NODESEEK2026**（优惠力度 6.77%）

👉 [搬瓦工 DC5 SLA 套餐：2核 AMD，1G内存，2.5Gbps 带宽](https://bwh81.net/aff.php?aff=20308&pid=164)

---

**DMIT** — 高端线路首选

> 洛杉矶 Pro 系列，三网 CN2-GIA 回程，最高带宽可达 10Gbps，适合对速度和稳定性要求极高的场景（直播、跨境电商、游戏加速）。价格偏高但线路质量一流。

👉 [DMIT 洛杉矶 Pro：三网 CN2-GIA，最高 10Gbps 带宽](https://www.dmit.io/aff.php?aff=3138&pid=100)

---

> 💡 **选机器建议：** 国内有备案选阿里云/腾讯云；海外无备案优先 Vultr（便宜好上手）；对国内访问速度有要求选搬瓦工或 DMIT。1核1G 够跑个人博客，2核2G 可以跑 WordPress + 插件，4核4G 可以跑多个站。

## 📂 目录结构

```
nextlnmp-1.5.6/
├── install.sh          # 安装入口
├── nextlnmp.conf       # 配置文件（镜像源地址等）
├── upgrade.sh          # 升级脚本
├── uninstall.sh        # 卸载脚本
├── addons.sh           # 扩展管理（虚拟主机、FTP 等）
├── sha256sums.txt      # PHP Binary 包 SHA256 校验清单
├── include/            # 核心安装脚本
│   ├── main.sh         # 公共函数（含 SHA256 校验逻辑）
│   ├── version.sh      # 所有软件版本号定义
│   ├── init.sh         # 系统初始化与依赖安装
│   ├── nginx.sh        # Nginx 编译安装
│   ├── php.sh          # PHP 编译安装（支持 Binary 急速模式）
│   ├── mysql.sh        # MySQL 编译安装
│   └── ...
├── conf/               # Nginx/Apache/PHP 配置模板
├── init.d/             # systemd 服务文件
├── tools/              # 备份、日志切割等运维工具
└── src/                # 编译补丁文件
```

## ❓ 常见问题

<details>
<summary><b>Q1: NextLNMP 和某流行工具有什么区别？</b></summary>

功能上几乎一样，核心区别在于安全：

- NextLNMP 所有源码包从 php.net、nginx.org 等官方上游获取
- 每个包下载后 SHA256 校验，防篡改
- 代码完全开源，GPL-3.0 协议
- 某流行工具的下载站已易主，无校验机制

如果你在乎服务器安全，NextLNMP 是更好的选择。
</details>

<details>
<summary><b>Q2: 从旧工具迁移到 NextLNMP 需要重装吗？</b></summary>

如果你已经用其他工具装好了环境，不需要重装。NextLNMP 主要面向新服务器部署。

已有环境可以继续用，但如果你要新开服务器，强烈建议用 NextLNMP。
</details>

<details>
<summary><b>Q3: 支持 PHP 8.4 吗？</b></summary>

支持。NextLNMP 首发支持 PHP 8.4，这是目前最新的稳定版本。

安装时选择菜单中的对应版本即可。
</details>

<details>
<summary><b>Q4: 镜像站在哪里？可靠吗？</b></summary>

镜像站 `mirror.zhangmei.com` 部署于阿里云国内节点，全程 HTTPS 加密传输。

所有文件均从官方上游获取后存放，SHA256 校验清单公开可查。你也可以自行从官方下载同版本源码包，对比哈希值独立验证。
</details>

<details>
<summary><b>Q5: 可以用于生产环境吗？</b></summary>

可以。NextLNMP 的安装逻辑经过长期验证，稳定可靠。SHA256 校验机制进一步保障了生产环境的安全性。

建议：先在测试环境验证，选择业务低峰期操作，安装前做好数据备份。
</details>

<details>
<summary><b>Q6: 开源版和商业版有什么区别？</b></summary>

NextLNMP 采用 GPL-3.0 + 商业双授权模式：

- **开源版（GPL-3.0）**：个人站长、独立开发者免费使用，需遵守 GPL-3.0 协议条款
- **商业授权**：企业集成、云服务商、主机面板厂商批量部署，需向掌媒科技购买商业授权

如需商业授权，请通过 QQ群 615298 联系。
</details>

## 🔄 更新日志

### v1.5.6 (2025-02-25)

### Bug 修复
- 修复 vhost del 删除站点后未 reload nginx 的问题
- 修复 Binary 安装缺少 init.d/php-fpm 启动脚本
- 修复 Binary 安装从 GitHub 下载 php.ini 国内不可达，改为镜像站 + 内置兜底

### CI 改进
- 修复 release.yml YAML 语法错误
- Release 说明改用 body_path，自动包含更新内容
- 修复 GitHub URL 指向旧账号的问题


- 修复 Binary 安装从 GitHub 下载 php.ini 国内不可达，改为镜像站 + 内置兜底


### v1.5.5 (2026-02-25)
- 🐛 修复 `nextlnmp info` / `nextlnmp password` 命令无效（case 分支在 `*` 通配符之后，永远执行不到）
- 🐛 修复安装 banner 版本号写死 v1.4.2，改为动态读取 `$NEXTLNMP_Ver` + 中文自动居中
- 🐛 修复 `nextlnmp vhost del` 时 `$vhostdir` 为空导致 .user.ini 解锁失败
- 🔧 选择 Typecho/ThinkPHP/Laravel/Yii2 伪静态时自动启用 Pathinfo（坑32）
- 🔧 `vhost add` 完成后显示部署提示：chattr 解锁→部署→chown→锁回（坑31）
- 🔧 管理工具 banner 边框对齐修正
- 🔧 Usage 提示从 `lnmp` 统一改为 `nextlnmp`
- 🔧 `lnmp_kill()` 用 `pkill` 替代 `killall`（Debian/Ubuntu 兼容）
- 🔧 `vhost add` 完成信息、`vhost del`、`vhost list` 等提示全面中文化
- 🔧 修正 9 处 `Sucessfully`、`rewirte`、`Virtul`、`selection::`、`diretcory` 等拼写错误


### v1.5.4 (2026-02-25)
- 🐛 修复 uninstall.sh 版本号显示为空（未从 nextlnmp.sh 读取 NEXTLNMP_Ver）
- 🔧 uninstall.sh / 安装完成界面 banner 右边框自动对齐（支持中英文混排动态计算列宽）


### v1.5.3 (2026-02-25)
- 🐛 修复安装完成界面 Unicode 边框字符在部分终端显示为乱码，改用 ASCII 字符
- 🔧 重写 uninstall.sh，修复 Echo_Red/Press_Start/Check_Stack 未定义函数报错
- ✨ uninstall.sh 新增「恢复出厂」选项，彻底清空服务器还原初始状态
- 🔧 uninstall.sh banner 改为动态读取版本号，URL 改为 nextlnmp.cn


### v1.5.2 (2026-02-25)
- 🐛 修复 CI 打包顺序，先回写版本号再打 tarball，解决 banner 显示旧版本号问题
- ✨ vhost add 全面中文化，所有提示改为中文并注明用途和默认值
- 🔧 所有交互输入支持退格键修改
- ✨ 伪静态规则改为数字选择，默认 WordPress
- ✨ 数据库名自动从域名生成，回车确认无需手动输入
- ✨ 数据库密码自动随机生成，明文显示，无需用户记忆
- 🔧 自动读取已保存的 root 密码，无需重复输入
- ✨ SSL 证书默认邮箱改为 letsencrypt@nextlnmp.cn
- 🐛 修复 acme.sh 下载源，改为 NextLNMP 镜像站
- 🐛 修复重建站点时 .user.ini 权限报错问题
- 🐛 修复 php-fpm reload 兼容多版本路径
- 🐛 修复数据库名/密码提示显示混乱问题
- 🐛 修复 nginx http2 语法警告
- ✨ nextlnmp ssl add 重写为站点列表选择模式


### v1.5.1 (2026-02-24)
- 🎨 安装完成界面新增中国站长论坛标志（https://cnwebmasters.com），致敬情怀
- 🌐 访问地址加「复制到浏览器打开」说明，新手更友好
- 📦 服务管理命令展开逐条说明，移除 {start|stop} 花括号写法
- 🔗 官网链接统一改为 https://nextlnmp.cn
- 📝 README 自动更新日志、badge、下载链接全流程自动化上线
- ✅ CI 全自动发版完成闭环，打 tag 即触发全流程


### v1.5.0 (2026-02-24)
- 🔧 CI 版本号回写 bug 修复，发版全流程自动化完成
- 📝 README 更新日志自动化，打 tag 即同步更新


### v1.4.6 (2026-02-24)
- ✅ CI 全自动化发版完成：打包 → SHA256 → GitHub Release → 镜像站同步 → Gitee Release + 附件上传，一个 tag 触发全流程
- 🔧 修复 Gitee Release API 缺少 `target_commitish` 字段导致创建失败的问题

### v1.4.2 (2026-02-24)
- 🎨 安装完成界面全面重构：耗时前置，关键信息集中展示，移除无关技术输出
- 💾 新增安装信息持久化：安装完成后自动保存至 `/root/nextlnmp-info.txt`（权限600），重新 SSH 登录后随时可查
- 🔧 新增 `nextlnmp info` 命令：一行命令查看完整安装信息（访问地址、数据库密码、常用命令）
- 🚪 安装完成后自动退出 screen 会话，无需手动操作

### v1.4.1 (2026-02-24)
- 🐛 修复 Binary 急速安装模式下 `php.ini` 被创建为空文件（0字节）的问题
- 🐛 修复 Binary 急速安装模式下 `www.conf` PHP-FPM 配置文件缺失的问题

### v1.4.0 (2026-02-23)
- 🚀 install.sh 整合 BBR 状态机：自动检测内核版本，支持 BBR 一键启用
- ⚙️ 全自动系统更新（update+upgrade），安装前静默执行
- 🔧 依赖检测新增 git，环境预检更完整
- 🔄 内核升级流程全自动，升级后引导用户 reboot 重新运行安装命令

### v1.3.4 (2026-02-23)
- 🚀 PHP 8.2 急速安装模式：Ubuntu 22.04 / Debian 12 自动识别，Binary 包直接解压，安装时间从30分钟缩短至1分钟内
- 🖥️ 推荐系统：Ubuntu 22.04 LTS / Debian 12，全程约5分钟完成 NextLNMP 部署
- 其他系统自动回退源码编译模式

### v1.3.3 (2026-02-23)
- 🎨 安装完成界面全面中文化重写，品牌信息统一
- 🧹 清理所有残留的原项目标识

### v1.3.2 (2026-02-23)
- 🐛 修复一路回车安装走源码编译的问题（DBSelect 回退时未同步设置 Bin=y）
- 🚀 数据库 Binary 包下载改为镜像站优先，官方源回退
- 📦 镜像站新增全套数据库 Binary 包（MySQL 5个 + MariaDB 4个，共 5GB+）

### v1.3.1 (2026-02-23)
- 🐛 修复预编译二进制包选项默认值（回车空输入走了源码编译）

### v1.3.0 (2026-02-22)
- 🧠 新增智能硬件推荐系统：自动检测 CPU/内存/磁盘，一键推荐最佳配置
- 📊 新增 MySQL my.cnf 自动优化：根据内存分级调整 buffer_pool/max_conn/performance_schema
- 🎯 统一推荐 MySQL 5.7（所有配置），避免用户迁移时跨版本数据库导入出错
- ⏎ 所有菜单提示加"回车默认"，小白一路回车即可完成安装

### v1.2.0 (2026-02-22)
- 🇨🇳 全面中文化：数据库选择、PHP 选择、内存分配器选择菜单全部中文
- 🔑 数据库密码自动生成（16位随机密码），不再让小白手动设密码
- 🔍 品牌 PHP 探针（NextLNMP Prober），替换默认探针

### v1.1.1 (2026-02-22)
- ⚙️ 新增 GitHub Actions 自动化发版，推 tag 即出 Release，无需手动打包
- 🛡️ 新增 .gitignore，杜绝 tarball 误入库
- 🔒 install.sh 中 SHA256 改由 CI 自动回写，发版更安全可靠

### v1.1.0 (2026-02-22)
- 🚀 新增一行 `curl` 安装命令，复制粘贴即装
- 🔄 三源容灾下载（镜像站 → Gitee → GitHub），自动切换最快源
- 🔒 安装包 SHA256 完整性校验，防篡改
- 🖥️ 系统环境预检（内存 / 磁盘 / 端口），只警告不阻断
- 📦 包管理器自动识别（yum / apt-get），基础依赖自动安装

### v1.0.0 (2026-02-22)
- 🎉 首次发布
- ✅ 全部源码包从官方上游获取，SHA256 逐包校验
- ✅ 自建 HTTPS 镜像站，60 个源码包全覆盖
- ✅ 新增 PHP 8.4.18 支持
- ✅ 全新品牌，GPL-3.0 + 商业双授权

## 📞 技术支持

- **QQ群：** 615298
- **作者：** 静水流深
- **网站：** [中国站长](https://cnwebmasters.com)
- **问题反馈：** [Gitee Issues](https://gitee.com/palmmedia/nextlnmp/issues) · [GitHub Issues](https://github.com/NextLNMP/nextlnmp/issues)

## 🤝 相关项目

同系列开源工具，覆盖 Linux 服务器从检测到部署的全链路：

| 项目 | 用途 | 链接 |
|------|------|------|
| **VPSCheck** | VPS 全能检测（流媒体/AI/回程/跑分） | [GitHub](https://github.com/adsorgcn/vpscheck) · [Gitee](https://gitee.com/palmmedia/vpscheck) |
| **BBR 一键加速** | Google BBR 拥塞控制一键开启 | [GitHub](https://github.com/adsorgcn/bbr-script) · [Gitee](https://gitee.com/palmmedia/bbr-script) |
| **NextLNMP** | 安全可信的 LNMP 一键安装（本项目） | [GitHub](https://github.com/NextLNMP/nextlnmp) · [Gitee](https://gitee.com/palmmedia/nextlnmp) |

**推荐部署流程：** VPSCheck 检测 → BBR 加速 → NextLNMP 部署

## 📜 开源协议

本项目采用 **GPL-3.0 + 商业双授权**模式：

- 个人站长、独立开发者：[GPL-3.0](LICENSE) 免费使用
- 企业/云服务商/主机商集成：需向 **掌媒科技有限公司** 购买商业授权

参考案例：MySQL、MariaDB、Qt 均采用相同授权模式。

Copyright © 2026 掌媒科技有限公司. All rights reserved.

---

<div align="center">

**如果这个项目对你有帮助，请给个 ⭐ Star 支持一下！**

👉 [Gitee](https://gitee.com/palmmedia/nextlnmp) · [GitHub](https://github.com/NextLNMP/nextlnmp)

Made with ❤️ by 静水流深 | 掌媒科技有限公司

</div>
