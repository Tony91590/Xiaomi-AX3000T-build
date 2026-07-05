#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
# 
# Custom for Xiaomi AX3000T

IMM_LUCI_BRANCH="openwrt-25.12"
        STATUS_FILE="feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js"

        curl -fsSL "https://raw.githubusercontent.com/immortalwrt/luci/${IMM_LUCI_BRANCH}/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js" \
          -o "$STATUS_FILE" || \
        curl -fsSL "https://raw.githubusercontent.com/immortalwrt/luci/master/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js" \
          -o "$STATUS_FILE"

        # 3.给官方 luci RPC 后端补 ImmortalWrt 的 CPU 信息方法
        python3 <<'PY'
        from pathlib import Path

        p = Path("feeds/luci/modules/luci-base/root/usr/share/rpcd/ucode/luci")
        s = p.read_text()

        if "getCPUInfo:" not in s:
            block = r"""
        getCPUBench: {
            call: function() {
                return { cpubench: readfile('/etc/bench.log') || '' };
            }
        },

        getCPUInfo: {
            call: function() {
                if (!access('/sbin/cpuinfo'))
                    return {};

                const fd = popen('/sbin/cpuinfo');

                if (fd) {
                    let cpuinfo = fd.read('all');

                    if (!cpuinfo)
                        cpuinfo = '?';

                    fd.close();

                    return { cpuinfo: cpuinfo };
                }
                else {
                    return { cpuinfo: error() };
                }
            }
        },

        getCPUUsage: {
            call: function() {
                const fd = popen('top -n1 | awk \'/^CPU/ {printf("%d%%", 100 - $8)}\'');

                if (fd) {
                    let cpuusage = fd.read('all');

                    if (!cpuusage)
                        cpuusage = '?';

                    fd.close();

                    return { cpuusage: cpuusage };
                }
                else {
                    return { cpuusage: error() };
                }
            }
        },

        getTempInfo: {
            call: function() {
                if (!access('/sbin/tempinfo'))
                    return {};

                const fd = popen('/sbin/tempinfo');

                if (fd) {
                    let tempinfo = fd.read('all');

                    if (!tempinfo)
                        tempinfo = '?';

                    fd.close();

                    return { tempinfo: tempinfo };
                }
                else {
                    return { tempinfo: error() };
                }
            }
        }
        """

            marker = "\n};\n\nreturn { luci: methods };"

            if marker not in s:
                marker = "\n}; return { luci: methods };"

            if marker not in s:
                raise SystemExit("没有找到 luci RPC 文件结尾标记，未修改。")

            s = s.replace(marker, ",\n" + block.strip() + marker, 1)
            p.write_text(s)
        PY

git clone -b openwrt-25.12 https://github.com/immortalwrt/immortalwrt.git tmp_imm

cp -r tmp_imm/package/emortal package/
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
