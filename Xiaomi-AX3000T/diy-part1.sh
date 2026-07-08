#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
#echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
#echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default
#echo 'src-git messense https://github.com/messense/aliyundrive-webdav' >>feeds.conf.default
#
cat > feeds.conf.default << 'EOF'
src-git packages https://github.com/coolsnowwolf/packages
#src-git luci https://github.com/coolsnowwolf/luci
#src-git luci https://github.com/coolsnowwolf/luci.git;openwrt-23.05
#src-git luci https://github.com/coolsnowwolf/luci.git;openwrt-24.10
src-git luci https://github.com/coolsnowwolf/luci.git;openwrt-25.12
src-git routing https://github.com/coolsnowwolf/routing
src-git telephony https://github.com/coolsnowwolf/telephony.git
#src-git helloworld https://github.com/fw876/helloworld.git
#src-git qmodem https://github.com/FUjr/modem_feeds.git
#src-git video https://github.com/openwrt/video.git
#src-git targets https://github.com/openwrt/targets.git
#src-git oldpackages http://git.openwrt.org/packages.git
#src-link custom /usr/src/openwrt/custom-feed
EOF
