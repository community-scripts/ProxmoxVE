#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

echo -e "\e[1;33m This script will allow USB passthrough to a PRIVILEGED LXC Container ONLY\e[0m"
while true; do
  read -p "Did you replace 106 with your LXC ID? Proceed(y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) exit ;;
  *) echo "Please answer yes or no." ;;
  esac
done

TEMP_DIR=$(mktemp -d)
pushd $TEMP_DIR >/dev/null
CHAR_DEVS+=("166:.*")
CHAR_DEVS+=("188:.*")
CHAR_DEVS+=("189:.*")

for char_dev in ${CHAR_DEVS[@]}; do
  [ ! -z "${CHAR_DEV_STRING-}" ] && CHAR_DEV_STRING+=" -o"
  CHAR_DEV_STRING+=" -regex \".*/${char_dev}\""
done

read -r -d '' HOOK_SCRIPT <<-EOF || true
for char_dev in \$(find /sys/dev/char -regextype sed $CHAR_DEV_STRING); do
  dev="/dev/\$(sed -n "/DEVNAME/ s/^.*=\(.*\)$/\1/p" \${char_dev}/uevent)";
  mkdir -p \$(dirname \${LXC_ROOTFS_MOUNT}\${dev});
  for link in \$(udevadm info --query=property \$dev | sed -n "s/DEVLINKS=//p"); do
    mkdir -p \${LXC_ROOTFS_MOUNT}\$(dirname \$link);
    cp -dpR \$link \${LXC_ROOTFS_MOUNT}\${link};
  done;
  cp -dpR \$dev \${LXC_ROOTFS_MOUNT}\${dev};
done;
EOF
HOOK_SCRIPT=${HOOK_SCRIPT//$'\n'/}

CTID=$1
CTID_CONFIG_PATH=/etc/pve/lxc/${CTID}.conf
sed '/autodev/d' $CTID_CONFIG_PATH >CTID.conf
cat CTID.conf >$CTID_CONFIG_PATH

cat <<EOF >>$CTID_CONFIG_PATH
lxc.autodev: 1
lxc.hook.autodev: bash -c '$HOOK_SCRIPT'
EOF
echo -e "\e[1;33m Finished....Reboot ${CTID} LXC to apply the changes \e[0m"
