#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

header_info() {
  clear
  cat <<"EOF"
    ____  ____  __  ___   ____             __     ____           __        ____
   / __ \/ __ \/  |/  /  / __ \____  _____/ /_   /  _/___  _____/ /_____ _/ / /
  / /_/ / / / / /|_/ /  / /_/ / __ \/ ___/ __/   / // __ \/ ___/ __/ __ `/ / /
 / ____/ /_/ / /  / /  / ____/ /_/ (__  ) /_   _/ // / / (__  ) /_/ /_/ / / /
/_/   /_____/_/  /_/  /_/    \____/____/\__/  /___/_/ /_/____/\__/\__,_/_/_/

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
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "post-pdm-install" "pve"

if ! dpkg -s proxmox-datacenter-manager >/dev/null 2>&1; then
  msg_error "This script is only intended for Proxmox Datacenter Manager"
  exit 232
fi

repo_state() {
  # $1 = component name (e.g. pdm-enterprise, pdm-no-subscription, pdm-test)
  local repo="$1"
  local file=""
  local state="missing"
  for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
    [[ -f "$f" ]] || continue
    if grep -q "$repo" "$f"; then
      file="$f"
      if [[ "$f" == *.sources ]]; then
        if grep -qiE '^Enabled:\s*(no|false)' "$f"; then
          state="disabled"
        else
          state="active"
        fi
      else
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
        sed -i 's/^Enabled:.*/Enabled: false/' "$file"
      else
        echo "Enabled: false" >>"$file"
      fi
    else
      sed -i 's/^Enabled:.*/Enabled: true/' "$file"
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
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PDM SOURCES" --menu \
    "This will set the correct Debian sources for Proxmox Datacenter Manager.\n\nCorrect sources?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Correcting Debian Sources"
    cat <<EOF >/etc/apt/sources.list.d/debian.sources
Types: deb
URIs: http://deb.debian.org/debian/
Suites: ${VERSION} ${VERSION}-updates
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security/
Suites: ${VERSION}-security
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
    rm -f /etc/apt/sources.list
    msg_ok "Corrected Debian Sources"
    ;;
  no) msg_error "Selected no to Correcting Debian Sources" ;;
  esac

  # ---- PDM-ENTERPRISE ----
  read -r state file <<<"$(repo_state pdm-enterprise)"
  case $state in
  active)
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PDM-ENTERPRISE" \
      --menu "'pdm-enterprise' repository is currently ENABLED.\n\nIt requires a subscription and will fail apt update without one.\n\nWhat do you want to do?" 16 58 3 \
      "disable" "Disable this repo" \
      "keep" "Keep as is" \
      "delete" "Delete repo file" \
      3>&2 2>&1 1>&3)
    case $CHOICE in
    keep) msg_ok "Kept 'pdm-enterprise' repository" ;;
    disable)
      msg_info "Disabling 'pdm-enterprise' repository"
      toggle_repo "$file" disable
      msg_ok "Disabled 'pdm-enterprise' repository"
      ;;
    delete)
      msg_info "Deleting 'pdm-enterprise' repository file"
      rm -f "$file"
      msg_ok "Deleted 'pdm-enterprise' repository file"
      ;;
    esac
    ;;
  disabled)
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PDM-ENTERPRISE" \
      --menu "'pdm-enterprise' repository is currently DISABLED.\n\nWhat do you want to do?" 14 58 3 \
      "keep" "Keep disabled" \
      "enable" "Enable (subscription required)" \
      "delete" "Delete repo file" \
      3>&2 2>&1 1>&3)
    case $CHOICE in
    enable)
      msg_info "Enabling 'pdm-enterprise' repository"
      toggle_repo "$file" enable
      msg_ok "Enabled 'pdm-enterprise' repository"
      ;;
    keep) msg_ok "Kept 'pdm-enterprise' repository disabled" ;;
    delete)
      msg_info "Deleting 'pdm-enterprise' repository file"
      rm -f "$file"
      msg_ok "Deleted 'pdm-enterprise' repository file"
      ;;
    esac
    ;;
  missing)
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PDM-ENTERPRISE" \
      --menu "Add 'pdm-enterprise' repository?\n\nOnly for subscription customers." 14 58 2 \
      "no" " " \
      "yes" " " \
      --default-item "no" \
      3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      msg_info "Adding 'pdm-enterprise' repository"
      cat <<EOF >/etc/apt/sources.list.d/pdm-enterprise.sources
Types: deb
URIs: https://enterprise.proxmox.com/debian/pdm
Suites: ${VERSION}
Components: pdm-enterprise
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
      msg_ok "Added 'pdm-enterprise' repository"
      ;;
    no) msg_error "Selected no to Adding 'pdm-enterprise' repository" ;;
    esac
    ;;
  esac

  # ---- PDM-NO-SUBSCRIPTION ----
  read -r state file <<<"$(repo_state pdm-no-subscription)"
  case $state in
  active)
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PDM-NO-SUBSCRIPTION" \
      --menu "'pdm-no-subscription' repository is currently ENABLED.\n\nWhat do you want to do?" 14 58 3 \
      "keep" "Keep as is" \
      "disable" "Disable this repo" \
      "delete" "Delete repo file" \
      3>&2 2>&1 1>&3)
    case $CHOICE in
    keep) msg_ok "Kept 'pdm-no-subscription' repository" ;;
    disable)
      msg_info "Disabling 'pdm-no-subscription' repository"
      toggle_repo "$file" disable
      msg_ok "Disabled 'pdm-no-subscription' repository"
      ;;
    delete)
      msg_info "Deleting 'pdm-no-subscription' repository file"
      rm -f "$file"
      msg_ok "Deleted 'pdm-no-subscription' repository file"
      ;;
    esac
    ;;
  disabled)
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PDM-NO-SUBSCRIPTION" \
      --menu "'pdm-no-subscription' repository is currently DISABLED.\n\nWhat do you want to do?" 14 58 3 \
      "enable" "Enable (recommended)" \
      "keep" "Keep disabled" \
      "delete" "Delete repo file" \
      3>&2 2>&1 1>&3)
    case $CHOICE in
    enable)
      msg_info "Enabling 'pdm-no-subscription' repository"
      toggle_repo "$file" enable
      msg_ok "Enabled 'pdm-no-subscription' repository"
      ;;
    keep) msg_ok "Kept 'pdm-no-subscription' repository disabled" ;;
    delete)
      msg_info "Deleting 'pdm-no-subscription' repository file"
      rm -f "$file"
      msg_ok "Deleted 'pdm-no-subscription' repository file"
      ;;
    esac
    ;;
  missing)
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PDM-NO-SUBSCRIPTION" \
      --menu "The 'pdm-no-subscription' repository provides access to all open-source components of Proxmox Datacenter Manager.\n\nAdd 'pdm-no-subscription' repository?" 14 58 2 \
      "yes" " " \
      "no" " " \
      3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      msg_info "Adding 'pdm-no-subscription' repository"
      cat <<EOF >/etc/apt/sources.list.d/proxmox.sources
Types: deb
URIs: http://download.proxmox.com/debian/pdm
Suites: ${VERSION}
Components: pdm-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
      msg_ok "Added 'pdm-no-subscription' repository"
      ;;
    no) msg_error "Selected no to Adding 'pdm-no-subscription' repository" ;;
    esac
    ;;
  esac

  # ---- PDM-TEST ----
  read -r state file <<<"$(repo_state pdm-test)"
  case $state in
  active) msg_ok "'pdm-test' repository already active (skipped)" ;;
  disabled) msg_ok "'pdm-test' repository already disabled (skipped)" ;;
  missing)
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PDM-TEST" \
      --menu "The 'pdm-test' repository is used by developers to test new features.\n\nAdd (disabled) 'pdm-test' repository?" 14 58 2 \
      "yes" " " \
      "no" " " 3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      msg_info "Adding 'pdm-test' repository (disabled)"
      cat <<EOF >/etc/apt/sources.list.d/pdm-test.sources
Types: deb
URIs: http://download.proxmox.com/debian/pdm
Suites: ${VERSION}
Components: pdm-test
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
Enabled: false
EOF
      msg_ok "Added 'pdm-test' repository"
      ;;
    no) msg_error "Selected no to Adding 'pdm-test' repository" ;;
    esac
    ;;
  esac

  # ---- SUBSCRIPTION NAG ----
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUBSCRIPTION NAG" --menu \
    "Disable subscription nag in the PDM UI?" 14 58 2 "yes" " " "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "Support Subscriptions" \
      "Supporting the software's development team is essential.\nPlease consider buying a subscription." 10 58
    msg_info "Disabling subscription nag"
    mkdir -p /usr/local/bin
    cat <<'EOF' >/usr/local/bin/pdm-remove-nag.sh
#!/bin/sh
# PDM ships its web UI as a Yew/WASM app in a single JS bundle - there is no
# proxmoxlib.js and no HTML template to patch, so the dialog is confirmed at
# runtime instead. The nag gates the update refresh: its on_close callback is
# what sends RefreshAll, so it must be close()d, never removed from the DOM.
# Re-applied by the apt hook after every package update.
BUNDLE=/usr/share/javascript/proxmox-datacenter-manager/js/pdm-ui_bundle.js
if [ -s "$BUNDLE" ] && ! grep -q PDM_NO_MORE_NAGGING "$BUNDLE"; then
    echo "Patching PDM subscription nag..."
    cat >>"$BUNDLE" <<'JS'

// PDM_NO_MORE_NAGGING
(function () {
  var MARK = 'data-pdm-nag';
  var dismiss = function (d) {
    if (d.getAttribute(MARK)) return;
    d.setAttribute(MARK, '1');
    var tries = 12;
    var tick = function () {
      if (!d.isConnected || tries-- <= 0) return;
      try { d.close(); } catch (e) {}
      setTimeout(tick, 120);
    };
    requestAnimationFrame(tick);
  };
  var scan = function () {
    document.querySelectorAll('dialog.pwt-outer-dialog').forEach(function (d) {
      if ((d.textContent || '').indexOf('pdm.proxmox.com') !== -1) dismiss(d);
    });
  };
  var start = function () {
    scan();
    new MutationObserver(scan).observe(document.body, { childList: true, subtree: true });
  };
  if (document.body) { start(); } else {
    document.addEventListener('DOMContentLoaded', start);
  }
})();
JS
fi
EOF
    chmod 755 /usr/local/bin/pdm-remove-nag.sh
    /usr/local/bin/pdm-remove-nag.sh >/dev/null 2>&1

    cat <<'EOF' >/etc/apt/apt.conf.d/no-nag-script
DPkg::Post-Invoke { "/usr/local/bin/pdm-remove-nag.sh"; };
EOF
    chmod 644 /etc/apt/apt.conf.d/no-nag-script
    msg_ok "Disabled subscription nag (clear browser cache!)"
    ;;
  no)
    msg_error "Selected no to Disabling subscription nag"
    rm -f /etc/apt/apt.conf.d/no-nag-script /usr/local/bin/pdm-remove-nag.sh 2>/dev/null
    apt --reinstall install proxmox-datacenter-manager-ui &>/dev/null || msg_error "UI reinstall failed"
    ;;
  esac

  # ---- UPDATE ----
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "UPDATE" --menu \
    "Update Proxmox Datacenter Manager now?" 11 58 2 "yes" " " "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Updating Proxmox Datacenter Manager (Patience)"
    apt update &>/dev/null || msg_error "apt update failed"
    apt -y dist-upgrade &>/dev/null || msg_error "apt dist-upgrade failed"
    msg_ok "Updated Proxmox Datacenter Manager"
    ;;
  no) msg_error "Selected no to updating Proxmox Datacenter Manager" ;;
  esac

  # ---- REMINDER ----
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "Post-Install Reminder" --msgbox \
    "IMPORTANT:

Proxmox Datacenter Manager is still under active development. Do not rely on it as the only management path to your nodes.

After completing these steps, it is strongly recommended to REBOOT.

After the upgrade or post-install routines, always clear your browser cache or perform a hard reload (Ctrl+Shift+R) before using the PDM Web UI to avoid UI display issues." 20 80

  # ---- REBOOT ----
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "REBOOT" --menu \
    "Reboot Proxmox Datacenter Manager now? (recommended)" 11 58 2 "yes" " " "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Rebooting Proxmox Datacenter Manager"
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
  read -rp "Start the Proxmox Datacenter Manager Post Install Script (y/n)? " yn
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
