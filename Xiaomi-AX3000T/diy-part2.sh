!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# Custom build script - Xiaomi AX3000T
# Optimized LuCI + ImmortalWrt enhancements

set -e

IMM_LUCI_BRANCH="openwrt-25.12"
STATUS_FILE="feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js"

echo "[1/5] Downloading LuCI system status patch..."

mkdir -p "$(dirname "$STATUS_FILE")"

curl -fsSL "https://raw.githubusercontent.com/immortalwrt/luci/${IMM_LUCI_BRANCH}/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js" \
  -o "$STATUS_FILE" || \
curl -fsSL "https://raw.githubusercontent.com/immortalwrt/luci/master/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js" \
  -o "$STATUS_FILE"


echo "[2/5] Patching LuCI RPC backend..."

python3 <<'PY'
from pathlib import Path

file = Path("feeds/luci/modules/luci-base/root/usr/share/rpcd/ucode/luci")

if not file.exists():
    raise SystemExit("LuCI RPC file not found")

s = file.read_text()

# protection anti double patch
if "getCPUInfo:" in s:
    print("Patch already applied, skipping.")
    exit(0)

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
                if (!fd)
                    return { cpuinfo: error() };

                let cpuinfo = fd.read('all') || '?';
                fd.close();

                return { cpuinfo: cpuinfo };
            }
        },

        getCPUUsage: {
            call: function() {
                const fd = popen("awk '/^cpu / {u=$2+$4; t=$2+$4+$5; if (t>0) printf(\"%.0f%%\", u*100/t);}' /proc/stat");

                if (!fd)
                    return { cpuusage: error() };

                let cpuusage = fd.read('all') || '?';
                fd.close();

                return { cpuusage: cpuusage };
            }
        },

        getTempInfo: {
            call: function() {
                if (!access('/sbin/tempinfo'))
                    return {};

                const fd = popen('/sbin/tempinfo');
                if (!fd)
                    return { tempinfo: error() };

                let tempinfo = fd.read('all') || '?';
                fd.close();

                return { tempinfo: tempinfo };
            }
        }
"""

marker_candidates = [
    "\n};\n\nreturn { luci: methods };",
    "\n}; return { luci: methods };"
]

for marker in marker_candidates:
    if marker in s:
        s = s.replace(marker, ",\n" + block.strip() + marker, 1)
        file.write_text(s)
        print("Patch applied successfully.")
        break
else:
    raise SystemExit("LuCI RPC end marker not found, aborting.")
PY


echo "[3/5] Adding ImmortalWrt packages..."

git clone -b openwrt-25.12 https://github.com/immortalwrt/immortalwrt.git tmp_imm
cp -r tmp_imm/package/emortal package/
rm -rf tmp_imm


echo "[4/5] Kernel tweak (mt76 / AX3000T)..."

sed -i '/AUTOLOAD:=$(call AutoProbe,mt7915e)/a \  MODPARAMS.mt7915e:=wed_enable=Y' package/kernel/mt76/Makefile


echo "[5/5] LuCI theme Argon..."

rm -rf package/luci-theme-argon package/luci-app-argon-config

git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config


echo "[6/5] Default WiFi + firewall config..."

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


echo "Done ✔"
