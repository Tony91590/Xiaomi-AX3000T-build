#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
# 
# Custom for Xiaomi AX3000T stock

# test
cp $GITHUB_WORKSPACE/Xiaomi-AX3000T/mt7981b-xiaomi_mi-router.dtsi feeds/luci/modules/luci-mod-network/htdocs/luci-static/resources/view/network/wireless.js\
    && echo "✅ testest"
# test

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
