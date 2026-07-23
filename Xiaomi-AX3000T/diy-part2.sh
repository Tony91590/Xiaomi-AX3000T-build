#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
# 
# Custom for Xiaomi AX3000T stock

PATCH_FILE="$GITHUB_WORKSPACE/Xiaomi-AX3000T/diff.patch"
patch -p1 < "$PATCH_FILE"

mkdir -p target/linux/mediatek/filogic/base-files/etc/init.d
	
cat > target/linux/mediatek/filogic/base-files/etc/init.d/bootcount <<'BOOTCOUNT_EOF'
#!/bin/sh /etc/rc.common
# SPDX-License-Identifier: GPL-2.0-only

START=99

boot() {
	case $(board_name) in
	xiaomi,mi-router-ax3000t)
		. /lib/upgrade/common.sh
		[ "$(rootfs_type)" = "tmpfs" ] && \
			logger "bootcount: initramfs mode detected, exit" && \
			return 0
		[ "$(fw_printenv -n flag_try_sys2_failed 2>&1)" = "8" ] && \
			logger "bootcount: rd03 model detected, exit" && \
			return 0
		fw_setenv -s - <<-EOF
			flag_boot_rootfs 0
			flag_boot_success 1
			flag_last_success 0
			flag_ota_reboot 0
			flag_try_sys1_failed 0
			flag_try_sys2_failed 0
		EOF
		logger "bootcount: rd23 model detected, nvram was updated"
		;;
	esac
}
BOOTCOUNT_EOF

mkdir -p target/linux/mediatek/filogic/base-files/etc/rc.d
ln -sf ../init.d/bootcount target/linux/mediatek/filogic/base-files/etc/rc.d/S99bootcount
chmod 0755 target/linux/mediatek/filogic/base-files/etc/init.d/bootcount

cat > package/lean/default-settings/files/zzz-default-settings <<'DEFAULT_EOF'
#!/bin/sh

rm -f /usr/lib/lua/luci/view/admin_status/index/mwan.htm
rm -f /usr/lib/lua/luci/view/admin_status/index/upnp.htm
rm -f /usr/lib/lua/luci/view/admin_status/index/ddns.htm
rm -f /usr/lib/lua/luci/view/admin_status/index/minidlna.htm

rm -f /www/luci-static/resources/view/status/include/70_ddns.js
rm -f /www/luci-static/resources/view/status/include/80_upnp.js

sed -i 's/\"services\"/\"nas\"/g' /usr/lib/lua/luci/controller/aria2.lua
sed -i 's/services/nas/g' /usr/lib/lua/luci/view/aria2/overview_status.htm
sed -i 's/\"services\"/\"nas\"/g' /usr/lib/lua/luci/controller/hd_idle.lua
sed -i 's/\"services\"/\"nas\"/g' /usr/lib/lua/luci/controller/samba.lua
sed -i 's/\"services\"/\"nas\"/g' /usr/lib/lua/luci/controller/samba4.lua
sed -i 's/\"services\"/\"nas\"/g' /usr/lib/lua/luci/controller/minidlna.lua
sed -i 's/\"services\"/\"nas\"/g' /usr/lib/lua/luci/controller/transmission.lua
sed -i 's/\"services\"/\"nas\"/g' /usr/lib/lua/luci/controller/mjpg-streamer.lua
sed -i 's/\"services\"/\"nas\"/g' /usr/lib/lua/luci/controller/p910nd.lua
sed -i 's/\"services\"/\"nas\"/g' /usr/lib/lua/luci/controller/usb_printer.lua
sed -i 's/\"services\"/\"nas\"/g' /usr/lib/lua/luci/controller/xunlei.lua
sed -i 's/services/nas/g'  /usr/lib/lua/luci/view/minidlna_status.htm

sed -i 's/\"services\"/\"nas\"/g' /usr/share/luci/menu.d/luci-app-samba4.json

#sed -i 's#downloads.openwrt.org#mirrors.tencent.com/lede#g' /etc/opkg/distfeeds.conf
#sed -i 's#downloads.openwrt.org#mirrors.tencent.com/lede#g' /etc/apk/repositories.d/distfeeds.list
sed -i 's/root::0:0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:99999:7:::/g' /etc/shadow
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:99999:7:::/g' /etc/shadow

sed -i "s/# //g" /etc/opkg/distfeeds.conf
sed -i '/helloworld/d' /etc/opkg/distfeeds.conf
sed -i '/openwrt_luci/ { s/snapshots/releases\/18.06.9/g; }'  /etc/opkg/distfeeds.conf

sed -i '/check_signature/d' /etc/opkg.conf

sed -i '/REDIRECT --to-ports 53/d' /etc/firewall.user

sed -i '/DISTRIB_REVISION/d' /etc/openwrt_release
echo "DISTRIB_REVISION='R26.05.20'" >> /etc/openwrt_release
sed -i '/DISTRIB_DESCRIPTION/d' /etc/openwrt_release
echo "DISTRIB_DESCRIPTION='LEDE '" >> /etc/openwrt_release

sed -i '/OPENWRT_RELEASE/d' /usr/lib/os-release
echo 'OPENWRT_RELEASE="LEDE R26.05.20"' >> /usr/lib/os-release

sed -i '/log-facility/d' /etc/dnsmasq.conf
echo "log-facility=/dev/null" >> /etc/dnsmasq.conf

rm -rf /tmp/luci-modulecache/
rm -f /tmp/luci-indexcache

exit 0
DEFAULT_EOF

rm -f feeds/luci/modules/luci-mod-network/htdocs/luci-static/resources/view/network/wireless.js.orig
rm -f target/linux/mediatek/dts/mt7981b-xiaomi_mi-router.dtsi.orig
rm -f target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh.orig

STATUS_FILE="feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/channel_analysis.js"
mkdir -p "$(dirname "$STATUS_FILE")"
curl -fsSL "https://raw.githubusercontent.com/coolsnowwolf/luci/refs/heads/openwrt-24.10/modules/luci-mod-status/htdocs/luci-static/resources/view/status/channel_analysis.js" \
  -o "$STATUS_FILE"

feeds/luci/themes/luci-theme-argon

