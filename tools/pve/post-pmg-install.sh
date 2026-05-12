#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: thost96 (thost96)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

header_info() {
  clear
  cat <<"EOF"
    ____  __  _________   ____             __     ____           __        ____
   / __ \/  |/  / ____/  / __ \____  _____/ /_   /  _/___  _____/ /_____ _/ / /
  / /_/ / /|_/ / / __   / /_/ / __ \/ ___/ __/   / // __ \/ ___/ __/ __ `/ / /
 / ____/ /  / / /_/ /  / ____/ /_/ (__  ) /_   _/ // / / (__  ) /_/ /_/ / / /
/_/   /_/  /_/\____/  /_/    \____/____/\__/  /___/_/ /_/____/\__/\__,_/_/_/

EOF
}

RD=$(echo "\033[01;31m")
YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"

set -euo pipefail
shopt -s inherit_errexit nullglob

msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

msg_error() {
  local msg="$1"
  echo -e "${BFR} ${CROSS} ${RD}${msg}${CL}"
}

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "post-pmg-install" "pve"

if ! dpkg -s proxmox-mailgateway-container >/dev/null 2>&1 &&
  ! dpkg -s proxmox-mailgateway >/dev/null 2>&1; then
  msg_error "This script is only intended for Proxmox Mail Gateway"
  exit 232
fi

repo_state() {
  # $1 = repo name (e.g. pmg-enterprise, pmg-no-subscription, pmgtest)
  local repo="$1"
  local file=""
  local state="missing"
  for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
    [[ -f "$f" ]] || continue
    if grep -q "$repo" "$f"; then
      file="$f"
      if [[ "$f" == *.sources ]]; then
        # deb822 format: check Enabled field
        if grep -qiE '^Enabled:\s*no' "$f"; then
          state="disabled"
        else
          state="active"
        fi
      else
        # legacy format
        if grep -qE "^[^#].*${repo}" "$f"; then
          state="active"
        elif grep -qE "^#.*${repo}" "$f"; then
          state="disabled"
        fi
      fi
      break
    fi
  done
  echo "$state $file"
}

toggle_repo() {
  # $1 = file, $2 = action (enable|disable)
  local file="$1" action="$2"
  if [[ "$file" == *.sources ]]; then
    if [[ "$action" == "disable" ]]; then
      if grep -qiE '^Enabled:' "$file"; then
        sed -i 's/^Enabled:.*/Enabled: no/' "$file"
      else
        echo "Enabled: no" >>"$file"
      fi
    else
      sed -i 's/^Enabled:.*/Enabled: yes/' "$file"
    fi
  else
    if [[ "$action" == "disable" ]]; then
      sed -i '/^[^#]/s/^/# /' "$file"
    else
      sed -i 's/^# *//' "$file"
    fi
  fi
}

start_routines() {
  header_info
  VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"

  # ---- SOURCES ----
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PMG SOURCES" --menu \
    "This will set the correct Debian sources for Proxmox Mail Gateway.\n\nCorrect sources?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Correcting Debian Sources"
    cat <<EOF >/etc/apt/sources.list.d/debian.sources
Types: deb
URIs: http://deb.debian.org/debian
Suites: ${VERSION} ${VERSION}-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: ${VERSION}-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
    rm -f /etc/apt/sources.list
    msg_ok "Corrected Debian Sources"
    ;;
  no) msg_error "Selected no to Correcting Debian Sources" ;;
  esac

  # ---- PMG-ENTERPRISE ----
  read -r state file <<<"$(repo_state pmg-enterprise)"
  case $state in
  active)
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PMG-ENTERPRISE" \
      --menu "'pmg-enterprise' repository is currently ENABLED.\n\nWhat do you want to do?" 14 58 3 \
      "keep" "Keep as is" \
      "disable" "Comment out (disable)" \
      "delete" "Delete repo file" \
      3>&2 2>&1 1>&3)
    case $CHOICE in
    keep) msg_ok "Kept 'pmg-enterprise' repository" ;;
    disable)
      msg_info "Disabling 'pmg-enterprise' repository"
      toggle_repo "$file" disable
      msg_ok "Disabled 'pmg-enterprise' repository"
      ;;
    delete)
      msg_info "Deleting 'pmg-enterprise' repository file"
      rm -f "$file"
      msg_ok "Deleted 'pmg-enterprise' repository file"
      ;;
    esac
    ;;
  disabled)
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PMG-ENTERPRISE" \
      --menu "'pmg-enterprise' repository is currently DISABLED.\n\nWhat do you want to do?" 14 58 3 \
      "enable" "Uncomment (enable)" \
      "keep" "Keep disabled" \
      "delete" "Delete repo file" \
      3>&2 2>&1 1>&3)
    case $CHOICE in
    enable)
      msg_info "Enabling 'pmg-enterprise' repository"
      toggle_repo "$file" enable
      msg_ok "Enabled 'pmg-enterprise' repository"
      ;;
    keep) msg_ok "Kept 'pmg-enterprise' repository disabled" ;;
    delete)
      msg_info "Deleting 'pmg-enterprise' repository file"
      rm -f "$file"
      msg_ok "Deleted 'pmg-enterprise' repository file"
      ;;
    esac
    ;;
  missing)
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PMG-ENTERPRISE" \
      --menu "Add 'pmg-enterprise' repository?\n\nOnly for subscription customers." 14 58 2 \
      "no" " " \
      "yes" " " \
      --default-item "no" \
      3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      msg_info "Adding 'pmg-enterprise' repository"
      cat >/etc/apt/sources.list.d/pmg-enterprise.sources <<EOF
Types: deb
URIs: https://enterprise.proxmox.com/debian/pmg
Suites: ${VERSION}
Components: pmg-enterprise
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
      msg_ok "Added 'pmg-enterprise' repository"
      ;;
    no) msg_error "Selected no to Adding 'pmg-enterprise' repository" ;;
    esac
    ;;
  esac

  # ---- PMG-NO-SUBSCRIPTION ----
  read -r state file <<<"$(repo_state pmg-no-subscription)"
  case $state in
  active)
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PMG-NO-SUBSCRIPTION" \
      --menu "'pmg-no-subscription' repository is currently ENABLED.\n\nWhat do you want to do?" 14 58 3 \
      "keep" "Keep as is" \
      "disable" "Comment out (disable)" \
      "delete" "Delete repo file" \
      3>&2 2>&1 1>&3)
    case $CHOICE in
    keep) msg_ok "Kept 'pmg-no-subscription' repository" ;;
    disable)
      msg_info "Disabling 'pmg-no-subscription' repository"
      toggle_repo "$file" disable
      msg_ok "Disabled 'pmg-no-subscription' repository"
      ;;
    delete)
      msg_info "Deleting 'pmg-no-subscription' repository file"
      rm -f "$file"
      msg_ok "Deleted 'pmg-no-subscription' repository file"
      ;;
    esac
    ;;
  disabled)
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PMG-NO-SUBSCRIPTION" \
      --menu "'pmg-no-subscription' repository is currently DISABLED.\n\nWhat do you want to do?" 14 58 3 \
      "enable" "Uncomment (enable)" \
      "keep" "Keep disabled" \
      "delete" "Delete repo file" \
      3>&2 2>&1 1>&3)
    case $CHOICE in
    enable)
      msg_info "Enabling 'pmg-no-subscription' repository"
      toggle_repo "$file" enable
      msg_ok "Enabled 'pmg-no-subscription' repository"
      ;;
    keep) msg_ok "Kept 'pmg-no-subscription' repository disabled" ;;
    delete)
      msg_info "Deleting 'pmg-no-subscription' repository file"
      rm -f "$file"
      msg_ok "Deleted 'pmg-no-subscription' repository file"
      ;;
    esac
    ;;
  missing)
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PMG-NO-SUBSCRIPTION" \
      --menu "Add 'pmg-no-subscription' repository?" 14 58 2 \
      "yes" " " \
      "no" " " \
      3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      msg_info "Adding 'pmg-no-subscription' repository"
      cat >/etc/apt/sources.list.d/pmg-no-subscription.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pmg
Suites: ${VERSION}
Components: pmg-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
      msg_ok "Added 'pmg-no-subscription' repository"
      ;;
    no) msg_error "Selected no to Adding 'pmg-no-subscription' repository" ;;
    esac
    ;;
  esac

  # ---- PMG-TEST ----
  read -r state file <<<"$(repo_state pmgtest)"
  case $state in
  active) msg_ok "'pmgtest' repository already active (skipped)" ;;
  disabled) msg_ok "'pmgtest' repository already disabled (skipped)" ;;
  missing)
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PMG TEST" \
      --menu "The 'pmgtest' repository can give advanced users access to new features early.\n\nAdd (disabled) 'pmgtest' repository?" 14 58 2 \
      "yes" " " \
      "no" " " 3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      msg_info "Adding 'pmgtest' repository (disabled)"
      cat >/etc/apt/sources.list.d/pmgtest.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pmg
Suites: ${VERSION}
Components: pmgtest
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
Enabled: no
EOF
      msg_ok "Added 'pmgtest' repository"
      ;;
    no) msg_error "Selected no to Adding 'pmgtest' repository" ;;
    esac
    ;;
  esac

  # ---- SUBSCRIPTION NAG ----
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUBSCRIPTION NAG" --menu \
    "Disable subscription nag in PMG UI?" 14 58 2 "yes" " " "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "Support Subscriptions" \
      "Supporting the software's development team is essential.\nPlease consider buying a subscription." 10 58
    msg_info "Disabling subscription nag"
    cat >/etc/apt/apt.conf.d/no-nag-script <<'EOF'
DPkg::Post-Invoke { "if [ -s /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js ] && ! grep -q -F 'NoMoreNagging' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; then sed -i '/data\.status/{s/\!//;s/active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; fi"; };
EOF

    cat >/etc/apt/apt.conf.d/no-nag-script-pmgmanagerlib-mobile <<'EOF'
DPkg::Post-Invoke { "if [ -s /usr/share/javascript/pmg-gui/js/pmgmanagerlib-mobile.js ] && ! grep -q -F 'NoMoreNagging' /usr/share/javascript/pmg-gui/js/pmgmanagerlib-mobile.js; then sed -i '/data\.status/{s/\!//;s/active/NoMoreNagging/}' /usr/share/javascript/pmg-gui/js/pmgmanagerlib-mobile.js; fi"; };
EOF
    msg_ok "Disabled subscription nag (clear browser cache!)"
    ;;
  no)
    msg_error "Selected no to Disabling subscription nag"
    rm -f /etc/apt/apt.conf.d/no-nag-script 2>/dev/null
    ;;
  esac
  apt --reinstall install proxmox-widget-toolkit pmg-gui &>/dev/null || msg_error "Widget toolkit reinstall failed"

  # ---- UPDATE ----
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "UPDATE" --menu \
    "Update Proxmox Mail Gateway now?" 11 58 2 "yes" " " "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Updating Proxmox Mail Gateway (Patience)"
    apt update &>/dev/null || msg_error "apt update failed"
    apt -y dist-upgrade &>/dev/null || msg_error "apt dist-upgrade failed"
    msg_ok "Updated Proxmox Mail Gateway"
    ;;
  no) msg_error "Selected no to updating Proxmox Mail Gateway" ;;
  esac

  # ---- REMINDER ----
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "Post-Install Reminder" --msgbox \
    "IMPORTANT:

Please run this script on every PMG node individually if you have multiple nodes.

After completing these steps, it is strongly recommended to REBOOT your node.

After the upgrade or post-install routines, always clear your browser cache or perform a hard reload (Ctrl+Shift+R) before using the PMG Web UI to avoid UI display issues." 20 80

  # ---- REBOOT ----
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "REBOOT" --menu \
    "Reboot Proxmox Mail Gateway now? (recommended)" 11 58 2 "yes" " " "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Rebooting Proxmox Mail Gateway"
    sleep 2
    msg_ok "Completed Post Install Routines"
    reboot
    ;;
  no)
    msg_error "Selected no to reboot (Reboot recommended)"
    msg_ok "Completed Post Install Routines"
    ;;
  esac
}

header_info
echo -e "\nThis script will Perform Post Install Routines.\n"
while true; do
  read -rp "Start the Proxmox Mail Gateway Post Install Script (y/n)? " yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*)
    clear
    exit
    ;;
  *) echo "Please answer yes or no." ;;
  esac
done

start_routines
