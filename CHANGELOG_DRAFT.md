### v1.11.1 —— imap 扩展 EL9 补链（2026-08-24）

- uw-imap el9 双 RPM 找到正经上游：Remi 仓库的 EL9 构建（libc-client / uw-imap-devel 2007f-30.el9.remi，x86_64 + aarch64 全有）——此前被判为“无公网上游需人工补原件”，现已入补货清单自动同步
- php.sh / php_imap.sh 的 RPM 文件名引用同步更新；校验清单扫描纳入 .rpm 文件；镜像覆盖体检将这四件从 warn 层转为正式条目
- 至此覆盖体检的 warn 层清零：所有安装器会请求的文件都有可自动补货的上游
