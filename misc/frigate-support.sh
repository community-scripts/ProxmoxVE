#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
    clear
cat <<"EOF"
   ____    _           __        ____                        __
  / __/___(_)__ ____ _/ /____   / __/_ _____  ___  ___  ____/ /_
 / _// __/ / _ `/ _ `/ __/ -_) _\ \/ // / _ \/ _ \/ _ \/ __/ __/
/_/ /_/ /_/\_, /\_,_/\__/\__/ /___/\_,_/ .__/ .__/\___/_/  \__/
          /___/                       /_/  /_/
EOF
}
header_info
while true; do
  read -p "This will Prepare a LXC Container for Frigate. Proceed (y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) exit ;;
  *) echo "Please answer yes or no." ;;
  esac
done
header_info

# The array of device types
# CHAR_DEVS+=(major:minor)
CHAR_DEVS+=("1:1") # mem
CHAR_DEVS+=("29:0") # fb0
CHAR_DEVS+=("188:.*") # ttyUSB*
CHAR_DEVS+=("189:.*") # bus/usb/*
CHAR_DEVS+=("226:0") # card0
CHAR_DEVS+=("226:128") # renderD128

# Proccess char device string
for char_dev in ${CHAR_DEVS[@]}; do
  [ ! -z "${CHAR_DEV_STRING-}" ] && CHAR_DEV_STRING+=" -o"
  CHAR_DEV_STRING+=" -regex \".*/${char_dev}\""
done

# Store autodev hook script in a variable
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

# Remove newline char from the variable
HOOK_SCRIPT=${HOOK_SCRIPT//$'\n'/}

# Generate menu of LXC containers in current node
NODE=$(hostname)
while read -r line; do
  TAG=$(echo "$line" | awk '{print $1}')
  ITEM=$(echo "$line" | awk '{print substr($0,36)}')
  OFFSET=2
  if [[ $((${#ITEM} + $OFFSET)) -gt ${MSG_MAX_LENGTH:-} ]]; then
    MSG_MAX_LENGTH=$((${#ITEM} + $OFFSET))
  fi
  CTID_MENU+=("$TAG" "$ITEM " "OFF")
done < <(pct list | awk 'NR>1')

# Selection menu for LXC containers
while [ -z "${CTID:+x}" ]; do
  CTID=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Containers on $NODE" --radiolist \
    "\nSelect a container to add support:\n" \
    16 $(($MSG_MAX_LENGTH + 23)) 6 \
    "${CTID_MENU[@]}" 3>&1 1>&2 2>&3) || exit
done

# Add autodev settings
CTID_CONFIG_PATH=/etc/pve/lxc/${CTID}.conf
sed '/autodev/d' $CTID_CONFIG_PATH >CTID.conf
cat CTID.conf >$CTID_CONFIG_PATH

cat <<EOF >>$CTID_CONFIG_PATH
lxc.autodev: 1
lxc.hook.autodev: bash -c '$HOOK_SCRIPT'
EOF
echo -e "\e[1;33m \nFinished....Reboot ${CTID} LXC to apply the changes.\n \e[0m"

# In the Proxmox web shell run
# bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/frigate-support.sh)"
# Reboot the LXC to apply the changes