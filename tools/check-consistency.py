#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""一致性断言 —— 防止「菜单收了单，代码不发货」这类事故复发。

2026-08-24 审计的真实事故：菜单列出 MariaDB 11.8/12.3（DBSelect 12/13），
version.sh 有版本、镜像有包、下载也真发生了，唯独没有安装函数——用户装完
没有数据库。同类还有 PHP 8.4 在 multiplephp 菜单里缺席、addons 的 PHP 选择
菜单止步 8.2。这些都是「一处加了、另一处没跟」，靠本文件的断言拦下。

用法：python3 tools/check-consistency.py
退出码：0=一致，1=有断层
"""
import io, os, re, sys

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

def read(p):
    return io.open(p, encoding='utf-8').read() if os.path.exists(p) else ''

problems = []

def need(cond, msg):
    if not cond:
        problems.append(msg)

main_sh = read('include/main.sh')
version_sh = read('include/version.sh')
nextlnmp_sh = read('nextlnmp.sh')
only_sh = read('include/only.sh')
end_sh = read('include/end.sh')
php_sh = read('include/php.sh')
mariadb_sh = read('include/mariadb.sh')
mysql_sh = read('include/mysql.sh')
mphp_sh = read('include/multiplephp.sh')
frag = read('conf/cli/php-select.sh')

# ---- 1. 数据库：菜单选项 ⊆ version.sh 版本表 ⊆ 安装分发 ----
db_menu = set(re.findall(r'^\s*echo "(\d+): 安装 \$\{DB_Info\[', main_sh, re.M))
db_menu = set(re.findall(r'echo "(\d+): 安装 \$\{DB_Info\[\d+\]\}"', main_sh))
db_ver = set(re.findall(r'\[ "\$\{DBSelect\}" = "(\d+)" \]', version_sh))
# 两个安装入口必须【各自】都有分支：取并集会让一个文件的遗漏被另一个掩盖（本工具首版就踩过）
db_entries = {'nextlnmp.sh（整栈安装）': nextlnmp_sh, 'include/only.sh（单装数据库）': only_sh}
# end.sh 的收尾自检门（MariaDB 系）也必须认得该选项，否则装完被判失败
db_gate = set()
for grp in re.findall(r'DBSelect\}" =~ \^\(([0-9|]+)\)\$', end_sh):
    db_gate |= set(grp.split('|'))
db_gate |= set(re.findall(r'\[ "\$\{DBSelect\}" = "(\d+)" \]', end_sh))
for o in sorted(db_menu, key=int):
    need(o in db_ver, 'DBSelect=%s 在菜单里，但 include/version.sh 没有对应版本' % o)
    for label, src in db_entries.items():
        branches = set(re.findall(r'\[ "\$\{DBSelect\}" = "(\d+)" \]', src))
        need(o in branches, 'DBSelect=%s 在菜单里，但 %s 没有安装分发分支（收单不发货）' % (o, label))
    need(o in db_gate, 'DBSelect=%s 在菜单里，但 include/end.sh 的收尾自检不认它（装完会被判失败）' % o)

# ---- 2. PHP：菜单选项 ⊆ version.sh ⊆ Install_PHP_* 分发 ----
php_menu = set(re.findall(r'echo "(\d+): 安装 \$\{PHP_Info\[\d+\]\}"', main_sh))
php_ver = set(re.findall(r'\[ "\$\{PHPSelect\}" = "(\d+)" \]', version_sh))
php_dispatch = set(re.findall(r'\[ "\$\{PHPSelect\}" = "(\d+)" \]', nextlnmp_sh))
for o in sorted(php_menu, key=int):
    need(o in php_ver, 'PHPSelect=%s 在菜单里，但 include/version.sh 没有对应版本' % o)
    need(o in php_dispatch, 'PHPSelect=%s 在菜单里，但 nextlnmp.sh 没有 Install_PHP_* 分发分支' % o)

# ---- 3. 安装函数必须真实存在 ----
defined = set(re.findall(r'^([A-Za-z_][A-Za-z0-9_]*)\(\)', php_sh + mariadb_sh + mysql_sh, re.M))
for fn in sorted(set(re.findall(r'^\s+(Install_(?:PHP|MySQL|MariaDB)_\w+)\s*$', nextlnmp_sh, re.M))):
    need(fn in defined, '%s 被 nextlnmp.sh 调用，但 include/ 下没有定义' % fn)

# ---- 4. 多版本 PHP：单一事实源覆盖安装脚本能装的版本 ----
mphp_versions = set(re.findall(r"MPHP_VERSIONS='([^']+)'", frag)[0].split()) if re.search(r"MPHP_VERSIONS='", frag) else set()
mphp_paths = set(re.findall(r"MPHP_Path='/usr/local/php([\d.]+)'", mphp_sh))
for v in sorted(mphp_paths):
    need(v in mphp_versions, 'multiplephp.sh 能安装 PHP %s，但 conf/cli/php-select.sh 的 MPHP_VERSIONS 里没有它（装了也选不到）' % v)

# ---- 5. 公共函数不得在栈文件重定义 ----
common = set(re.findall(r'^([A-Za-z_][A-Za-z0-9_.]*)\(\)', read('conf/cli/common.sh'), re.M))
for k in ('lnmp', 'lnmpa', 'lamp'):
    stack = set(re.findall(r'^([A-Za-z_][A-Za-z0-9_.]*)\(\)', read('conf/cli/%s.funcs.sh' % k), re.M))
    for dup in sorted(common & stack):
        problems.append('%s 同时定义在 common.sh 与 %s.funcs.sh（后定义者静默覆盖前者）' % (dup, k))

if problems:
    print('❌ 一致性断言失败，%d 处断层：' % len(problems))
    for p in problems:
        print('   ' + p)
    sys.exit(1)
print('✓ 一致性断言通过（数据库 %d 项 / PHP %d 项 / 多版本 PHP %d 项，均已菜单↔版本表↔安装函数三方对齐）'
      % (len(db_menu), len(php_menu), len(mphp_paths)))
