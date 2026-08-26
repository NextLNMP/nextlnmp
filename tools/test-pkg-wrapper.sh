#!/usr/bin/env bash
# 依赖安装容错外壳单测：Try_Install_Pkg 必须能区分「这个发行版没这个包」和「真失败」。
# 前者静默收集、最后统一说明；后者必须原样吐出并返回非 0——吞掉真失败就是假绿。
cur_dir=$(cd "$(dirname "$0")/.." && pwd)
Echo_Red() { echo "[红] $*"; }
Echo_Yellow() { echo "[黄] $*"; }

eval "$(sed -n '/^Pkg_Missing=""/,/^}/p;/^Report_Missing_Pkg()/,/^}/p' "${cur_dir}/include/init.sh")"

if ! declare -f Try_Install_Pkg >/dev/null; then
    echo "✗ 没能从 include/init.sh 里取出 Try_Install_Pkg"
    exit 1
fi

pass=0; fail=0
# 注意：不能用 out=$(Try_Install_Pkg ...) —— 那是子 shell，Pkg_Missing 传不回来。
# 产品里是在循环中直接调用的，所以这里也必须直接调用、把输出重定向到文件。
tmp_out=$(mktemp)
trap 'rm -f "${tmp_out}"' EXIT
check() { # check <说明> <期望返回码> <期望收集项> <实际返回码> <实际收集项>
    if [ "$2" = "$4" ] && [ "$3" = "$5" ]; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "  ✗ $1（期望 rc=$2 收集=[$3]，实际 rc=$4 收集=[$5]）"
    fi
}

yum_notfound()  { echo "Error: Unable to find a match: $1"; return 1; }
yum_nopackage() { echo "No package $1 available."; return 1; }
apt_notfound()  { echo "E: Unable to locate package $1"; return 1; }
apt_nocand()    { echo "E: Package '$1' has no installation candidate"; return 1; }
pm_ok()         { echo "Installed: $1"; return 0; }
pm_repofail()   { echo "Error: Failed to download metadata for repo appstream"; return 1; }
pm_conflict()   { echo "Error: Transaction test error: file conflict"; return 1; }

# 四种「查无此包」的措辞都要认出来，且不得留下噪音
for f in yum_notfound yum_nopackage apt_notfound apt_nocand; do
    Pkg_Missing=""
    Try_Install_Pkg "ghost-pkg" ${f} > "${tmp_out}"; rc=$?
    check "${f} 应静默收集" 0 "ghost-pkg" "${rc}" "${Pkg_Missing# }"
    [ -s "${tmp_out}" ] && { fail=$((fail + 1)); echo "  ✗ ${f} 不该有输出，实得：$(cat "${tmp_out}")"; }
done

# 装成功：原样输出、不进收集
Pkg_Missing=""
Try_Install_Pkg "gcc" pm_ok > "${tmp_out}"; rc=$?
check "成功应原样输出" 0 "" "${rc}" "${Pkg_Missing# }"
[ "$(cat "${tmp_out}")" = "Installed: gcc" ] || { fail=$((fail + 1)); echo "  ✗ 成功时输出被吞：$(cat "${tmp_out}")"; }

# 真失败：必须返回非 0、吐原始输出、不得混进「可选包」名单
for f in pm_repofail pm_conflict; do
    Pkg_Missing=""
    Try_Install_Pkg "make" ${f} > "${tmp_out}" 2>&1; rc=$?
    check "${f} 必须报错不吞" 1 "" "${rc}" "${Pkg_Missing# }"
    grep -q "Error" "${tmp_out}" || { fail=$((fail + 1)); echo "  ✗ ${f} 原始输出丢了"; }
done

# 汇总后必须清空，否则下一个发行版分支会重复报
Pkg_Missing=""
Try_Install_Pkg "ghost" yum_notfound >/dev/null
Report_Missing_Pkg >/dev/null
[ -z "${Pkg_Missing}" ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "  ✗ 汇总后没清空"; }
# 空名单时不该吭声
[ -z "$(Report_Missing_Pkg)" ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "  ✗ 空名单仍有输出"; }

if [ ${fail} -eq 0 ]; then
    echo "✓ 依赖安装容错外壳测试全部通过（查无此包 4 例 / 成功 1 例 / 真失败 2 例 / 汇总 2 例）"
    exit 0
fi
echo "✗ 失败 ${fail} 项，通过 ${pass} 项"
exit 1
