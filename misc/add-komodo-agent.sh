#!/usr/bin/env bash

function header_info {
clear
cat <<"EOF"

EOF
}

clear
header_info
APP="LXC Komodo Agent Installer"
hostname=$(hostname)

msg_info() {
  echo -ne "➤ $1..."
}

msg_ok() {
  echo -e "✔ $1"
}

msg_error() {
  echo -e "✖ $1"
}

# Activer le mode debug si demandé
if [[ "$1" == "--debug" ]]; then
  set -x
fi

while true; do
  read -p "This will install ${APP} on ${hostname}. Proceed? (y/n): " yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*)
  msg_error "Installation cancelled."
  exit
  ;;
  *) msg_error "Please answer yes or no." ;;
  esac
done

# Vérifier la version de Proxmox
if ! pveversion | grep -Eq "pve-manager/8\.[0-9]+"; then
  msg_error "This version of Proxmox Virtual Environment is not supported"
  msg_error "⚠ Requires Proxmox Virtual Environment Version 8.0 or later."
  exit
fi

# Récupération des VM LXC
msg_info "Fetching LXC container list"
vmid_list=$(pct list 2>/dev/null | awk 'NR>1 {print $1}')
if [[ -z "$vmid_list" ]]; then
  msg_error "No LXC containers found."
  exit 1
fi
msg_ok "LXC container list retrieved"

# Installation de l'agent sur chaque conteneur
for vmid in $vmid_list; do
  msg_info "Installing Komodo Agent on LXC $vmid"
  
  # Exécuter la commande et capturer l'erreur si elle échoue
  OUTPUT=$(pct exec "$vmid" -- bash -c "curl -sSL https://raw.githubusercontent.com/moghtech/komodo/main/scripts/setup-periphery.py | python3" 2>&1)
  EXIT_CODE=$?
  
  if [ $EXIT_CODE -eq 0 ]; then
    msg_ok "Komodo Agent installed on LXC $vmid"
  else
    msg_error "Failed to install Komodo Agent on LXC $vmid"
    echo "Error log for LXC $vmid:"
    echo "$OUTPUT"
  fi
done

echo -e "\n${APP} installation completed successfully!"
