# NextLNMP

<div align="center">

![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)
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

- 🚀 **急速安装**：Ubuntu 22/24、Debian 12/13 全覆盖，清单驱动的 PHP Binary 预编译包（8.2 / 8.3 / 8.4）直接解压，全程约 **5 分钟**完成 LNMP 环境部署
- 🤖 **AI 装机救援**：安装失败当场进入对话，AI 读日志、要证据、给修复建议。只读诊断命令走白名单自动执行，修复命令逐条 y/N 确认；上传日志前征得同意且先抹掉密码。不需要就 `NEXTLNMP_AI=n`
- 🧯 **可靠升级**：`upgrade.sh` 升级前做磁盘预检与 CPU 兼容实测，解压或恢复失败自动回滚到原版本，数据与网站不受影响
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
| **x86_64** | ✅ 完整支持 | 急速安装模式（8.2 / 8.3 / 8.4 Binary 包，< 1分钟）+ 源码编译双模式 |
| **ARM64 / aarch64** | ✅ 完整支持 | PHP、MySQL 8.0/8.4 均有 aarch64 预编译包；Nginx 源码编译（MariaDB 官方无 arm 通用 bintar）。真机实测全程约 12 分钟 |
| **ARM64 急速模式** | ✅ 已上线 | PHP 8.3 / 8.4 aarch64 Binary 包（Ubuntu 22/24、Debian 12/13），清单驱动自动启用 |

> 腾讯云、阿里云、AWS 的 ARM 实例（如 Graviton）均可正常安装，使用源码编译模式。

## ⚡ 快速开始

**方式一：一行命令安装（推荐）**

国内直连 CNB 源：

```bash
bash <(curl -sL "https://cnb.cool/NextLNMP/NextLNMP/-/git/raw/main/install.sh?download=true")
```

GitHub 源备用：

```bash
bash <(curl -sL https://raw.githubusercontent.com/NextLNMP/nextlnmp/main/install.sh)
```

**方式二：从镜像站下载安装（国内快）**

```bash
wget https://mirror.nextlnmp.cn/nextlnmp-2.0.0.tar.gz && tar zxf nextlnmp-2.0.0.tar.gz && cd nextlnmp-2.0.0 && bash install.sh
```

**方式三：从 GitHub 下载安装**

```bash
wget https://github.com/NextLNMP/nextlnmp/releases/download/v2.0.0/nextlnmp-2.0.0.tar.gz && tar zxf nextlnmp-2.0.0.tar.gz && cd nextlnmp-2.0.0 && bash install.sh
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

- **PHP 8.4** — 首发支持，Binary 急速安装
- **MySQL 8.4 LTS / MariaDB 11.8 LTS / 12.3 LTS** — 长期支持版本全跟进
- **Nginx 1.30** — 主线最新版
- 同时保留 PHP 5.6 ~ 8.3、MySQL 5.1 ~ 8.0、MariaDB 5.5 ~ 10.11 全版本可选，老项目无缝迁移

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

> LNMP 模式支持把 Web 服务器换成 Caddy v2：安装前在 `nextlnmp.conf` 中设 `WebServer='caddy'` 即可。

### 📦 支持的软件版本

| 软件 | 可选版本 |
|------|---------|
| **Nginx** | 1.30.3 |
| **PHP** | 5.6 / 7.0 / 7.1 / 7.2 / 7.3 / 7.4 / 8.0 / 8.1 / 8.2⚡ / 8.3⚡ / **8.4⚡** |

> ⚡ = Binary 急速安装：Ubuntu 22/24、Debian 12/13 上直接解压预编译包，< 1 分钟
| **MySQL** | 5.1 / 5.5 / 5.6 / 5.7 / 8.0（EOL）/ **8.4 LTS** |
| **MariaDB** | 5.5 / 10.4 / 10.5 / 10.6（EOL）/ 10.11 / **11.8 LTS** / **12.3 LTS** |
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

# SSL 证书（Let's Encrypt / BuyPass / ZeroSSL，webroot 验证）
nextlnmp ssl add

# SSL 证书（DNS 验证，支持 cx/ali/cf/dp/he/gd/aws）
nextlnmp dns cf

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
| **Debian** | 10 / 11 / 12 / 13 | ✅ 支持 |

> 🚀 **急速安装推荐：** Ubuntu 22.04/24.04、Debian 12/13 上选择 PHP 8.2 / 8.3 / 8.4 时自动使用 Binary 预编译包，安装时间 **< 1分钟**，全程约 **5分钟** 完成 NextLNMP 部署。其他系统与版本自动回退源码编译。

**系统要求：** 内存 ≥ 512MB，磁盘 ≥ 5GB

> ✅ v2.0.0 发版前在 Ubuntu 22.04 / Rocky 9.7 / CentOS 7 / Debian 12 / Debian 13 / ARM64 Ubuntu 六种真机环境、LNMP / LAMP / LNMPA / Caddy 四种栈上完成 15 轮安装与升级验收，含官方一行命令的发版金标测试。

## 🔒 安全机制详解

NextLNMP 的安全不是一句口号，是一条闭合的信任链：

```
用户执行 install.sh（托管于 GitHub / CNB，内嵌主包 SHA256 锚点）
    ↓
多源下载主包（mirror.nextlnmp.cn → GitHub），与内嵌锚点比对
    ↓  ❌ 不匹配 → 立即终止
主包内自带 sha256sums.txt 校验清单（与代码同仓，逐次变更公开可审计）
    ↓
逐个下载组件包，计算 SHA256 与清单比对
    ↓
✅ 匹配 → 继续    ❌ 不匹配 → 删除可疑文件，立即终止
⚠️ 清单暂缺该包 → 黄色警告放行；NEXTLNMP_VERIFY=strict 时直接终止
```

设计要点：

- **锚点分离**：引导脚本与主包走不同渠道。脚本在 GitHub/CNB，包在镜像站。镜像站即使被完全攻陷，也伪造不出能通过脚本内嵌锚点的主包
- **清单随包**：组件校验清单不从镜像站下载（那会形成"自证清白"），而是打进主包分发，可信度等同主包本身
- **全程可审计**：清单就是仓库里的 `sha256sums.txt`，由 CI 从镜像站全量生成，每次更新都是一次公开的 git 提交
- **严格模式**：`NEXTLNMP_VERIFY=strict bash install.sh` 让任何未列入清单的包直接终止安装
- **二进制可溯源**：PHP Binary 预编译包由公开的 GitHub Actions 产线从 php.net 官方源码构建，构建日志与产物哈希任何人可查

**镜像站：** `https://mirror.nextlnmp.cn`

- 部署于阿里云国内节点，全程 HTTPS 加密传输
- 仅提供源码包格式（.tar.gz / .tar.bz2 / .tar.xz / .tgz），禁止目录遍历
- 全部包可溯源至官方发布页

## 🤖 AI 装机救援

安装失败时不再只留一句"请把日志发到 QQ 群"，而是当场进入对话：AI 读日志、要证据、给修复建议，你逐条决定是否执行。

边界写死在代码里，公开可审计（`include/ai-assist.sh`）：

- 上传日志前先征得同意，且密码字段已抹掉
- 只读诊断命令必须整行匹配白名单才自动执行
- 修复命令一律 y/N 确认；`rm -rf /` 这类灾难命令即使按了 y 也拦下
- 命令里出现控制字符直接拒绝，屏幕显示的就是实际执行的
- 网关超时或不可达一律静默跳过，永不阻塞安装
- 一键关闭：`NEXTLNMP_AI=n bash install.sh`

若 AI 判定是镜像缺件，会先核实主镜像真缺、官方上游真有，查重限流后自动提交 GitHub issue，补货由仓库侧 CI 完成。同一个坑，后来者不再踩。

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
nextlnmp-2.0.0/
├── install.sh          # 安装入口
├── nextlnmp.conf       # 配置文件（镜像源地址等）
├── upgrade.sh          # 升级脚本
├── uninstall.sh        # 卸载脚本
├── addons.sh           # 扩展管理（虚拟主机、FTP 等）
├── sha256sums.txt      # 组件全量 SHA256 校验清单（随主包分发的权威源）
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

镜像站 `mirror.nextlnmp.cn` 部署于阿里云国内节点，全程 HTTPS 加密传输。

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

### v2.0.0 (2026-08-28)

**一、AI 装机救援（本版主线）**

安装失败时不再只留一句"请把日志发到 QQ 群"，而是当场进入对话：AI 读日志、
要证据、给修复建议，用户逐条决定是否执行。

- **客户端 `include/ai-assist.sh`**：失败自动进入对话，无需用户主动求助。
  上传日志前征得同意且先抹掉密码；只读诊断命令走整行白名单（客户端与
  服务端各校验一次），修复命令一律 y/N 确认，灾难命令即使按了 y 也拦下；
  命令含控制字符直接拒绝（防"屏幕显示的和实际执行的不是一回事"）。
- **网关**（源码在 `ai-gateway/`，可审计，密钥全走环境变量）：
  DeepSeek v4-flash + 两级缓存（L1 错误签名归一化零 token、L2 前缀缓存）、
  日费用上限、并发闸。
- **镜像缺件处理**：AI 判定缺件后不直接动镜像，而是先 HEAD 主镜像核实
  真缺、再 HEAD 官方上游核实文件真实存在，查重限流后开 GitHub issue，
  补货由仓库侧机器人/CI 完成——幻觉和提示词注入最坏只产生一条噪音通知。
- **关闭方式**：`NEXTLNMP_AI=n`。

**二、CLI 重构（消除漂移债）**

三个 CLI（lnmp / lnmpa / lamp）此前是三份近似复制，改一处忘两处是常态。

- 改为构建期组装：公共函数抽出 38 个，单一事实源。
- 多版本 PHP 选择、数据库/PHP 菜单改为表驱动，菜单↔版本表↔安装函数三方对齐。
- **六道 CI 闸**（CLI Guard）防止重构回归：漂移、指纹等价、渲染保真、
  一致性断言、php-select 单测、`bash -n`。本版又加了第 7、8 道
  （ai-assist 安全闸门、依赖安装容错外壳）。

**三、安全相关（真机实测坐实）**

- **`/home/wwwlogs` 是 777 且没有 sticky 位**（`25dea83`）——日志由 nginx/httpd 的
  master（root）打开，www 根本不需要写权限。而非 sticky 的 777 目录不受
  `fs.protected_symlinks` 保护。真机三组对照：www 预先建符号链接，root 追加日志
  时原样跟随过去 —— 这是一条 www → root 的任意文件写入。改 755。
- **带明文密码的临时 SQL 放在 `/tmp` 固定文件名下**（`472ccfd`）——内容是
  `CREATE USER ... IDENTIFIED BY '<明文密码>'`，权限 0644，真机实测 www 用户
  直接 cat 得到；而每个站点的 `open_basedir` 恰好放行 `/tmp/`。迁到
  `/root/.nextlnmp-tmp`(700)。
- **数据库 root 密码进了 `ps` 和 0644 的安装日志**（`b758095`）——
  `mysql_upgrade -p${密码}` 让同机任何用户 `ps aux` 就能看到；
  `| tee` 建的安装日志是 0644，而成功面板会把自动生成的密码打进去。
- **Caddy 二进制既无 TLS 认证也无哈希校验**（`c7caade`）——不在 sha256sums 清单里，
  而 `Try_Download` 默认只对"清单查无此条目"打黄字警告，wget 又带
  `--no-check-certificate`。已上架镜像并入清单，走三级链路逐包校验。
- **Caddy 栈的 PHP 完全没有 open_basedir 隔离**（`bb8b9cd`）——注释写着"对齐
  nginx.sh"，实际只建了目录，`.user.ini` 那道隔离整套缺席。
- **网站根目录不校验就 `chmod -R` / `chown -R`**（`2ffc6bc`）——填成父目录
  `/home/wwwroot` 会把这台机器上所有站点的文件递归改成 www:www 755。

**四、会静默毁数据 / 报假成功的地方**

- **收尾自检把"装了"当成"跑起来了"**（`4fe5152`）——数据库启动失败 4 次仍打印
  完整成功横幅，AI 救援也因此从不触发。
- **装挂了整条一键安装命令仍返回 0**（`f64b175`）——三个栈跑在 `| tee` 左侧，
  所有 `exit 1` 只杀子 shell，脚本结尾一句裸 `exit` 交出 tee 的 0。
  CI 与自动化调用方全被骗过。
- **换个目录运行就跳过数据库备份、然后照样 `rm -rf`**（`f896379`）——
  `uninstall.sh` / `upgrade.sh` / `addons.sh` 靠 `$(pwd)` 定位，配置读不出来时
  备份被 `[ -n ]` 守卫静默跳过，而删除是无条件的。
- **数据库升级：版本分发落空时旧库已被搬走**（`d653f3d`）——`Backup_MySQL` 是
  `mv` 走整个 MySQL，而分发只认 6 个大版本、没有 else；输入 8.1/9.x 这类真实
  存在但不支持的版本，用户手上只剩一台被拆干净的机器且没有任何报错。
  同一提交还修了三处"恢复备份失败仍打印绿色 completed"。
- **建站面板按用户当初的 y/n 打印凭据**（`9bcd15f`）——库没建成也照样吐出
  数据库名/用户/密码，用户拿去装 WordPress 才发现连不上。
- **重跑一次就把用户配置的备份盖成已改坏的版本**（`e571599`）——
  `/etc/yum.conf` 的 `exclude=kernel*`、`sources.list` 的自定义源就此永久丢失。

**五、会卡死用户 / 撑爆磁盘**

- **`.online` / `.email` 这类邮箱被判非法，且循环没有出口**（`44cd3be`）——
  只能 Ctrl+C，SSL 配置整条路走不通。
- **23 处交互循环的 `read` 不判 EOF**（`1bbdbaa` `95fc974` `1f842cb`）——
  非交互调用（脚本/cron/`</dev/null`）下无限空转刷屏，实测 3 秒刷 22~29 万行。
- **"连不上数据库"被报成"密码错误"并无限追问**（`a91ae8f`）——数据库没启动的
  用户输一百遍正确密码也过不去，屏幕上始终说密码错。

**六、其它**

- **301 跳转对 `.php` 页面从来没生效过**（`20cfc97`）——插的是 `location /`，
  而 `enable-php.conf` 是正则 location、优先级更高。对 PHP 站点来说等于绝大多数
  页面始终走明文 HTTP。同一处还修了重复配置导致的 `duplicate location` 致命错误。
- **`fs.file-max=65535` 是降级不是优化**（`ccefc23`）——内核默认值是
  9223372036854775807；且只写文件不 `sysctl -p`，重启后才发作。
  同一提交修了 `Kill_PM` 用整条命令行做子串匹配、会 `kill -9` 掉
  `vim /etc/apt/sources.list` 这类无关进程。
- **`addons.sh uninstall` 被改写成 install**（`d7d99ae`）；单装 nginx 后
  `/bin/nextlnmp` 因漏 `chmod +x` 不可执行。
- **依赖清单里的上古包名刷一屏 Error**（`9515a80` `ffe32cc`）——会让用户以为装挂了，
  也会把 AI 救援带偏。⚠ 这条修复的第一版被自己的审计抓到造了个"假成功"
  （源整个坏了时 gcc/make 也会被当可选件吞掉），已在 `e8daace` 补上必需件名单
  与工具链硬断言。
- 菜单输入校验的交替式缺括号、`www` 用户组非幂等、ARM64 悬空软链接、
  推荐面板在 RHEL 系谎称"免编译"等若干项。

**七、数据库升级路径加固（真机实锤后重做）**

在 8.4G 小盘真机上把升级流程打穿了三次，三处结构性缺陷全部修复：

- **磁盘零预检**：下载、校验、备份全成功，老库搬走后解压新版把盘写满，
  机器从此没有任何可用数据库。现在 `Upgrade_Disk_Preflight` 读包内真实
  解压大小（gzip -l / xz --robot），在备份之前拦截——此刻还什么都没动，
  中止是零损失的。
- **CPU 兼容性零检测**：新版预编译包的客户端在无 AVX2 的机器上 SIGILL
  （服务端能跑，init 脚本的 ping 每秒崩一次，systemd 90 秒超时把健康的
  服务杀掉）。现在升级前绕开 init/systemd 直接拉起新服务端实连测客户端，
  不兼容自动回滚，全程约 2 分钟，网站不掉线。
- **5.7 备份导不进 8.0**（ERROR 3554：8.0 禁写 mysql 系统表，dump/restore
  对 8.x 目标结构性走不通）：目标 8.x 且源 ≥5.7 改走官方在位升级
  （`mysqld --upgrade=FORCE`），用户、授权、数据全保留，dump 照做但降级
  为保险；5.6 及以下直跳 8.x 在备份前拦死（官方升级路线：5.7 → 8.0 → 8.4）。
- 三条升级路（MySQL / MariaDB / MySQL→MariaDB）的"恢复失败"从扔给用户
  一台空库机器，改为自动回滚到原版本并把整栈拉回。

实测：MariaDB 10.4.33 → 10.11.18、MySQL 5.7.44 → 8.0.46 均全绿，
数据无损穿越；盘满与 CPU 不兼容两种失败均以"原库原样、网站在线"收场。

**八、供应链**

- 镜像补货至 126/126，覆盖体检全绿。
- 魔搭（ModelScope）副镜像，三级容灾：主镜像 → 副镜像 → 官方上游，
  任一级失败自动降级并逐包 SHA256 校验。
- CI 每日自动发版（需 CI 全绿方可放行）。

**验证状态（13 轮真机，全部收口）**

| 覆盖面 | 结果 |
|------|------|
| Ubuntu 22.04 / Rocky 9.7 / CentOS 7 / Debian 12 / Debian 13 | ✅ 全绿（含 OOM→AI 救援全链路、CentOS 7 EOL 归档源、Debian 13 t64 过渡） |
| LNMP / LAMP / Caddy 三种栈 | ✅ 全绿（Caddy 含 open_basedir 隔离与 CLI 起停实测） |
| 数据库升级：MariaDB 10.4→10.11、MySQL 5.7→8.0 | ✅ 成功路径与两类失败路径（盘满、CPU 不兼容）三态全验 |
| AI 救援 + 缺件上报 | ✅ 真实故障多轮诊断定位正确；issue 上报含核实/查重/限流实证 |

未覆盖：LNMPA 栈与 ARM64 未上真机（ARM64 待有硬件）。

### v1.11.1 (2026-08-24)
### v1.11.1 —— imap 扩展 EL9 补链（2026-08-24）

- uw-imap el9 双 RPM 找到正经上游：Remi 仓库的 EL9 构建（libc-client / uw-imap-devel 2007f-30.el9.remi，x86_64 + aarch64 全有）——此前被判为“无公网上游需人工补原件”，现已入补货清单自动同步
- php.sh / php_imap.sh 的 RPM 文件名引用同步更新；校验清单扫描纳入 .rpm 文件；镜像覆盖体检将这四件从 warn 层转为正式条目
- 至此覆盖体检的 warn 层清零：所有安装器会请求的文件都有可自动补货的上游

### v1.11.0 (2026-08-24)
### v1.11.0 —— 魔搭副镜像双保险（2026-08-24）

- 新增备用镜像：魔搭 ModelScope 数据集 `iLang/NextLNMP-dist`，与主镜像目录结构完全一致，全量文件同步
- `Check_Mirror` 主镜像探活失败时自动切换到备用镜像（`nextlnmp.conf` 新增 `Download_Mirror_Backup`，可自行替换或留空禁用）
- sync-checksums 工作流在清单更新后自动触发镜像机向魔搭增量同步（LFS 按内容去重）
- 每周镜像覆盖体检同时核查主/备两个镜像（备镜像滞后仅警告）
- 自此下载链路三级容灾：主镜像（阿里云）→ 魔搭副镜像 → 各组件官方源

### v1.10.2 (2026-08-24)
### v1.10.2 —— 闭环核销补遗（2026-08-24）

- 84 条审计发现逐条对 v1.10.1 代码+镜像做闭环核销（7 路独立核查），补掉最后 1 条 open：addons.sh 的多版本 PHP 选择（Select_PHP）探测与菜单止步于 8.2，仅装 php8.3/8.4 时扩展会静默装进主 PHP——现已扩到 16 个选项与 8.4 对齐
- 默认欢迎页引用的 nextlnmp.gif 不存在（死图），改为文字标头
- 核销结论：84 条 = 79 fixed + 4 by_design（上游事实：MariaDB 5.5 无 systemd bintar ×2、MariaDB 无 aarch64 bintar、32 位 ARM 无 DB 预编译）+ 1 处外观残留已随本版清零

### v1.10.1 (2026-08-24)
### v1.10.1 —— 上游域名跟进（2026-08-24）

- lnmp 官方镜像域名 `soft.vpser.net` 已停止解析（NXDOMAIN），全部引用切换到现行官方域名 `soft.lnmp.com`（acme.sh 引导 ×3 CLI、PHP 5.2 fpm 补丁兜底、上游声明清单）
- 镜像站补齐 Zend loader 全套（PHP 5.2–5.6）与 php-5.2.17-fpm 补丁共 6 件，校验清单同步收编——老版本 PHP 安装链路完整闭环
- 说明：v1.10.0 用户不受影响（acme.sh 有 GitHub 兜底、Zend loader 为软失败可跳过），本版为体验修正

<details><summary>v1.10.0 完整更新内容（全量审计修复版）</summary>

基于全量审计（14 路并行代码审查 + 镜像 175 个下载地址逐一实测）修复 84 条已确认缺陷：数据安全四件套（假备份真删库、卸载误删 MariaDB 数据、升级先拆后验）、下载兜底链全面复活、MariaDB 11.8/12.3 真实安装、MySQL 8.4 管理面、Apache/Caddy/LAMP 修复、PHP 8.4 全线支持、SSL 链路修复、镜像补货 39 项（含 PHP 8.2.28 全部 8 个 bin 变体）、每周镜像覆盖体检 CI。详见 v1.10.0 Release。
</details>

### v1.10.0 (2026-08-24)
### v1.10.0 —— 全量审计修复版（2026-08-24）

本版基于一次全量审计（14 路并行代码审查 + 镜像 175 个下载地址逐一实测）修复 84 条已确认缺陷，去重后约 45 个独立问题。

**🛡 数据安全（务必升级）**
- 修复重装时的"假备份真删库"：数据目录备份此前用不带 `-r` 的 cp，所有库表子目录被跳过后 `rm -rf` 永久删除；现在完整备份（含隐藏文件），备份失败即中止安装
- 修复卸载"保留数据"选项静默销毁 MariaDB 数据目录（此前只备份 MySQL）
- PHP 升级改为"先验证版本再拆旧环境"，并支持升级到 8.4；此前输入不支持的版本会在全站停机、PHP 被搬走之后才报错退出
- 多版本 PHP 升级增加选择校验，输错编号不再导致全栈服务停摆

**📦 下载与镜像**
- `Download_Files` 失败即退出导致所有官方源兜底（cdn.mysql.com、pureftpd.org、php.net 等）成为死代码——新增 `Try_Download` 并重写全部兜底链，镜像缺件从"必死"降级为"自动切换官方源"
- 镜像补货 61 项（PHP 8.2.28 源码、MySQL 8.x 源码、Lua 全家、fancyindex、pure-ftpd、fail2ban、libzip、libmemcached、老版扩展等），`tools/upstream-sources.txt` 全部 URL 经实测
- MySQL aarch64 通用包按官方实际命名走 glibc2.28（此前拼 glibc2.17 必 404，"ARM fast lane" 数据库从未可用）
- SHA256 清单查找改为精确匹配，兼容带路径前缀的旧格式清单；sync-checksums 现在会把新清单同步回镜像站
- 新增每周镜像覆盖体检 CI（`tools/check-mirror-coverage.sh`），防"升版本号忘传包"复发

**🗄 数据库**
- MariaDB 11.8 / 12.3 LTS 此前"菜单收单但没有安装函数"（选了装完没有数据库）——现在真的会装；菜单补齐 12/13
- MariaDB 5.5 强制源码编译（上游从未发布过 linux-systemd 二进制，此前默认回车必 404）
- MySQL 8.4 管理面修复：CLI 建库/改密不再使用 8.0 已删除的 `GRANT ... IDENTIFIED BY` 旧语法；安全初始化、重置 root 密码工具、Boost、系统门槛检查全部认识 8.4
- MariaDB 10.4+ 改密走 `SET PASSWORD`（mysql.user 在 10.4+ 是视图）；10.4 安全初始化分支修复
- 修复 11 处"提示源码编译、实际装二进制"的默认分支错位

**🌐 Web 服务器与 PHP**
- LNMPA 栈修复：Apache 配置引用了不存在的 `*-nextlnmpa.conf` 文件名（实际是 `*-lnmpa.conf`），装完 Apache 没有 httpd.conf；LAMP 管理 CLI 同类问题（conf/lamp → conf/nextlamp）
- Caddy 从"四连炸摆设"修成能用：下载 URL 版本号拼接、v2 语法 Caddyfile、www 用户与可写存储目录、按架构选包、诚实的启动校验与收尾检查
- PHP bin 急速安装只在纯 LNMP 栈启用（bin 包不含 mod_php，LAMP/LNMPA 装了 Apache 无法执行 PHP）；8.3/8.4 急速安装补上 `/etc/init.d/php-fpm`（此前 `nextlnmp restart`、插件重启、check502 全部失效）
- Apache + PHP 8.3/8.4 组合修复（版本正则漏了 14/15）
- PHP 7.1 不再错配要求 PHP≥7.2.5 的 phpMyAdmin 5.2.x
- 多版本 PHP 支持 8.4；vhost 的 PHP 选择菜单补上 8.3/8.4；swoole 支持 PHP 8.4（swoole-5.1.8）；PHP 5.2–5.6 的 Zend loader 改为可选（缺文件跳过而非中断安装）
- fail2ban 从不存在的幻影版本 1.0.3 改为 1.1.0（兼容 python3.11+）

**🔐 SSL 与 CLI**
- acme.sh 下载源已死（mirror.zhangmei.com）→ 改为 soft.vpser.net + GitHub 双线；三个 CLI 统一
- `nextlnmp ssl add` 不再生成 `include rewrite/.conf;` 损坏配置——从现有站点配置继承 rewrite/PHP/日志设置

**🧹 其他**
- 卸载时清理 systemd 单元与多版本 PHP 目录；`upgrade.sh` 输入 "PHP" 大写不识别的拼写错误；composer 版本判断误伤 PHP 7.4+；内存分配器菜单回车现在真的采用推荐值；Ubuntu 24.10/25.04 EOL 源、RHEL 9.x CRB 仓库 ID、32 位 ARM 架构识别等一批小修

### v1.9.1 (2026-07-07)
- 修复：sync-checksums 增加并发排队，根治双链式触发竞态互吞提交的静默缺陷
- 说明：aarch64 二进制清单条目自本版本随包生效（v1.9.0 包内清单打包早于 arm 条目落库）

### v1.9.0 (2026-07-07)
- 功能：PHP 二进制快车道支持 aarch64（包名追加 -aarch64 后缀，清单驱动逻辑不变）
- 基建：build-php-binaries 产线扩展为 x86_64 + aarch64 双架构八腿矩阵（GitHub ARM Runner）
- 基建：新增 smoke-mariadb 真机冒烟工作流（下载 bintar → 布局校验 → install_db → 起服务 → 版本断言 → utf8mb4 读写回环 → 关停）
- 结论：MariaDB 官方无 aarch64 通用 bintar（已核实），ARM 上走源码编译回退属上游事实

### v1.8.1 (2026-07-07)
- 修复：二进制快车道取回 php.ini 模板失败时正确回落内置模板，不再中断安装
- 清理：addons 帮助文案中一处 eAccelerator 残留

### v1.8.0 (2026-07-07)
- 组件：Nginx 升级至 1.30.3 稳定版；MariaDB 新增 11.8 LTS 与 12.3 LTS 选项，10.11 更新至 10.11.18；MySQL 8.4 更新至 8.4.9，8.0 定格终版 8.0.46 并标注 EOL，10.6 同标 EOL；phpMyAdmin 更新至 5.2.2
- 组件：MySQL 8.0 二进制统一 glibc2.17 线（2.12 已停发），8.4 上游回退源改为 Downloads
- 基建：新增 sync-upstream 工作流与 tools/upstream-sources.txt 声明式清单，官方源到镜像站一键同步并自动刷新校验清单

### v1.7.0 (2026-07-07)
- 功能：PHP 急速安装升级为清单驱动，支持任意版本 × Ubuntu 22/24、Debian 12/13，修复旧版在 Ubuntu22/Debian12 上无视所选版本强制下载 8.2.28 的问题
- 功能：8.3 / 8.4 安装接入二进制快车道，运行时依赖自动解析
- 基建：新增 build-php-binaries 产线工作流，一键构建四发行版二进制并自动上传镜像、刷新校验清单
- 清理：移除 eAccelerator 与 XCache 遗留组件（PHP 5 时代产物）

### v1.6.0 (2026-07-07)
- 安全：组件校验清单改为随主包分发，信任链闭合到仓库，不再依赖镜像站自证；新增 NEXTLNMP_VERIFY=strict 严格模式
- 安全：引导脚本校验占位符由静默跳过改为硬失败，杜绝零校验版本流出（开发调试用 NEXTLNMP_DEV=1）
- 基建：新增 sync-checksums 工作流，从镜像站一键生成全量校验清单并自动提交
- 调整：安装入口统一为 CNB 与 GitHub，移除已停更的 Gitee 渠道；主包下载源改为镜像站与 GitHub 双源
- 文档：安全机制章节按新信任链重写，镜像域名统一为 mirror.nextlnmp.cn

### v1.5.9 (2026-04-20)
**镜像站迁移 + 下载架构升级**

- 镜像站从 mirror.zhangmei.com 迁移至 nextlnmp.cn（国内BGP加速）
- install.sh 下载优先级调整为：Gitee > 镜像站 > GitHub
- 镜像站检测失败不再中断安装，改为警告并尝试备用下载源
- 修复 DNS 检测 bug：兼容 Oracle Cloud 等最小化镜像（ping 未安装 / 多种 DNS 错误格式）
- 清除全部 mirror.zhangmei.com 硬编码引用（共4处）

### v1.5.8 (2026-02-25)
### Bug 修复
- 修复 nextlnmpa 模式 vhost del 缺少 reload nginx/apache
- 修复 php-fpm glob 模式 [5,7,8] 逗号导致无法匹配多版本
- 补充 enable-php8.4.conf（PHP 8.4 菜单可用但缺 nginx 配置）

### 改进
- nextlnmpa Del_VHost 提示中文化
- Usage 提示统一改为 nextlnmp

### v1.5.7 (2026-02-25)
### Bug 修复
- 修复 DB_Info 显示 MySQL 8.4.0 实际为 8.4.4 的版本号不一致
- 修复 PHP_Info 显示 PHP 8.2.19 实际 Binary 包为 8.2.28 的版本号不一致
- 修复 Check_nextLNMPA_Install 条件判断缺少空格
- 清理 uninstall.sh 恢复出厂中无效的 apt-get remove 命令

### 改进
- PHP 选择菜单新增 PHP 8.4 选项
- 修正 Dispaly_Selection 拼写错误为 Display_Selection

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
- **问题反馈：** [GitHub Issues](https://github.com/NextLNMP/nextlnmp/issues) · [CNB](https://cnb.cool/NextLNMP/NextLNMP)

## 🤝 相关项目

同系列开源工具，覆盖 Linux 服务器从检测到部署的全链路：

| 项目 | 用途 | 链接 |
|------|------|------|
| **VPSCheck** | VPS 全能检测（流媒体/AI/回程/跑分） | [GitHub](https://github.com/adsorgcn/vpscheck) · [Gitee](https://gitee.com/palmmedia/vpscheck) |
| **BBR 一键加速** | Google BBR 拥塞控制一键开启 | [GitHub](https://github.com/adsorgcn/bbr-script) · [Gitee](https://gitee.com/palmmedia/bbr-script) |
| **NextLNMP** | 安全可信的 LNMP 一键安装（本项目） | [GitHub](https://github.com/NextLNMP/nextlnmp) · [CNB](https://cnb.cool/NextLNMP/NextLNMP) |

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

👉 [GitHub](https://github.com/NextLNMP/nextlnmp) · [CNB](https://cnb.cool/NextLNMP/NextLNMP)

Made with ❤️ by 静水流深 | 掌媒科技有限公司

</div>
