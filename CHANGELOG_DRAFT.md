### v1.10.2 —— 闭环核销补遗（2026-08-24）

- 84 条审计发现逐条对 v1.10.1 代码+镜像做闭环核销（7 路独立核查），补掉最后 1 条 open：addons.sh 的多版本 PHP 选择（Select_PHP）探测与菜单止步于 8.2，仅装 php8.3/8.4 时扩展会静默装进主 PHP——现已扩到 16 个选项与 8.4 对齐
- 默认欢迎页引用的 nextlnmp.gif 不存在（死图），改为文字标头
- 核销结论：84 条 = 79 fixed + 4 by_design（上游事实：MariaDB 5.5 无 systemd bintar ×2、MariaDB 无 aarch64 bintar、32 位 ARM 无 DB 预编译）+ 1 处外观残留已随本版清零
