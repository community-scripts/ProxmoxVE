#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
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

while true; do

  for instance in $(pct list | awk 'NR>1 {print $1}'; qm list | awk 'NR>1 {print $1}'); do
    # Skip excluded instances
    if [[ " ${excluded_instances[@]} " =~ " ${instance} " ]]; then
      echo "Skipping $instance because it is excluded"
      continue
    fi

    # Determine type and set config command
    if pct status $instance >/dev/null 2>&1; then
      type="ct"
      config_cmd="pct config"
    else
      type="vm"
      config_cmd="qm config"
    fi

    # Skip templates and onboot-disabled
    onboot=$($config_cmd $instance | grep -q "onboot: 0" || ( ! $config_cmd $instance | grep -q "onboot" ) && echo "true" || echo "false")
    template=$($config_cmd $instance | grep -q "^template:" && echo "true" || echo "false")

    if [ "$onboot" == "true" ]; then
      echo "Skipping $instance because it is set not to boot"
      continue
    elif [ "$template" == "true" ]; then
      echo "Skipping $instance because it is a template"
      continue
    fi

    # Check for mon-restart tag
    has_tag=$($config_cmd $instance | grep -q "tags:.*mon-restart" && echo "true" || echo "false")
    if [ "$has_tag" != "true" ]; then
      echo "Skipping $instance because it does not have 'mon-restart' tag"
      continue
    fi

    # Responsiveness check and restart if needed
    if [ "$type" == "vm" ]; then
      # Check if guest agent responds
      if qm guest cmd $instance ping >/dev/null 2>&1; then
        echo "VM $instance is responsive via guest agent"
      else
        echo "$(date): VM $instance is not responding to agent ping, restarting..."
        if qm status $instance | grep -q "status: running"; then
          qm stop $instance >/dev/null 2>&1
          sleep 5
        fi
        qm start $instance >/dev/null 2>&1
      fi
    else
      # Container: get IP and ping
      IP=$(pct exec $instance ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)
      if ! ping -c 1 $IP >/dev/null 2>&1; then
        echo "$(date): CT $instance is not responding, restarting..."
        pct stop $instance >/dev/null 2>&1
        sleep 5
        pct start $instance >/dev/null 2>&1
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

  cat <<EOF >/etc/systemd/system/ping-instances.timer
[Unit]
Description=Delay ping-instances.service by 5 minutes

[Timer]
OnBootSec=300
OnUnitActiveSec=300

[Install]
WantedBy=timers.target
EOF

  cat <<EOF >/etc/systemd/system/ping-instances.service
[Unit]
Description=Ping instances every 5 minutes and restart if necessary
After=ping-instances.timer
Requires=ping-instances.timer

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
  systemctl enable -q --now ping-instances.timer
  systemctl enable -q --now ping-instances.service
  clear
  echo -e "\n Monitor All installed."
  echo "📄 To view logs: cat /var/log/ping-instances.log"
  echo "⚙️  Make sure your VMs or containers have the 'mon-restart' tag to be monitored."
}

remove() {
  systemctl disable -q --now ping-instances.timer
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
*) echo "Exiting..."; exit 0 ;;
esac
