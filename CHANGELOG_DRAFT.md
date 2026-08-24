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
