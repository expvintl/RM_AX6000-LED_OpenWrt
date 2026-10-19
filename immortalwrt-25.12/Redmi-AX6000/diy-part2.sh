#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

##-----------------OpenClash 提前塞入 dev 内核（省得开机第一次再下载）------------------
OC_DIR="feeds/luci/applications/luci-app-openclash"
if [ -d "$OC_DIR" ]; then
  curl -fsSL -m 60 --retry 3 \
    https://raw.githubusercontent.com/vernesong/OpenClash/master/core-lateset/dev/clash-linux-arm64.tar.gz \
    -o /tmp/clash.tar.gz
  if [ -s /tmp/clash.tar.gz ]; then
    tar zxf /tmp/clash.tar.gz -C /tmp >/dev/null 2>&1
    chmod +x /tmp/clash >/dev/null 2>&1
    mkdir -p "$OC_DIR/root/etc/openclash/core"
    mv -f /tmp/clash "$OC_DIR/root/etc/openclash/core/clash"
    rm -f /tmp/clash.tar.gz
    echo "OpenClash core: $(ls -l "$OC_DIR/root/etc/openclash/core/clash" | awk '{print $5}') bytes"
  else
    echo "OpenClash core 下载失败，跳过（固件仍可编译，内核可在 LuCI 里装）"
  fi
else
  echo "未找到 $OC_DIR，跳过 OpenClash 内核注入"
fi
##----------------------------------------------------------------------------------------
