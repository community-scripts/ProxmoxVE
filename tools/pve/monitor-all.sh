#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

clear
cat <<"EOF"
    __  ___            _ __                ___    ____
   /  |/  /___  ____  (_) /_____  _____   /   |  / / /
  / /|_/ / __ \/ __ \/ / __/ __ \/ ___/  / /| | / / /
 / /  / / /_/ / / / / / /_/ /_/ / /     / ___ |/ / /
/_/  /_/\____/_/ /_/_/\__/\____/_/     /_/  |_/_/_/

EOF

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "monitor-all" "pve"

add() {
  echo -e "\n IMPORTANT: Tag-Based Monitoring Enabled"
  echo "Only VMs and containers with the tag 'mon-restart' will be automatically restarted by this service."
  echo
  echo "🔧 How to add the tag:"
  echo "  → Proxmox Web UI: Go to VM/CT → Options → Tags → Add 'mon-restart'"
  echo "  → CLI: qm set <vmid> -tags mon-restart"
  echo "         pct set <ctid> -tags mon-restart"
  echo

  while true; do
    read -p "This script will add Monitor All to Proxmox VE. Proceed (y/n)? " yn
    case $yn in
    [Yy]*) break ;;
    [Nn]*) exit ;;
    *) echo "Please answer yes or no." ;;
    esac
  done

  cat <<'EOF' >/usr/local/bin/ping-instances.sh
#!/usr/bin/env bash

# Read excluded instances from command line arguments
excluded_instances=("$@")
echo "Excluded instances: ${excluded_instances[@]}"

value_of() { sed -n "s/^$1:[[:space:]]*//p" <<<"$config" | head -n1; }

while true; do

  for instance in $(pct list | awk 'NR>1 {print $1}'; qm list | awk 'NR>1 {print $1}'); do
    # Skip excluded instances
    if [[ " ${excluded_instances[@]} " =~ " ${instance} " ]]; then
      echo "Skipping $instance because it is excluded"
      continue
    fi

    # Determine type and read the current config directly from Proxmox's pmxcfs.
    # Ignore snapshot sections, matching the current config shown by pct/qm config.
    if [ -r "/etc/pve/lxc/$instance.conf" ]; then
      type="ct"
      config_file="/etc/pve/lxc/$instance.conf"
    elif [ -r "/etc/pve/qemu-server/$instance.conf" ]; then
      type="vm"
      config_file="/etc/pve/qemu-server/$instance.conf"
    else
      echo "Skipping $instance because its config is no longer readable"
      continue
    fi
    config=$(sed '/^\[/,$d' "$config_file")

    # Both are booleans that Proxmox also writes as 0, so the value decides and
    # not the presence of the key.
    [ "$(value_of onboot)" = "1" ] && onboot="true" || onboot="false"
    [ "$(value_of template)" = "1" ] && template="true" || template="false"

    if [ "$onboot" != "true" ]; then
      echo "Skipping $instance because it is set not to boot"
      continue
    elif [ "$template" == "true" ]; then
      echo "Skipping $instance because it is a template"
      continue
    fi

    # Tags are semicolon separated, so match a whole entry instead of a
    # substring of a longer tag such as mon-restart-disabled.
    tags=";$(value_of tags | tr -d '[:space:]');"
    if [[ "$tags" != *";mon-restart;"* ]]; then
      echo "Skipping $instance because it does not have 'mon-restart' tag"
      continue
    fi

    # Responsiveness check and restart if needed
    if [ "$type" == "vm" ]; then
      if ! qm status "$instance" 2>/dev/null | grep -q "status: running"; then
        echo "$(date): VM $instance is not running, starting..."
        qm start "$instance" >/dev/null 2>&1
      elif qm guest cmd "$instance" ping >/dev/null 2>&1; then
        echo "VM $instance is responsive via guest agent"
      else
        echo "$(date): VM $instance is not responding to agent ping, restarting..."
        qm stop "$instance" >/dev/null 2>&1
        sleep 5
        qm start "$instance" >/dev/null 2>&1
      fi
    else
      if ! pct status "$instance" 2>/dev/null | grep -q "status: running"; then
        echo "$(date): CT $instance is not running, starting..."
        pct start "$instance" >/dev/null 2>&1
        continue
      fi
      # Not every container names its interface eth0.
      IP=$(pct exec "$instance" -- ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
      if [ -z "$IP" ] || ! ping -c 1 -W 2 "$IP" >/dev/null 2>&1; then
        echo "$(date): CT $instance is not responding, restarting..."
        pct stop "$instance" >/dev/null 2>&1
        sleep 5
        pct start "$instance" >/dev/null 2>&1
      else
        echo "CT $instance is responsive"
      fi
    fi
  done

  echo "$(date): Pausing for 5 minutes..."
  sleep 300

done >/var/log/ping-instances.log 2>&1
EOF

  touch /var/log/ping-instances.log
  chmod +x /usr/local/bin/ping-instances.sh

  # The service loops with its own five minute sleep, so the timer that earlier
  # versions installed could only ever start a unit that was already running.
  if [[ -f /etc/systemd/system/ping-instances.timer ]]; then
    systemctl disable -q --now ping-instances.timer 2>/dev/null || true
    rm -f /etc/systemd/system/ping-instances.timer
  fi

  cat <<EOF >/etc/systemd/system/ping-instances.service
[Unit]
Description=Ping instances every 5 minutes and restart if necessary
After=pve-cluster.service
Wants=pve-cluster.service

[Service]
Type=simple
# To exclude specific instances, pass IDs to ExecStart, e.g.:
# ExecStart=/usr/local/bin/ping-instances.sh 100 200
# Instances must also have the 'mon-restart' tag to be monitored

ExecStart=/usr/local/bin/ping-instances.sh
Restart=always
StandardOutput=file:/var/log/ping-instances.log
StandardError=file:/var/log/ping-instances.log

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable -q --now ping-instances.service
  clear
  echo -e "\n Monitor All installed."
  echo "📄 To view logs: cat /var/log/ping-instances.log"
  echo "⚙️  Make sure your VMs or containers have the 'mon-restart' tag to be monitored."
}

remove() {
  systemctl disable -q --now ping-instances.timer 2>/dev/null || true
  systemctl disable -q --now ping-instances.service
  rm -f /etc/systemd/system/ping-instances.service
  rm -f /etc/systemd/system/ping-instances.timer
  rm -f /usr/local/bin/ping-instances.sh
  rm -f /var/log/ping-instances.log
  echo "Monitor All removed from Proxmox VE"
}

OPTIONS=(Add "Add Monitor-All to Proxmox VE"
  Remove "Remove Monitor-All from Proxmox VE")

CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Monitor-All for Proxmox VE" --menu "Select an option:" 10 58 2 \
  "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

case $CHOICE in
"Add") add ;;
"Remove") remove ;;
*)
  echo "Exiting..."
  exit 0
  ;;
esac
