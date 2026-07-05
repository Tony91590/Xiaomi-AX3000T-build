#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
# 
# Custom for Xiaomi AX3000T



git clone -b openwrt-25.12 https://github.com/immortalwrt/immortalwrt.git tmp_imm

cp -r tmp_imm/package/emortal package/emortal
rm -rf tmp_imm

sed -i '/AUTOLOAD:=$(call AutoProbe,mt7915e)/a \  MODPARAMS.mt7915e:=wed_enable=Y' package/kernel/mt76/Makefile

# ===== Argon Theme =====

rm -rf package/luci-theme-argon
rm -rf package/luci-app-argon-config

git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config

mkdir -p files/etc/uci-defaults

cat > files/etc/uci-defaults/99-default-settings << 'EOF'
#!/bin/sh

uci set wireless.@wifi-device[0].disabled='0'
uci set wireless.@wifi-iface[0].disabled='0'
uci set wireless.@wifi-iface[0].encryption='none'
uci set wireless.@wifi-iface[0].ssid="OpenWrt_2.4G"
uci set wireless.@wifi-device[1].disabled='0'
uci set wireless.@wifi-iface[1].disabled='0'
uci set wireless.@wifi-iface[1].encryption='none'
uci set wireless.@wifi-iface[1].ssid="OpenWrt_5G"
uci commit wireless

uci set firewall.@defaults[0].flow_offloading='1'
uci set firewall.@defaults[0].flow_offloading_hw='1'
uci commit firewall
  
rm -f /etc/uci-defaults/99-default-settings

exit 0
EOF

chmod +x files/etc/uci-defaults/99-default-settings
