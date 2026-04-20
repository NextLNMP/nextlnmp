**镜像站迁移 + 下载架构升级**

- 镜像站从 mirror.zhangmei.com 迁移至 nextlnmp.cn（国内BGP加速）
- install.sh 下载优先级调整为：Gitee > 镜像站 > GitHub
- 镜像站检测失败不再中断安装，改为警告并尝试备用下载源
- 修复 DNS 检测 bug：兼容 Oracle Cloud 等最小化镜像（ping 未安装 / 多种 DNS 错误格式）
- 清除全部 mirror.zhangmei.com 硬编码引用（共4处）
