#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""参数化保真校验器 —— 阶段 2 的安全绳。

公共函数用 ${Vhost_Dir} 这类栈变量替换了硬编码路径。本工具把变量按各栈的
实际取值渲染回去，与「重构前的基线指纹」逐函数比对：
凡是没有申报升级的栈，渲染结果必须与它原来的函数逐字节一致。

用法：python3 tools/cli-render-check.py tools/cli-baseline.json [--upgrades upgrades.txt]
  --upgrades 列出「有意为该栈升级」的 栈:函数名（这些不要求与基线一致，但会打印差异供审阅）
退出码：0=保真，1=存在未申报的渲染偏差
"""
import hashlib, io, json, re, sys

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

FUNC_RE = re.compile(r'(?ms)^([A-Za-z_][A-Za-z0-9_.]*)\(\)\s*\n\{\n(.*?)^\}')
STACK_FILE = {'lnmp': 'conf/nextlnmp', 'lnmpa': 'conf/nextlnmpa', 'lamp': 'conf/nextlamp'}

def stack_vars(key):
    """从生成物头部解析该栈的变量取值（单一事实源：头部声明）"""
    src = io.open(STACK_FILE[key], encoding='utf-8').read()
    head = src[:FUNC_RE.search(src).start()]
    return dict(re.findall(r"^([A-Z][A-Za-z_]*)='([^']*)'\s*(?:#.*)?$", head, re.M))

def render(body, vars_):
    out = body
    for k, v in sorted(vars_.items(), key=lambda kv: -len(kv[0])):
        out = out.replace('${%s}' % k, v)
    return out

def main():
    base = json.load(io.open(sys.argv[1], encoding='utf-8'))
    upgrades = set()
    if '--upgrades' in sys.argv:
        p = sys.argv[sys.argv.index('--upgrades') + 1]
        for line in io.open(p, encoding='utf-8'):
            line = line.split('#')[0].strip()
            if line:
                upgrades.add(line)
    common = {m.group(1): m.group(2)
              for m in FUNC_RE.finditer(io.open('conf/cli/common.sh', encoding='utf-8').read())}
    bad, upgraded, faithful = [], 0, 0
    for key, path in STACK_FILE.items():
        vars_ = stack_vars(key)
        for name, body in common.items():
            want = base.get(path, {}).get('functions', {}).get(name)
            if want is None:
                continue
            got = hashlib.sha1(render(body, vars_).encode('utf-8')).hexdigest()
            tag = '%s:%s' % (key, name)
            if got == want:
                faithful += 1
            elif tag in upgrades:
                upgraded += 1
            else:
                bad.append(tag)
    if bad:
        print('❌ 参数化保真校验失败，%d 处未申报偏差：' % len(bad))
        for b in bad:
            print('   ' + b)
        return 1
    print('✓ 参数化保真校验通过（%d 项渲染后与基线逐字节一致，%d 项为已申报升级）' % (faithful, upgraded))
    return 0

if __name__ == '__main__':
    sys.exit(main())
