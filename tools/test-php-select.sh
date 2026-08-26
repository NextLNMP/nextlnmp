#!/usr/bin/env bash
# 多版本 PHP 探测/选择的离线单元测试（伪造安装目录，不依赖真实环境）
# 用法：bash tools/test-php-select.sh
Echo_Green(){ :; }; Echo_Yellow(){ :; }
R=$(mktemp -d); export MPHP_ROOT="$R/usr/local" MPHP_NGXCONF="$R/nginx" MPHP_INITD="$R/initd"
mkdir -p "$MPHP_ROOT" "$MPHP_NGXCONF" "$MPHP_INITD"
mk(){ mkdir -p "$MPHP_ROOT/php$1/sbin"; echo x > "$MPHP_ROOT/php$1/sbin/php-fpm"; echo x > "$MPHP_NGXCONF/enable-php$1.conf"; echo x > "$MPHP_INITD/php-fpm$1"; }
cd "$(dirname "$0")/.."
. "${1:-conf/cli/php-select.sh}"
fail=0
chk(){ [ "$2" = "$3" ] && echo "  ✓ $1 → [$2]" || { echo "  ✗ $1 → [$2] 期望 [$3]"; fail=1; }; }
mk 8.3; mk 5.6
PHP_Multi_Detect >/dev/null; chk "探测" "${MPHP_FOUND}" "5.6 8.3"
PHP_Multi_Select <<< "15" >/dev/null; chk "选 15(=8.3)" "${PHP_Select_Ver}" "8.3"
PHP_Multi_Select <<< "6"  >/dev/null; chk "选 6(=5.6)"  "${PHP_Select_Ver}" "5.6"
PHP_Multi_Select <<< ""   >/dev/null; chk "回车(主PHP)" "${PHP_Select_Ver}" ""
PHP_Multi_Select <<< "1"  >/dev/null; chk "选 1(主PHP)" "${PHP_Select_Ver}" ""
PHP_Multi_Select <<< "3"  >/dev/null; chk "选 3(未装,回落)" "${PHP_Select_Ver}" ""
PHP_Multi_Select <<< "99" >/dev/null; chk "越界(回落)"  "${PHP_Select_Ver}" ""
PHP_Multi_Select <<< "abc" >/dev/null; chk "非数字(回落)" "${PHP_Select_Ver}" ""
rm -rf "$MPHP_ROOT/php8.3"; PHP_Multi_Detect >/dev/null; chk "移除后重探" "${MPHP_FOUND}" "5.6"
rm -rf "$R"; exit $fail
