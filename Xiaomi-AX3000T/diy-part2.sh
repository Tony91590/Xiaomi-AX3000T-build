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

# cp $GITHUB_WORKSPACE/Xiaomi-AX3000T/wireless.js feeds/luci/modules/luci-mod-network/htdocs/luci-static/resources/view/network/ \
#     && echo "✅ wireless.js"

# cp $GITHUB_WORKSPACE/Xiaomi-AX3000T/mt7981b-xiaomi-ax3000t.dts target/linux/mediatek/dts/ \
#     && echo "✅ mt7981b-xiaomi-ax3000t.dts copié"

# cp $GITHUB_WORKSPACE/Xiaomi-AX3000T/mt7981b-xiaomi_mi-router.dtsi target/linux/mediatek/dts/ \
#     && echo "✅ mt7981b-xiaomi_mi-router.dtsi copié"

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
