#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
# 
# Custom for Xiaomi AX3000T stock

cp $GITHUB_WORKSPACE/Xiaomi-AX3000T/mt7981b-xiaomi-ax3000t.dts target/linux/mediatek/dts/ \
    && echo "✅ mt7981b-xiaomi-ax3000t.dts copié"

cp $GITHUB_WORKSPACE/Xiaomi-AX3000T/mt7981b-xiaomi_mi-router.dtsi target/linux/mediatek/dts/ \
    && echo "✅ mt7981b-xiaomi_mi-router.dtsi copié"

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

cat > target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh <<'PLATFORM_EOF'
REQUIRE_IMAGE_METADATA=1
RAMFS_COPY_BIN='fitblk fit_check_sign'

xiaomi_initial_setup()
{
	# initialize UBI and setup uboot-env if it's running on initramfs
	[ "$(rootfs_type)" = "tmpfs" ] || return 0

	local mtdnum="$( find_mtd_index ubi )"
	if [ ! "$mtdnum" ]; then
		echo "unable to find mtd partition ubi"
		return 1
	fi

	local kern_mtdnum="$( find_mtd_index ubi_kernel )"
	if [ ! "$kern_mtdnum" ]; then
		echo "unable to find mtd partition ubi_kernel"
		return 1
	fi

	ubidetach -m "$mtdnum"
	ubiformat /dev/mtd$mtdnum -y

	ubidetach -m "$kern_mtdnum"
	ubiformat /dev/mtd$kern_mtdnum -y

	if ! fw_printenv -n flag_try_sys2_failed &>/dev/null; then
		echo "failed to access u-boot-env. skip env setup."
		return 0
	fi

	fw_setenv -s - <<-EOF
		boot_wait on
		uart_en 1
		flag_boot_rootfs 0
		flag_last_success 1
		flag_boot_success 1
		flag_try_sys1_failed 8
		flag_try_sys2_failed 8
	EOF

	local board=$(board_name)
	case "$board" in
	xiaomi,mi-router-ax3000t)
		fw_setenv mtdparts "nmbm0:1024k(bl2),256k(Nvram),256k(Bdata),2048k(factory),2048k(fip),256k(crash),256k(crash_log),34816k(ubi),34816k(ubi1),32768k(overlay),12288k(data),256k(KF)"
		;;
	esac
}

platform_do_upgrade() {
	local board=$(board_name)

	case "$board" in
	xiaomi,mi-router-ax3000t)
		CI_KERN_UBIPART=ubi_kernel
		CI_ROOT_UBIPART=ubi
		nand_do_upgrade "$1"
		;;
	*)
		nand_do_upgrade "$1"
		;;
	esac
}

PART_NAME=firmware

platform_check_image() {
	local board=$(board_name)

	[ "$#" -gt 1 ] && return 1

	case "$board" in
	xiaomi,mi-router-ax3000t)
		nand_do_platform_check "$board" "$1"
		return $?
		;;
	esac

	return 0
}

platform_pre_upgrade() {
	local board=$(board_name)

	case "$board" in
	xiaomi,mi-router-ax3000t)
		xiaomi_initial_setup
		;;
	esac
}
PLATFORM_EOF

sed -i 's/ntp.aliyun.com/0.openwrt.pool.ntp.org/g' package/base-files/files/bin/config_generate
sed -i 's/time1.cloud.tencent.com/1.openwrt.pool.ntp.org/g' package/base-files/files/bin/config_generate
sed -i 's/time.ustc.edu.cn/2.openwrt.pool.ntp.org/g' package/base-files/files/bin/config_generate
sed -i 's/cn.pool.ntp.org/3.openwrt.pool.ntp.org/g' package/base-files/files/bin/config_generate
sed -i 's/zh_cn/auto/g' feeds/luci/modules/luci-base/root/etc/uci-defaults/luci-base 
cp $GITHUB_WORKSPACE/Xiaomi-AX3000T/index.htm package/lean/autocore/files/arm/
cp $GITHUB_WORKSPACE/Xiaomi-AX3000T/zones.lua feeds/luci/applications/luci-app-firewall/luasrc/model/cbi/firewall/

mkdir -p files/sbin

cat > files/sbin/tempinfo <<'EOF'
#!/bin/sh
#
# MediaTek Filogic platform support: CPU and WiFi temperature monitoring

IEEE_PATH="/sys/class/ieee80211"
THERMAL_PATH="/sys/class/thermal"

wifi_temp="$(awk '{printf("%.1f°C ", $0 / 1000)}' "$IEEE_PATH"/phy*/hwmon*/temp1_input 2>"/dev/null" | awk '$1=$1')"
cpu_temp="$(awk '{printf("%.1f°C", $0 / 1000)}' "$THERMAL_PATH/thermal_zone0/temp" 2>"/dev/null")"

echo -n "CPU: $cpu_temp, WiFi: $wifi_temp"
EOF

chmod +x files/sbin/tempinfo

rm -rf package/luci-theme-argon_new

git clone --depth=1 https://github.com/Tony91590/luci-theme-argon_new.git package/luci-theme-argon_new

cat > package/lean/default-settings/files/zzz-default-settings <<'DEFAULT_EOF'
#!/bin/sh

uci set fstab.@global[0].anon_mount=1
uci commit fstab

rm -f /usr/lib/lua/luci/view/admin_status/index/mwan.htm
rm -f /usr/lib/lua/luci/view/admin_status/index/upnp.htm
rm -f /usr/lib/lua/luci/view/admin_status/index/ddns.htm
rm -f /usr/lib/lua/luci/view/admin_status/index/minidlna.htm

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

#ln -sf /sbin/ip /usr/bin/ip

sed -i 's#downloads.openwrt.org#mirrors.cloud.tencent.com/lede#g' /etc/opkg/distfeeds.conf
sed -i 's/root::0:0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:99999:7:::/g' /etc/shadow
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:99999:7:::/g' /etc/shadow

sed -i "s/# //g" /etc/opkg/distfeeds.conf
sed -i '/openwrt_luci/ { s/snapshots/releases\/18.06.9/g; }'  /etc/opkg/distfeeds.conf

sed -i '/check_signature/d' /etc/opkg.conf

sed -i '/REDIRECT --to-ports 53/d' /etc/firewall.user
#echo 'iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user
#echo 'iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user
#echo '[ -n "$(command -v ip6tables)" ] && ip6tables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user
#echo '[ -n "$(command -v ip6tables)" ] && ip6tables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user

#echo 'iptables -A OUTPUT -m string --string "api.installer.xiaomi.cn" --algo bm --to 65535 -j DROP' >> /etc/firewall.user

sed -i '/option disabled/d' /etc/config/wireless
sed -i '/set wireless.radio${devidx}.disabled/d' /lib/wifi/mac80211.sh

sed -i '/DISTRIB_REVISION/d' /etc/openwrt_release
echo "DISTRIB_REVISION='R24.5.1'" >> /etc/openwrt_release
sed -i '/DISTRIB_DESCRIPTION/d' /etc/openwrt_release
echo "DISTRIB_DESCRIPTION='OpenWrt '" >> /etc/openwrt_release

sed -i '/log-facility/d' /etc/dnsmasq.conf
echo "log-facility=/dev/null" >> /etc/dnsmasq.conf

rm -rf /tmp/luci-modulecache/
rm -f /tmp/luci-indexcache

exit 0
DEFAULT_EOF
