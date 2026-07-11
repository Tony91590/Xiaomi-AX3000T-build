#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
# 
# Custom for Xiaomi AX3000T
cp $GITHUB_WORKSPACE/Xiaomi-AX3000T/patch/7661-022-fix-rrm-snprintf-error.patch package/mtk/drivers/mt_wifi/patches-7673/
cp $GITHUB_WORKSPACE/Xiaomi-AX3000T/patch/7661-022-fix-rrm-snprintf-error.patch package/mtk/drivers/mt_wifi/patches-7661/
sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate
sed -i '/\["FR"\]/s/{ 1, 2 }/{ 1, 1 }/' package/mtk/applications/mtwifi-cfg/files/mtwifi-cfg/mtwifi_defs.lua
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt-2.4G/OpenWrt-2.4G/g' package/mtk/applications/mtwifi-cfg/files/mtwifi.sh
sed -i 's/ImmortalWrt-5G/OpenWrt-5G/g' package/mtk/applications/mtwifi-cfg/files/mtwifi.sh
sed -i 's/ImmortalWrt-6G/OpenWrt-6G/g' package/mtk/applications/mtwifi-cfg/files/mtwifi.sh
sed -i 's/pool.ntp.org/3.openwrt.pool.ntp.org/g' package/base-files/files/bin/config_generate
sed -i 's/time1.apple.com/0.openwrt.pool.ntp.org/g' package/base-files/files/bin/config_generate
sed -i 's/time1.google.com/1.openwrt.pool.ntp.org/g' package/base-files/files/bin/config_generate
sed -i 's/time.cloudflare.com/2.openwrt.pool.ntp.org/g' package/base-files/files/bin/config_generate
sed -i 's/default-settings-chn/default-settings/g' include/target.mk
sed -i 's/ImmortalWrt/OpenWrt/g' include/version.mk
sed -i 's,https://immortalwrt.org/,https://openwrt.org/,g' include/version.mk
sed -i 's,https://github.com/immortalwrt/immortalwrt/issues,https://bugs.openwrt.org/,g' include/version.mk
sed -i 's,https://github.com/immortalwrt/immortalwrt/discussions,https://forum.openwrt.org/,g' include/version.mk
sed -i 's/Xiaomi Mi Router AX3000T (stock layout)/Xiaomi Mi Router AX3000T/g' target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7981-xiaomi-mi-router-ax3000t-stock.dts
cat > package/base-files/files/etc/banner << EOF
  _______                     ________        __
 |       |.-----.-----.-----.|  |  |  |.----.|  |_
 |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|
 |_______||   __|_____|__|__||________||__|  |____|
          |__| W I R E L E S S   F R E E D O M
 -----------------------------------------------------
 %D %V, %C
 -----------------------------------------------------
EOF
grep -n "OpenWrt" package/mtk/applications/mtwifi-cfg/files/mtwifi.sh
grep -R '\["FR"\]' package/mtk/applications/mtwifi-cfg/files/mtwifi-cfg/mtwifi_defs.lua

cat > target/linux/mediatek/mt7981/base-files/etc/init.d/bootcount <<'BOOTCOUNT_EOF'
#!/bin/sh /etc/rc.common
# SPDX-License-Identifier: GPL-2.0-only

START=99

boot() {
	case $(board_name) in
	xiaomi,mi-router-ax3000t-stock)
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
