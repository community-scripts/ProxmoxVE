#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
#
# This script is installed locally by cron-update-lxcs.sh and executed
# by cron. It updates all LXC containers using their native package manager.

CONF_FILE="/etc/update-lxcs.conf"

echo -e "\n $(date)"

# Collect excluded containers from arguments
excluded_containers=("$@")

# Merge exclusions from config file if it exists
if [[ -f "$CONF_FILE" ]]; then
  conf_exclude=$(grep -oP '^\s*EXCLUDE\s*=\s*\K[0-9,]+' "$CONF_FILE" 2>/dev/null || true)
  IFS=',' read -ra conf_ids <<<"$conf_exclude"
  for id in "${conf_ids[@]}"; do
    id="${id// /}"
    [[ -n "$id" ]] && excluded_containers+=("$id")
  done
fi

function update_container() {
  local container=$1
  local name
  name=$(pct exec "$container" hostname 2>/dev/null || echo "unknown")
  local os
  os=$(pct config "$container" | awk '/^ostype/ {print $2}')
  echo -e "\n [Info] Updating $container : $name (os: $os)"
  case "$os" in
  alpine) pct exec "$container" -- ash -c "apk -U upgrade" ;;
  archlinux) pct exec "$container" -- bash -c "pacman -Syyu --noconfirm" ;;
  fedora | rocky | centos | alma) pct exec "$container" -- bash -c "dnf -y update && dnf -y upgrade" ;;
  ubuntu | debian | devuan) pct exec "$container" -- bash -c "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::='--force-confold' dist-upgrade -y; rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED" ;;
  opensuse) pct exec "$container" -- bash -c "zypper ref && zypper --non-interactive dup" ;;
  *) echo " [Warn] Unknown OS type '$os' for container $container, skipping" ;;
  esac
}

for container in $(pct list | awk '{if(NR>1) print $1}'); do
  excluded=false
  for excluded_container in "${excluded_containers[@]}"; do
    if [ "$container" == "$excluded_container" ]; then
      excluded=true
      break
    fi
  done
  if [ "$excluded" == true ]; then
    echo -e "[Info] Skipping $container"
    sleep 1
  else
    status=$(pct status "$container")
    if pct config "$container" 2>/dev/null | grep -q "^template:"; then
      echo -e "[Info] Skipping template $container"
      continue
    fi
    if [ "$status" == "status: stopped" ]; then
      echo -e "[Info] Starting $container"
      pct start "$container"
      sleep 5
      update_container "$container" || echo " [Error] Update failed for $container"
      echo -e "[Info] Shutting down $container"
      pct shutdown "$container" --timeout 60 &
    elif [ "$status" == "status: running" ]; then
      update_container "$container" || echo " [Error] Update failed for $container"
    fi
  fi
done
wait
