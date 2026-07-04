#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
# 
# Custom for Xiaomi AX3000T
sed -i '/\["FR"\]/s/{ 1, 2 }/{ 1, 1 }/' package/mtk/applications/mtwifi-cfg/files/mtwifi-cfg/mtwifi_defs.lua
sed -i 's/default-settings-chn/default-settings/g' include/target.mk
sed -i 's/"turboacc\.config\.fullcone"="2"/"turboacc.config.fullcone"="0"/g' package/mtk/applications/luci-app-turboacc-mtk/root/etc/uci-defaults/turboacc
cat package/mtk/applications/luci-app-turboacc-mtk/root/etc/uci-defaults/turboacc
grep -R '\["FR"\]' package/mtk/applications/mtwifi-cfg/files/mtwifi-cfg/mtwifi_defs.lua
