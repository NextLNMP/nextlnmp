### v1.10.1 —— 上游域名跟进（2026-08-24）

- lnmp 官方镜像域名 `soft.vpser.net` 已停止解析（NXDOMAIN），全部引用切换到现行官方域名 `soft.lnmp.com`（acme.sh 引导 ×3 CLI、PHP 5.2 fpm 补丁兜底、上游声明清单）
- 镜像站补齐 Zend loader 全套（PHP 5.2–5.6）与 php-5.2.17-fpm 补丁共 6 件，校验清单同步收编——老版本 PHP 安装链路完整闭环
- 说明：v1.10.0 用户不受影响（acme.sh 有 GitHub 兜底、Zend loader 为软失败可跳过），本版为体验修正

<details><summary>v1.10.0 完整更新内容（全量审计修复版）</summary>

基于全量审计（14 路并行代码审查 + 镜像 175 个下载地址逐一实测）修复 84 条已确认缺陷：数据安全四件套（假备份真删库、卸载误删 MariaDB 数据、升级先拆后验）、下载兜底链全面复活、MariaDB 11.8/12.3 真实安装、MySQL 8.4 管理面、Apache/Caddy/LAMP 修复、PHP 8.4 全线支持、SSL 链路修复、镜像补货 39 项（含 PHP 8.2.28 全部 8 个 bin 变体）、每周镜像覆盖体检 CI。详见 v1.10.0 Release。
</details>
