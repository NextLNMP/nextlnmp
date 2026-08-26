#!/usr/bin/env bash
# ============================================================================
# NextLNMP CLI 生成器
# 把 conf/cli/ 源码树拼装成三个自包含管理脚本：
#   conf/nextlnmp  conf/nextlnmpa  conf/nextlamp
#
# 设计：复用发生在【构建期】，装到用户机上的 /bin/nextlnmp 仍是单文件自包含，
#       拷到任何机器都完整可用——重构不改变用户面的任何习惯。
#
# 装配规则（保证可证明的等价性）：
#   · 每个片段文件去掉首尾空行、以单个换行结尾
#   · 片段之间以一个空行连接（即 "\n\n"），与原始 CLI 的函数间隔一致
#   · 以 #@ 开头的行是「源码专用注释」，不进生成物
#
# 用法：bash tools/build-cli.sh [--check]
#   --check  只校验生成物与源码是否一致（CI drift 检查用），不写文件
# ============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."
SRC=conf/cli
MODE="${1:-}"
STACK_KEYS=(lnmp lnmpa lamp)
declare -A OUT=( [lnmp]=conf/nextlnmp [lnmpa]=conf/nextlnmpa [lamp]=conf/nextlamp )
rc=0

emit() { grep -v '^#@' "$1"; }   # 剥离源码专用注释

for key in "${STACK_KEYS[@]}"; do
    target="${OUT[$key]}"
    tmp="$(mktemp)"
    {
        emit "${SRC}/${key}.head.sh"
        printf '\n'
        emit "${SRC}/common.sh"
        printf '\n'
        emit "${SRC}/${key}.funcs.sh"
        printf '\n'
        emit "${SRC}/${key}.dispatch.sh"
    } > "$tmp"

    if ! bash -n "$tmp"; then
        echo "❌ 生成物语法错误：${target}"; rm -f "$tmp"; exit 1
    fi

    if [ "${MODE}" = "--check" ]; then
        if ! diff -q "$tmp" "$target" >/dev/null 2>&1; then
            echo "❌ drift：${target} 与 conf/cli/ 源码不一致，请运行 bash tools/build-cli.sh 后提交"
            rc=1
        else
            echo "✓ ${target} 与源码一致"
        fi
        rm -f "$tmp"
    else
        mv "$tmp" "$target"
        chmod +x "$target"
        echo "✓ 生成 ${target}（$(wc -l < "$target") 行）"
    fi
done
exit $rc
