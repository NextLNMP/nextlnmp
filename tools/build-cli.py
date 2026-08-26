#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CLI 生成器 —— 把 conf/cli/ 下的公共库与各栈源码拼装成三个自包含 CLI。

设计：复用发生在【构建期】而不是运行期，生成物 conf/nextlnmp{,a}、conf/nextlamp
仍是单文件自包含脚本，用户拷到任何机器都完整可用。

源码布局：
  conf/cli/common.sh          三栈共享函数（唯一副本）
  conf/cli/{lnmp,lnmpa,lamp}.sh  各栈：头部 + #@include-common 标记 + 本栈函数 + 分发尾部

用法：
  python3 tools/build-cli.py           # 生成
  python3 tools/build-cli.py --check   # 只校验生成物与源码一致（CI 用，有漂移则退出 1）
"""
import io
import os
import re
import sys

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

MARKER = '#@include-common'
STACKS = [
    ('conf/cli/lnmp.sh', 'conf/nextlnmp'),
    ('conf/cli/lnmpa.sh', 'conf/nextlnmpa'),
    ('conf/cli/lamp.sh', 'conf/nextlamp'),
]
COMMON = 'conf/cli/common.sh'
FUNC_RE = re.compile(r'(?ms)^([A-Za-z_][A-Za-z0-9_.]*)\(\)\s*\n\{\n.*?^\}')


def read(path):
    return io.open(path, encoding='utf-8').read()


def common_block():
    """公共库正文：剥掉文件头注释，只留函数定义，按 \n\n 连接。"""
    src = read(COMMON)
    funcs = [m.group(0) for m in FUNC_RE.finditer(src)]
    if not funcs:
        raise SystemExit('公共库里没找到任何函数定义：%s' % COMMON)
    return '\n\n'.join(funcs)


def render(stack_path):
    src = read(stack_path)
    lines = src.split('\n')
    hits = [i for i, l in enumerate(lines) if l.strip() == MARKER]
    if len(hits) != 1:
        raise SystemExit('%s 需要恰好一个 %s 标记，实际 %d 个' % (stack_path, MARKER, len(hits)))
    i = hits[0]
    return '\n'.join(lines[:i] + [common_block()] + lines[i + 1:])


def main():
    check_only = '--check' in sys.argv
    drift = []
    for stack_path, out_path in STACKS:
        want = render(stack_path)
        have = read(out_path) if os.path.exists(out_path) else None
        if check_only:
            if have != want:
                drift.append(out_path)
        elif have != want:
            io.open(out_path, 'w', encoding='utf-8', newline='\n').write(want)
            print('已生成 %s（%d 字节）' % (out_path, len(want)))
        else:
            print('%s 无变化' % out_path)
    if check_only:
        if drift:
            print('❌ 生成物与源码漂移，请重跑 tools/build-cli.py 并提交：')
            for d in drift:
                print('   ' + d)
            return 1
        print('✓ 生成物与源码一致（%d 个 CLI）' % len(STACKS))
    return 0


if __name__ == '__main__':
    sys.exit(main())
