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

##-----------------OpenClash 提前塞入内核（省得开机第一次再下载）------------------
OC_DIR="feeds/luci/applications/luci-app-openclash"

## 内核早就不在 master 分支的 core-lateset/dev 下了（那个路径现在 404），
## 现在放在独立的 core 分支 meta 目录（mihomo / clash.meta），dev 比 master 新。
## 两个地址按顺序试，都失败就跳过——固件照样能编译，内核可以在 LuCI 里在线装。
CORE_URLS="
https://raw.githubusercontent.com/vernesong/OpenClash/core/dev/meta/clash-linux-arm64.tar.gz
https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-arm64.tar.gz
"

if [ -d "$OC_DIR" ]; then
  rm -f /tmp/clash.tar.gz /tmp/clash
  for core_url in $CORE_URLS; do
    echo "尝试下载 OpenClash 内核: $core_url"
    if curl -fSL -m 120 --retry 3 -o /tmp/clash.tar.gz "$core_url"; then
      break
    fi
    rm -f /tmp/clash.tar.gz
  done

  if [ -s /tmp/clash.tar.gz ]; then
    if tar zxf /tmp/clash.tar.gz -C /tmp >/dev/null 2>&1 && [ -f /tmp/clash ]; then
      chmod +x /tmp/clash
      mkdir -p "$OC_DIR/root/etc/openclash/core"
      mv -f /tmp/clash "$OC_DIR/root/etc/openclash/core/clash"
      echo "OpenClash core: $(ls -l "$OC_DIR/root/etc/openclash/core/clash" | awk '{print $5}') bytes"
    else
      echo "OpenClash 内核解包失败，跳过（固件仍可编译，内核可在 LuCI 里装）"
    fi
    rm -f /tmp/clash.tar.gz
  else
    echo "OpenClash core 下载失败，跳过（固件仍可编译，内核可在 LuCI 里装）"
  fi
else
  echo "未找到 $OC_DIR，跳过 OpenClash 内核注入"
fi
##----------------------------------------------------------------------------------------
