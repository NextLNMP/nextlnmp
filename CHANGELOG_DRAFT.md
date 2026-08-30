#### 数据库升级路径加固（8.4G 小盘真机三连实锤后重做）

- 🧯 新增磁盘预检：读包内真实解压大小，需求不足在备份之前红字中止，现有数据库分毫不动
- 🧯 新增 CPU 兼容实测：升级前绕开 init/systemd 直接拉起新版实连测客户端，SIGILL 等不兼容自动回滚，全程约 2 分钟、网站不掉线
- 🧯 MySQL 8.x 目标改走官方在位升级（`mysqld --upgrade=FORCE`）：5.7 的全量备份带 mysql 系统库、8.0 禁写系统表（ERROR 3554），dump 导入结构性走不通；在位升级用户/授权/数据全保留，dump 降级为保险
- 🧯 官方升级路线闸：5.6 及以下不许直跳 8.x（先升 5.7），在备份前拦截
- 🧯 三条升级路（MySQL / MariaDB / MySQL→MariaDB）恢复失败从"扔给用户一台空库机器"改为自动回滚并拉回整栈
- 🐛 修复 Tar_Cd 从不检查 tar 退出码：磁盘写满解压半截仍继续 mkdir/mv/写配置的连环车祸
- 🐛 修复 m2m 失败提示把备份目录写错（oldmysql → 实为 mysql2mariadb<时间戳>）

#### 引导与发版

- 🐛 修复无 TERM 的非交互环境（ssh 免 pty / cloud-init / CI）下 install.sh 被裸 `clear` 杀死
- ⚙️ 发版流程找回丢失的 gitee 同步，新增 cnb.cool 同步与镜像站 install.sh 同步
- ⚙️ 新增 sync-cn 工作流：main 每次更新自动推平 gitee 与 cnb.cool（gitcode 为 gitee 的 Pull 镜像，自动跟随）
- ⚙️ 发版版本戳提交带 [skip release]，避免次日空发 patch 版
- ✅ CI 补上第八道闸：依赖安装容错外壳 25 项断言进 CLI Guard
