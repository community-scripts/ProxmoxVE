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
while true; do
  read -p "This script will add Monitor All to Proxmox VE. Proceed(y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) exit ;;
  *) echo "Please answer yes or no." ;;
  esac
done

echo '#!/usr/bin/env bash
# Read excluded instances from command line arguments
excluded_instances=("$@")
echo "Excluded instances: ${excluded_instances[@]}"

while true; do

  for instance in $(pct list | awk '\''{if(NR>1) print $1}'\''; qm list | awk '\''{if(NR>1) print $1}'\''); do
    # Skip excluded instances
    if [[ " ${excluded_instances[@]} " =~ " ${instance} " ]]; then
      echo "Skipping $instance because it is excluded"
      continue
    fi

    # Determine the type of the instance (container or virtual machine)
    if pct status $instance >/dev/null 2>&1; then
      # It is a container
      config_cmd="pct config"
      IP=$(pct exec $instance ip a s dev eth0 | awk '\''/inet / {print $2}'\'' | cut -d/ -f1)
    else
      # It is a virtual machine
      config_cmd="qm config"
      IP=$(qm guest cmd $instance network-get-interfaces | egrep -o "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -E "192\.|10\." | head -n 1)
    fi

    # Skip instances based on onboot and templates
    onboot=$($config_cmd $instance | grep -q "onboot: 0" || ( ! $config_cmd $instance | grep -q "onboot" ) && echo "true" || echo "false")
    template=$($config_cmd $instance | grep template | grep -q "template:" && echo "true" || echo "false")

    if [ "$onboot" == "true" ]; then
      echo "Skipping $instance because it is set not to boot"
      continue
    elif [ "$template" == "true" ]; then
      echo "Skipping $instance because it is a template"
      continue
    fi

    # Ping the instance
    if ! ping -c 1 $IP >/dev/null 2>&1; then
      # If the instance can not be pinged, stop and start it
      if pct status $instance >/dev/null 2>&1; then
        # It is a container
        echo "$(date): CT $instance is not responding, restarting..."
        pct stop $instance >/dev/null 2>&1
        sleep 5
        pct start $instance >/dev/null 2>&1
      else
        # It is a virtual machine
        if qm status $instance | grep -q "status: running"; then
          echo "$(date): VM $instance is not responding, restarting..."
          qm stop $instance >/dev/null 2>&1
          sleep 5
        else
          echo "$(date): VM $instance is not running, starting..."
        fi
        qm start $instance >/dev/null 2>&1
      fi
    fi
  done

  # Wait for 5 minutes. (Edit to your needs)
  echo "$(date): Pausing for 5 minutes..."
  sleep 300
done >/var/log/ping-instances.log 2>&1' >/usr/local/bin/ping-instances.sh
touch /var/log/ping-instances.log
# Change file permissions to executable
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

# Create ping-instances.service
cat <<EOF >/etc/systemd/system/ping-instances.service
[Unit]
Description=Ping instances every 5 minutes and restarts if necessary
After=ping-instances.timer
Requires=ping-instances.timer
[Service]
Type=simple
# To specify which CT/VM should be excluded, add the CT/VM ID at the end of the line where ExecStart=/usr/local/bin/ping-instances.sh is specified.
# For example: ExecStart=/usr/local/bin/ping-instances.sh 100 102
# Virtual machines without the QEMU guest agent installed must be excluded.

ExecStart=/usr/local/bin/ping-instances.sh
Restart=always
StandardOutput=file:/var/log/ping-instances.log
StandardError=file:/var/log/ping-instances.log

[Install]
WantedBy=multi-user.target
EOF

# Reload daemon, enable and start ping-instances.service
systemctl daemon-reload
systemctl enable -q --now ping-instances.timer
systemctl enable -q --now ping-instances.service
clear
echo -e "\n To view Monitor All logs: cat /var/log/ping-instances.log"
}

remove() {
  systemctl disable -q --now ping-instances.timer
  systemctl disable -q --now ping-instances.service
  rm /etc/systemd/system/ping-instances.service /etc/systemd/system/ping-instances.timer /usr/local/bin/ping-instances.sh /var/log/ping-instances.log
  echo "Removed Monitor All from Proxmox VE"
}

# Define options for the whiptail menu
OPTIONS=(Add "Add Monitor-All to Proxmox VE" \
         Remove "Remove Monitor-All from Proxmox VE")

# Show the whiptail menu and save the user's choice
CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Monitor-All for Proxmox VE" --menu "Select an option:" 10 58 2 \
          "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

# Check the user's choice and perform the corresponding action
case $CHOICE in
  "Add")
    add
    ;;
  "Remove")
    remove
    ;;
  *)
    echo "Exiting..."
    exit 0
    ;;
esac
