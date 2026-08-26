#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CLI 等价性校验器 —— v2 重构的安全绳。

把每个 CLI 文件拆成「函数体」+「顶层代码」两部分分别指纹化，
重构前存基线，重构后逐项比对：应当不变的必须逐字节不变。

用法：
  python3 tools/cli-fingerprint.py baseline > tools/cli-baseline.json
  python3 tools/cli-fingerprint.py check tools/cli-baseline.json [--allow allow.txt]
     --allow 列出「有意变更」的 文件:函数名（每行一条，# 开头为注释）
退出码：0=等价（或差异均在 allow 名单内），1=存在未申报的差异
"""
import hashlib
import io
import json
import os
import re
import sys

try:  # Windows 控制台默认 GBK，钉死 UTF-8 免得中文/符号炸掉
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

TARGETS = ['conf/nextlnmp', 'conf/nextlnmpa', 'conf/nextlamp', 'addons.sh']
FUNC_RE = re.compile(r'(?ms)^([A-Za-z_][A-Za-z0-9_.]*)\(\)\s*\n\{\n(.*?)^\}')


def sha1(text):
    return hashlib.sha1(text.encode('utf-8')).hexdigest()


def parse(path):
    """返回 (函数字典, 顶层代码)。顶层 = 抠掉所有函数定义后剩下的部分。"""
    src = io.open(path, encoding='utf-8').read()
    funcs = {}
    spans = []
    for m in FUNC_RE.finditer(src):
        funcs[m.group(1)] = m.group(2)
        spans.append((m.start(), m.end()))
    out, last = [], 0
    for a, b in spans:
        out.append(src[last:a])
        last = b
    out.append(src[last:])
    # 函数之间的纯空白间隔归一化：重构会改变函数顺序与空行，但那不是行为变化。
    # 只有真正的顶层代码（非空白）才参与指纹。
    parts = [seg for seg in out if seg.strip()]
    return funcs, chr(10).join(seg.strip() for seg in parts)


def fingerprint():
    data = {}
    for path in TARGETS:
        if not os.path.exists(path):
            continue
        funcs, toplevel = parse(path)
        data[path] = {
            'functions': {name: sha1(body) for name, body in funcs.items()},
            'toplevel': sha1(toplevel),
            'func_count': len(funcs),
        }
    return data


def load_allow(path):
    allow = set()
    if path and os.path.exists(path):
        for line in io.open(path, encoding='utf-8'):
            line = line.split('#')[0].strip()
            if line:
                allow.add(line)
    return allow


def check(baseline_path, allow_path=None):
    base = json.load(io.open(baseline_path, encoding='utf-8'))
    cur = fingerprint()
    allow = load_allow(allow_path)
    problems = []
    for path, b in base.items():
        c = cur.get(path)
        if c is None:
            problems.append('%s: 文件消失' % path)
            continue
        for name, h in b['functions'].items():
            key = '%s:%s' % (path, name)
            ch = c['functions'].get(name)
            if ch is None:
                if key not in allow:
                    problems.append('%s 函数消失（未申报）' % key)
            elif ch != h and key not in allow:
                problems.append('%s 函数体变化（未申报）' % key)
        for name in c['functions']:
            key = '%s:%s' % (path, name)
            if name not in b['functions'] and key not in allow:
                problems.append('%s 新增函数（未申报）' % key)
        if c['toplevel'] != b['toplevel'] and ('%s:__toplevel__' % path) not in allow:
            problems.append('%s 顶层代码变化（未申报）' % path)
    if problems:
        print('❌ 等价性校验失败，%d 处未申报差异：' % len(problems))
        for p in problems:
            print('   ' + p)
        return 1
    total = sum(v['func_count'] for v in cur.values())
    print('✓ 等价性校验通过（%d 个函数 + %d 个顶层块，申报豁免 %d 项）'
          % (total, len(cur), len(allow)))
    return 0


if __name__ == '__main__':
    mode = sys.argv[1] if len(sys.argv) > 1 else 'baseline'
    if mode == 'baseline':
        json.dump(fingerprint(), sys.stdout, ensure_ascii=False, indent=1, sort_keys=True)
        print()
    elif mode == 'check':
        allow = None
        if '--allow' in sys.argv:
            allow = sys.argv[sys.argv.index('--allow') + 1]
        sys.exit(check(sys.argv[2], allow))
    else:
        print(__doc__)
        sys.exit(2)
