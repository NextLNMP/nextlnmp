#!/usr/bin/env bash
# 依赖安装容错外壳单测：Try_Install_Pkg 必须能区分「这个发行版没这个包」和「真失败」。
# 前者静默收集、最后统一说明；后者必须原样吐出并返回非 0——吞掉真失败就是假绿。
cur_dir=$(cd "$(dirname "$0")/.." && pwd)
Echo_Red() { echo "[红] $*"; }
Echo_Yellow() { echo "[黄] $*"; }

eval "$(sed -n '/^PKG_CRITICAL=/p;/^Pkg_Missing=""/,/^}/p;/^Report_Missing_Pkg()/,/^}/p' "${cur_dir}/include/init.sh")"

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



# ── 源整个坏了的场景（原修复在这里会假绿）─────────────────────────────
# 软件源不可用时 apt/yum 会对【每一个】包都说 not found，包括 gcc/make。
# 若照样静默收集，用户会看到一句「不影响安装」，二十分钟后才在 ./configure
# 炸出 no acceptable C compiler。所以必需件必须当场报错、返回非 0。
for crit in gcc make g++ cmake build-essential; do
    Pkg_Missing=""
    Try_Install_Pkg "${crit}" yum_notfound > "${tmp_out}" 2>&1; rc=$?
    check "必需件 ${crit} 不得被吞" 1 "" "${rc}" "${Pkg_Missing# }"
    grep -q "软件源" "${tmp_out}" || { fail=$((fail + 1)); echo "  ✗ ${crit} 没给出「源坏了」的提示"; }
done

# 反面：非必需件仍要静默收集，别把护栏做成一刀切
Pkg_Missing=""
Try_Install_Pkg "libpng10-devel" yum_notfound > "${tmp_out}" 2>&1; rc=$?
check "非必需件仍静默收集" 0 "libpng10-devel" "${rc}" "${Pkg_Missing# }"

# 必需件即便是「真失败」也一样要报（不能因为在名单里就走别的分支）
Pkg_Missing=""
Try_Install_Pkg "gcc" pm_repofail > "${tmp_out}" 2>&1; rc=$?
check "必需件真失败也要报" 1 "" "${rc}" "${Pkg_Missing# }"

# ── 静态断言：用到 Try_Install_Pkg 的文件，其入口必须先 source include/init.sh ──
# 否则运行到那一行才会 "command not found"，而依赖安装往往在安装流程深处。
users=$(grep -rl "Try_Install_Pkg" "${cur_dir}/include" 2>/dev/null | grep -v "init.sh$" | xargs -r -n1 basename)
for u in ${users}; do
    entry=$(grep -rl "\. include/${u}" "${cur_dir}"/*.sh 2>/dev/null)
    if [ -z "${entry}" ]; then
        fail=$((fail + 1)); echo "  ✗ include/${u} 用了 Try_Install_Pkg 却没有入口 source 它"
        continue
    fi
    for e in ${entry}; do
        init_ln=$(grep -n "^\. include/init\.sh" "${e}" | head -1 | cut -d: -f1)
        use_ln=$(grep -n "^\. include/${u}" "${e}" | head -1 | cut -d: -f1)
        if [ -z "${init_ln}" ]; then
            fail=$((fail + 1)); echo "  ✗ $(basename ${e}) source 了 ${u} 却没 source init.sh"
        elif [ "${init_ln}" -gt "${use_ln}" ]; then
            fail=$((fail + 1)); echo "  ✗ $(basename ${e}) 先 source ${u}（第${use_ln}行）后 source init.sh（第${init_ln}行），顺序反了"
        else
            pass=$((pass + 1))
        fi
    done
done

if [ ${fail} -eq 0 ]; then
    echo "✓ 依赖安装容错外壳测试全部通过（查无此包 4 / 成功 1 / 真失败 2 / 汇总 2 / 必需件不吞 7 / source 顺序若干，共 ${pass} 项）"
    exit 0
fi
echo "✗ 失败 ${fail} 项，通过 ${pass} 项"
exit 1
