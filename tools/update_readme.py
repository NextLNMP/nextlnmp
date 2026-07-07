#!/usr/bin/env python3
import os, sys, re, subprocess

version = os.environ.get('VERSION', '')
date = os.environ.get('DATE', '')

if not version or not date:
    print("ERROR: VERSION and DATE env vars required")
    sys.exit(1)

# 读取 CHANGELOG
with open('CHANGELOG_DRAFT.md') as f:
    changelog = f.read().strip()

with open('README.md') as f:
    readme = f.read()

if changelog:
    # 去掉 CHANGELOG 自带的版本标题行（避免双标题）
    changelog = re.sub(r'^##?\s*v[\d.]+.*\n+', '', changelog).strip()

    new_entry = f"### v{version} ({date})\n{changelog}\n"

    # 如果已存在该版本条目，先删除（防止重发版重复）
    pattern = rf'### v{re.escape(version)} \([^)]+\)\n(.*?)(?=### v|\Z)'
    readme = re.sub(pattern, '', readme, flags=re.DOTALL)

    # 插入新条目
    readme = readme.replace("## 🔄 更新日志\n", f"## 🔄 更新日志\n\n{new_entry}\n", 1)

# 更新 badge 版本号
readme = re.sub(r'version-[\d.]+-blue', f'version-{version}-blue', readme)

# 更新下载链接
readme = re.sub(r'releases/download/v[\d.]+/nextlnmp-[\d.]+\.tar\.gz',
                f'releases/download/v{version}/nextlnmp-{version}.tar.gz', readme)
readme = re.sub(r'mirror\.nextlnmp\.cn/nextlnmp-[\d.]+\.tar\.gz',
                f'mirror.nextlnmp.cn/nextlnmp-{version}.tar.gz', readme)
readme = re.sub(r'tar zxf nextlnmp-[\d.]+\.tar\.gz',
                f'tar zxf nextlnmp-{version}.tar.gz', readme)
readme = re.sub(r'cd nextlnmp-[\d.]+\b',
                f'cd nextlnmp-{version}', readme)
readme = re.sub(r'nextlnmp-[\d.]+/',
                f'nextlnmp-{version}/', readme)

# 更新 install.sh 头部注释版本号
subprocess.run(['sed', '-i', f's/一键安装引导脚本 v[0-9.]*/一键安装引导脚本 v{version}/', 'install.sh'])

# 清理多余空行（连续3个以上换行合并为2个）
readme = re.sub(r'\n{3,}', '\n\n', readme)

with open('README.md', 'w') as f:
    f.write(readme)

# 清空 CHANGELOG_DRAFT
with open('CHANGELOG_DRAFT.md', 'w') as f:
    f.write('')

print(f"README updated to v{version}")
