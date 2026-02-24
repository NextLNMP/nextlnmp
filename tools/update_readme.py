#!/usr/bin/env python3
import os, sys, re

version = os.environ.get('VERSION', '')
date = os.environ.get('DATE', '')

if not version or not date:
    print("ERROR: VERSION and DATE env vars required")
    sys.exit(1)

# 更新 README 更新日志
with open('CHANGELOG_DRAFT.md') as f:
    changelog = f.read().strip()

with open('README.md') as f:
    readme = f.read()

if changelog:
    new_entry = f"### v{version} ({date})\n{changelog}\n\n"
    readme = readme.replace("## 🔄 更新日志\n", f"## 🔄 更新日志\n\n{new_entry}", 1)

# 更新 badge 版本号
readme = re.sub(r'version-[\d.]+-blue', f'version-{version}-blue', readme)

# 更新下载链接
readme = re.sub(r'releases/download/v[\d.]+/nextlnmp-[\d.]+\.tar\.gz', 
                f'releases/download/v{version}/nextlnmp-{version}.tar.gz', readme)
readme = re.sub(r'tar zxf nextlnmp-[\d.]+\.tar\.gz', 
                f'tar zxf nextlnmp-{version}.tar.gz', readme)
readme = re.sub(r'cd nextlnmp-[\d.]+\b', 
                f'cd nextlnmp-{version}', readme)
readme = re.sub(r'nextlnmp-[\d.]+/', 
                f'nextlnmp-{version}/', readme)

# 更新 install.sh 头部注释版本号
import subprocess
subprocess.run(['sed', '-i', f's/一键安装引导脚本 v[0-9.]*/一键安装引导脚本 v{version}/', 'install.sh'])

with open('README.md', 'w') as f:
    f.write(readme)

# 清空 CHANGELOG_DRAFT
with open('CHANGELOG_DRAFT.md', 'w') as f:
    f.write('')

print(f"README updated to v{version}")
