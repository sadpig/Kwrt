#!/bin/bash

shopt -s extglob
SHELL_FOLDER=$(dirname $(readlink -f "$0"))

#bash $SHELL_FOLDER/../common/kernel_6.6.sh

sed -i -E -e 's/ ?root=\/dev\/fit0 rootwait//' -e "/rootdisk =/d" -e '/bootargs.* = ""/d' target/linux/mediatek/dts/*{qihoo-360t7,netcore-n60*,h3c-magic-nx30-pro,jdcloud-re-cp-03,cmcc-rax3000m,jcg-q30-pro,tplink-tl-xdr*,abt-asr3000,komi-a31,nokia-ea0326gmp,bt-r320}*.dts*

# ---- fork-local: Twrt branding (runs after common diy.sh which did OpenWrt->Kwrt) ----
# dist name / hostname / default Wi-Fi SSID / image prefix
sed -i "s/Kwrt/Twrt/g" package/base-files/files/bin/config_generate \
	package/base-files/image-config.in \
	package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc \
	config/Config-images.in Config.in include/u-boot.mk include/version.mk || true

# default LAN IP: 10.0.0.1 -> 10.10.8.1 (common diy.sh set 192.168.1 -> 10.0.0)
sed -i "s/10\.0\.0\./10.10.8./g" package/base-files/files/bin/config_generate

# rebrand kiddin9 my-default-settings (hostname fallback, dhcp domain, wizard/nginx shortcuts, IPs)
for f in feeds/kiddin9/my-default-settings/files/etc/uci-defaults/99-default-settings \
	 feeds/kiddin9/my-default-settings/files/etc/config/base_config; do
	[ -f "$f" ] && sed -i -e "s/Kwrt/Twrt/g" -e "s/kwrt/twrt/g" -e "s/10\.0\.0\./10.10.8./g" "$f" || true
done

# fix duplicated "首页" menu: luci-app-wizard registers a visible "Home"(首页)
# top menu at admin/index which just redirects to admin/quickstart, while
# luci-app-quickstart's menu.d JSON already shows "QuickStart"(首页).
# Hide wizard's menu title (keep the landing redirect working).
sed -i 's/, _("Home") , 1).dependent = false/).dependent = false/' \
	feeds/kiddin9/luci-app-wizard/luasrc/controller/wizard.lua || true

# vendor iStore from upstream into core package/ dir: the kiddin9-feed copy
# installs but its config symbol never appears after defconfig (feed index
# polluted by broken webd Makefile); core packages take precedence and always
# get indexed.
git clone --depth 1 https://github.com/linkease/istore.git /tmp/istore-src && {
	mkdir -p package/istore
	cp -a /tmp/istore-src/luci/* package/istore/
	rm -rf /tmp/istore-src
}

exit 0
