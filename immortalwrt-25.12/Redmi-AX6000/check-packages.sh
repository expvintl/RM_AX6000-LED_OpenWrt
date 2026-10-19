#!/bin/sh
# 编译前包清单对齐检查
#
# 目的：`make defconfig` 会把源码树里不存在的 CONFIG_PACKAGE_xxx 静默删掉。
#       老固件里的一堆 iptables/ipset 类包在新版可能已经改名或消失，
#       不检查就白编几个小时，刷进去才发现内核模块没了。
#
# 用法：./check-packages.sh <openwrt/.config>
# 退出码：0 = 关键包都在；1 = 有关键包被丢弃

set -u

CONFIG_PATH="${1:-openwrt/.config}"
LIST_PATH="$(dirname "$0")/packages.list"

[ -f "$CONFIG_PATH" ] || { echo "::error::找不到 $CONFIG_PATH"; exit 1; }
[ -f "$LIST_PATH" ]   || { echo "::error::找不到 $LIST_PATH";   exit 1; }

total=0
miss_crit=""
miss_opt=""

while IFS= read -r line || [ -n "$line" ]; do
    line=$(printf '%s' "$line" | tr -d '\r' | sed 's/[[:space:]]*$//')
    case "$line" in
        ''|\#*) continue ;;
    esac

    crit=0
    case "$line" in
        \!*) crit=1; line=${line#!} ;;
    esac

    total=$((total + 1))

    if grep -qx "CONFIG_PACKAGE_${line}=y" "$CONFIG_PATH"; then
        continue
    fi

    if [ "$crit" = 1 ]; then
        miss_crit="$miss_crit $line"
    else
        miss_opt="$miss_opt $line"
    fi
done < "$LIST_PATH"

echo "=============================================="
echo "包清单检查：共 $total 项"
echo "=============================================="

if [ -n "$miss_opt" ]; then
    echo "⚠️  以下可选包被 defconfig 丢弃（不影响编译，确认是否还需要）："
    for p in $miss_opt; do echo "    - $p"; done
    echo ""
fi

if [ -n "$miss_crit" ]; then
    echo "❌ 以下关键包没有生效，编译中止："
    for p in $miss_crit; do echo "    ✗ $p"; done
    echo ""
    echo "排查思路："
    echo "  1. 该包在新版是否改名（例如 luci-app-turboacc → luci-app-turboacc-mtk）"
    echo "  2. 是否已经被 nftables 体系取代（iptables-mod-* / ipset 之类）"
    echo "  3. 是否只在第三方 feed 里（easytier 这种），需要先在 diy-part1.sh 加源"
    echo "::error::关键包被丢弃:$miss_crit"
    exit 1
fi

echo "✅ 关键包全部在 .config 里生效"
