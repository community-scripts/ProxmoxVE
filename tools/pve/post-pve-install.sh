#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteckster | MickLesk (CanbiZ)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

header_info() {
  clear
  cat <<"EOF"
    ____ _    ________   ____             __     ____           __        ____
   / __ \ |  / / ____/  / __ \____  _____/ /_   /  _/___  _____/ /_____ _/ / /
  / /_/ / | / / __/    / /_/ / __ \/ ___/ __/   / // __ \/ ___/ __/ __ `/ / /
 / ____/| |/ / /___   / ____/ /_/ (__  ) /_   _/ // / / (__  ) /_/ /_/ / / /
/_/     |___/_____/  /_/    \____/____/\__/  /___/_/ /_/____/\__/\__,_/_/_/

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

get_pve_version() {
  local pve_ver
  pve_ver="$(pveversion | awk -F'/' '{print $2}' | awk -F'-' '{print $1}')"
  echo "$pve_ver"
}

get_pve_major_minor() {
  local ver="$1"
  local major minor
  IFS='.' read -r major minor _ <<<"$ver"
  echo "$major $minor"
}

component_exists_in_sources() {
  local component="$1"
  grep -h -E "^[^#]*Components:[^#]*\b${component}\b" /etc/apt/sources.list.d/*.sources 2>/dev/null | grep -q .
}

main() {
  header_info
  echo -e "\nThis script will Perform Post Install Routines.\n"
  while true; do
    read -p "Start the Proxmox VE Post Install Script (y/n)? " yn
    case $yn in
    [Yy]*) break ;;
    [Nn]*)
      clear
      exit
      ;;
    *) echo "Please answer yes or no." ;;
    esac
  done

  local PVE_VERSION PVE_MAJOR PVE_MINOR
  PVE_VERSION="$(get_pve_version)"
  read -r PVE_MAJOR PVE_MINOR <<<"$(get_pve_major_minor "$PVE_VERSION")"

  if [[ "$PVE_MAJOR" == "8" ]]; then
    if ((PVE_MINOR < 0 || PVE_MINOR > 9)); then
      msg_error "Unsupported Proxmox 8 version"
      exit 1
    fi
    start_routines_8
  elif [[ "$PVE_MAJOR" == "9" ]]; then
    if ((PVE_MINOR != 0)); then
      msg_error "Only Proxmox 9.0 is currently supported"
      exit 1
    fi
    start_routines_9
  else
    msg_error "Unsupported Proxmox VE major version: $PVE_MAJOR"
    echo -e "Supported: 8.0–8.9.x and 9.0"
    exit 1
  fi
}

start_routines_8() {
  header_info

  # === Bookworm/8.x: .list-Files ===
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SOURCES" --menu "The package manager will use the correct sources to update and install packages on your Proxmox VE server.\n \nCorrect Proxmox VE sources?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Correcting Proxmox VE Sources"
    cat <<EOF >/etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main contrib
deb http://deb.debian.org/debian bookworm-updates main contrib
deb http://security.debian.org/debian-security bookworm-security main contrib
EOF
    echo 'APT::Get::Update::SourceListWarnings::NonFreeFirmware "false";' >/etc/apt/apt.conf.d/no-bookworm-firmware.conf
    msg_ok "Corrected Proxmox VE Sources"
    ;;
  no) msg_error "Selected no to Correcting Proxmox VE Sources" ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PVE-ENTERPRISE" --menu "The 'pve-enterprise' repository is only available to users who have purchased a Proxmox VE subscription.\n \nDisable 'pve-enterprise' repository?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Disabling 'pve-enterprise' repository"
    cat <<EOF >/etc/apt/sources.list.d/pve-enterprise.list
# deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise
EOF
    msg_ok "Disabled 'pve-enterprise' repository"
    ;;
  no) msg_error "Selected no to Disabling 'pve-enterprise' repository" ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PVE-NO-SUBSCRIPTION" --menu "The 'pve-no-subscription' repository provides access to all of the open-source components of Proxmox VE.\n \nEnable 'pve-no-subscription' repository?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Enabling 'pve-no-subscription' repository"
    cat <<EOF >/etc/apt/sources.list.d/pve-install-repo.list
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF
    msg_ok "Enabled 'pve-no-subscription' repository"
    ;;
  no) msg_error "Selected no to Enabling 'pve-no-subscription' repository" ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "CEPH PACKAGE REPOSITORIES" --menu "The 'Ceph Package Repositories' provides access to both the 'no-subscription' and 'enterprise' repositories (initially disabled).\n \nCorrect 'ceph package sources?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Correcting 'ceph package repositories'"
    cat <<EOF >/etc/apt/sources.list.d/ceph.list
# deb https://enterprise.proxmox.com/debian/ceph-quincy bookworm enterprise
# deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription
# deb https://enterprise.proxmox.com/debian/ceph-reef bookworm enterprise
# deb http://download.proxmox.com/debian/ceph-reef bookworm no-subscription
EOF
    msg_ok "Corrected 'ceph package repositories'"
    ;;
  no) msg_error "Selected no to Correcting 'ceph package repositories'" ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PVETEST" --menu "The 'pvetest' repository can give advanced users access to new features and updates before they are officially released.\n \nAdd (Disabled) 'pvetest' repository?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Adding 'pvetest' repository and set disabled"
    cat <<EOF >/etc/apt/sources.list.d/pvetest-for-beta.list
# deb http://download.proxmox.com/debian/pve bookworm pvetest
EOF
    msg_ok "Added 'pvetest' repository"
    ;;
  no) msg_error "Selected no to Adding 'pvetest' repository" ;;
  esac

  post_routines_common
}

start_routines_9() {
  header_info

  # check if deb822 Sources (*.sources) exist
  if find /etc/apt/sources.list.d/ -maxdepth 1 -name '*.sources' | grep -q .; then
    whiptail --backtitle "Proxmox VE Helper Scripts" --title "Deb822 sources detected" \
      --msgbox "Modern deb822 sources (*.sources) already exist.\n\nNo changes to sources format required.\n\nYou may still have legacy sources.list or .list files, which you can disable in the next step." 12 65 || true
  else
    check_and_disable_legacy_sources() {
      local LEGACY_COUNT=0
      local listfile="/etc/apt/sources.list"

      # Check sources.list
      if [[ -f "$listfile" ]] && grep -qE '^\s*deb ' "$listfile"; then
        ((++LEGACY_COUNT))
      fi

      # Check .list files
      local list_files
      list_files=$(find /etc/apt/sources.list.d/ -type f -name "*.list" 2>/dev/null)
      if [[ -n "$list_files" ]]; then
        LEGACY_COUNT=$((LEGACY_COUNT + $(echo "$list_files" | wc -l)))
      fi

      if ((LEGACY_COUNT > 0)); then
        # Show summary to user
        local MSG="Legacy APT sources found:\n"
        [[ -f "$listfile" ]] && MSG+=" - /etc/apt/sources.list\n"
        [[ -n "$list_files" ]] && MSG+="$(echo "$list_files" | sed 's|^| - |')\n"
        MSG+="\nDo you want to disable (comment out/rename) all legacy sources and use ONLY deb822 .sources format?\n\nRecommended for Proxmox VE 9."

        whiptail --backtitle "Proxmox VE Helper Scripts" --title "Disable legacy sources?" \
          --yesno "$MSG" 18 80
        if [[ $? -eq 0 ]]; then
          # Backup and disable sources.list
          if [[ -f "$listfile" ]] && grep -qE '^\s*deb ' "$listfile"; then
            cp "$listfile" "$listfile.bak"
            sed -i '/^\s*deb /s/^/# Disabled by Proxmox Helper Script /' "$listfile"
            msg_ok "Disabled entries in sources.list (backup: sources.list.bak)"
          fi
          # Rename all .list files to .list.bak
          if [[ -n "$list_files" ]]; then
            while IFS= read -r f; do
              mv "$f" "$f.bak"
            done <<<"$list_files"
            msg_ok "Renamed legacy .list files to .bak"
          fi
        else
          msg_error "Kept legacy sources as-is (may cause APT warnings)"
        fi
      fi
    }

    check_and_disable_legacy_sources
    # === Trixie/9.x: deb822 .sources ===
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SOURCES" --menu \
      "The package manager will use the correct sources to update and install packages on your Proxmox VE 9 server.\n\nMigrate to deb822 sources format?" 14 58 2 \
      "yes" " " \
      "no" " " 3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      msg_info "Correcting Proxmox VE Sources (deb822)"
      # remove all existing .list files
      rm -f /etc/apt/sources.list.d/*.list
      # remove bookworm and proxmox entries from sources.list
      sed -i '/proxmox/d;/bookworm/d' /etc/apt/sources.list || true
      # Create new deb822 sources
      cat >/etc/apt/sources.list.d/debian.sources <<EOF
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie
Components: main contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie-updates
Components: main contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
      msg_ok "Corrected Proxmox VE 9 (Trixie) Sources"
      ;;
    no) msg_error "Selected no to Correcting Proxmox VE Sources" ;;
    esac
  fi

  # ---- PVE-ENTERPRISE ----
  if component_exists_in_sources "pve-enterprise"; then
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" \
      --title "PVE-ENTERPRISE" \
      --menu "'pve-enterprise' repository already exists.\n\nWhat do you want to do?" 14 58 2 \
      "keep" "Keep as is" \
      "disable" "Comment out (disable) this repo" \
      "delete" "Delete this repo file" \
      3>&2 2>&1 1>&3)
    case $CHOICE in
    keep)
      msg_ok "Kept 'pve-enterprise' repository"
      ;;
    disable)
      msg_info "Disabling 'pve-enterprise' repository"
      # Use Enabled: false instead of commenting to avoid malformed entry
      for file in /etc/apt/sources.list.d/*.sources; do
        if grep -q "Components:.*pve-enterprise" "$file"; then
          if grep -q "^Enabled:" "$file"; then
            sed -i 's/^Enabled:.*/Enabled: false/' "$file"
          else
            echo "Enabled: false" >>"$file"
          fi
        fi
      done
      msg_ok "Disabled 'pve-enterprise' repository"
      ;;
    delete)
      msg_info "Deleting 'pve-enterprise' repository file"
      for file in /etc/apt/sources.list.d/*.sources; do
        if grep -q "Components:.*pve-enterprise" "$file"; then
          rm -f "$file"
        fi
      done
      msg_ok "Deleted 'pve-enterprise' repository file"
      ;;
    esac
  else
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" \
      --title "PVE-ENTERPRISE" \
      --menu "The 'pve-enterprise' repository is only available to users who have purchased a Proxmox VE subscription.\n\nAdd 'pve-enterprise' repository (deb822)?" 14 58 2 \
      "no" " " \
      "yes" " " \
      --default-item "no" \
      3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      msg_info "Adding 'pve-enterprise' repository (deb822)"
      cat >/etc/apt/sources.list.d/pve-enterprise.sources <<EOF
Types: deb
URIs: https://enterprise.proxmox.com/debian/pve
Suites: trixie
Components: pve-enterprise
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
      msg_ok "Added 'pve-enterprise' repository"
      ;;
    no) msg_error "Selected no to Adding 'pve-enterprise' repository" ;;
    esac
  fi

  # ---- CEPH-ENTERPRISE ----
  if grep -q "enterprise.proxmox.com.*ceph" /etc/apt/sources.list.d/*.sources 2>/dev/null; then
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" \
      --title "CEPH-ENTERPRISE" \
      --menu "'ceph enterprise' repository already exists.\n\nWhat do you want to do?" 14 58 2 \
      "keep" "Keep as is" \
      "disable" "Comment out (disable) this repo" \
      "delete" "Delete this repo file" \
      3>&2 2>&1 1>&3)
    case $CHOICE in
    keep)
      msg_ok "Kept 'ceph enterprise' repository"
      ;;
    disable)
      msg_info "Disabling 'ceph enterprise' repository"
      # Use Enabled: false instead of commenting to avoid malformed entry
      for file in /etc/apt/sources.list.d/*.sources; do
        if grep -q "enterprise.proxmox.com.*ceph" "$file"; then
          if grep -q "^Enabled:" "$file"; then
            sed -i 's/^Enabled:.*/Enabled: false/' "$file"
          else
            echo "Enabled: false" >>"$file"
          fi
        fi
      done
      msg_ok "Disabled 'ceph enterprise' repository"
      ;;
    delete)
      msg_info "Deleting 'ceph enterprise' repository file"
      for file in /etc/apt/sources.list.d/*.sources; do
        if grep -q "enterprise.proxmox.com.*ceph" "$file"; then
          rm -f "$file"
        fi
      done
      msg_ok "Deleted 'ceph enterprise' repository file"
      ;;
    esac
  fi

  # ---- PVE-NO-SUBSCRIPTION ----
  REPO_FILE=""
  REPO_ACTIVE=0
  REPO_COMMENTED=0
  for file in /etc/apt/sources.list.d/*.sources; do
    if grep -q "Components:.*pve-no-subscription" "$file"; then
      REPO_FILE="$file"
      if grep -E '^[^#]*Components:.*pve-no-subscription' "$file" >/dev/null; then
        REPO_ACTIVE=1
      elif grep -E '^#.*Components:.*pve-no-subscription' "$file" >/dev/null; then
        REPO_COMMENTED=1
      fi
      break
    fi
  done

  if [[ "$REPO_ACTIVE" -eq 1 ]]; then
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" \
      --title "PVE-NO-SUBSCRIPTION" \
      --menu "'pve-no-subscription' repository is currently ENABLED.\n\nWhat do you want to do?" 14 58 3 \
      "keep" "Keep as is" \
      "disable" "Comment out (disable)" \
      "delete" "Delete repo file" \
      3>&2 2>&1 1>&3)
    case $CHOICE in
    keep)
      msg_ok "Kept 'pve-no-subscription' repository"
      ;;
    disable)
      msg_info "Disabling (commenting) 'pve-no-subscription' repository"
      sed -i '/^\s*Types:/,/^$/s/^\([^#].*\)$/# \1/' "$REPO_FILE"
      msg_ok "Disabled 'pve-no-subscription' repository"
      ;;
    delete)
      msg_info "Deleting 'pve-no-subscription' repository file"
      rm -f "$REPO_FILE"
      msg_ok "Deleted 'pve-no-subscription' repository file"
      ;;
    esac

  elif [[ "$REPO_COMMENTED" -eq 1 ]]; then
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" \
      --title "PVE-NO-SUBSCRIPTION" \
      --menu "'pve-no-subscription' repository is currently DISABLED (commented out).\n\nWhat do you want to do?" 14 58 3 \
      "enable" "Uncomment (enable)" \
      "keep" "Keep disabled" \
      "delete" "Delete repo file" \
      3>&2 2>&1 1>&3)
    case $CHOICE in
    enable)
      msg_info "Enabling (uncommenting) 'pve-no-subscription' repository"
      sed -i '/^#\s*Types:/,/^$/s/^#\s*//' "$REPO_FILE"
      msg_ok "Enabled 'pve-no-subscription' repository"
      ;;
    keep)
      msg_ok "Kept 'pve-no-subscription' repository disabled"
      ;;
    delete)
      msg_info "Deleting 'pve-no-subscription' repository file"
      rm -f "$REPO_FILE"
      msg_ok "Deleted 'pve-no-subscription' repository file"
      ;;
    esac
  else
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PVE-NO-SUBSCRIPTION" \
      --menu "The 'pve-no-subscription' repository provides access to all of the open-source components of Proxmox VE.\n\nAdd 'pve-no-subscription' repository (deb822)?" 14 58 2 \
      "yes" " " \
      "no" " " 3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      msg_info "Adding 'pve-no-subscription' repository (deb822)"
      cat >/etc/apt/sources.list.d/proxmox.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
      msg_ok "Added 'pve-no-subscription' repository"
      ;;
    no) msg_error "Selected no to Adding 'pve-no-subscription' repository" ;;
    esac
  fi

  # ---- CEPH ----
  if component_exists_in_sources "no-subscription"; then
    msg_ok "'ceph' package repository (no-subscription) already exists (skipped)"
  else
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "CEPH PACKAGE REPOSITORIES" \
      --menu "The 'Ceph Package Repositories' provides access to both the 'no-subscription' and 'enterprise' repositories (deb822).\n\nAdd 'ceph package sources?" 14 58 2 \
      "yes" " " \
      "no" " " 3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      msg_info "Adding 'ceph package repositories' (deb822)"
      cat >/etc/apt/sources.list.d/ceph.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/ceph-squid
Suites: trixie
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
      msg_ok "Added 'ceph package repositories'"
      ;;
    no)
      msg_error "Selected no to Adding 'ceph package repositories'"
      # Use Enabled: false for .sources files, comment for .list files
      for file in /etc/apt/sources.list.d/*.sources; do
        if grep -q "enterprise.proxmox.com.*ceph" "$file" 2>/dev/null; then
          if grep -q "^Enabled:" "$file"; then
            sed -i 's/^Enabled:.*/Enabled: false/' "$file"
          else
            echo "Enabled: false" >>"$file"
          fi
        fi
      done
      find /etc/apt/sources.list.d/ -type f -name "*.list" \
        -exec sed -i '/enterprise.proxmox.com.*ceph/s/^/# /' {} \;
      msg_ok "Disabled all Ceph Enterprise repositories"
      ;;
    esac
  fi

  # ---- PVETEST ----
  if component_exists_in_sources "pve-test"; then
    msg_ok "'pve-test' repository already exists (skipped)"
  else
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PVETEST" \
      --menu "The 'pve-test' repository can give advanced users access to new features and updates before they are officially released.\n\nAdd (Disabled) 'pvetest' repository (deb822)?" 14 58 2 \
      "yes" " " \
      "no" " " 3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      msg_info "Adding 'pve-test' repository (deb822, disabled)"
      cat >/etc/apt/sources.list.d/pve-test.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-test
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
Enabled: false
EOF
      msg_ok "Added 'pve-test' repository"
      ;;
    no) msg_error "Selected no to Adding 'pvetest' repository" ;;
    esac
  fi

  post_routines_common
}

post_routines_common() {
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUBSCRIPTION NAG" --menu "This will disable the nag message reminding you to purchase a subscription every time you log in to the web interface.\n \nDisable subscription nag?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "Support Subscriptions" "Supporting the software's development team is essential. Check their official website's Support Subscriptions for pricing. Without their dedicated work, we wouldn't have this exceptional software." 10 58
    msg_info "Disabling subscription nag"
    # Create external script, this is needed because DPkg::Post-Invoke is fidly with quote interpretation
    mkdir -p /usr/local/bin
    cat >/usr/local/bin/pve-remove-nag.sh <<'EOF'
#!/bin/sh
WEB_JS=/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
if [ -s "$WEB_JS" ] && ! grep -q NoMoreNagging "$WEB_JS"; then
    echo "Patching Web UI nag..."
    sed -i -e "/data\.status/ s/!//" -e "/data\.status/ s/active/NoMoreNagging/" "$WEB_JS"
fi

MOBILE_TPL=/usr/share/pve-yew-mobile-gui/index.html.tpl
MARKER="<!-- MANAGED BLOCK FOR MOBILE NAG -->"
if [ -f "$MOBILE_TPL" ] && ! grep -q "$MARKER" "$MOBILE_TPL"; then
    echo "Patching Mobile UI nag..."
    printf "%s\n" \
      "$MARKER" \
      "<script>" \
      "  function removeSubscriptionElements() {" \
      "    // --- Remove subscription dialogs ---" \
      "    const dialogs = document.querySelectorAll('dialog.pwt-outer-dialog');" \
      "    dialogs.forEach(dialog => {" \
      "      const text = (dialog.textContent || '').toLowerCase();" \
      "      if (text.includes('subscription')) {" \
      "        dialog.remove();" \
      "        console.log('Removed subscription dialog');" \
      "      }" \
      "    });" \
      "" \
      "    // --- Remove subscription cards, but keep Reboot/Shutdown/Console ---" \
      "    const cards = document.querySelectorAll('.pwt-card.pwt-p-2.pwt-d-flex.pwt-interactive.pwt-justify-content-center');" \
      "    cards.forEach(card => {" \
      "      const text = (card.textContent || '').toLowerCase();" \
      "      const hasButton = card.querySelector('button');" \
      "      if (!hasButton && text.includes('subscription')) {" \
      "        card.remove();" \
      "        console.log('Removed subscription card');" \
      "      }" \
      "    });" \
      "  }" \
      "" \
      "  const observer = new MutationObserver(removeSubscriptionElements);" \
      "  observer.observe(document.body, { childList: true, subtree: true });" \
      "  removeSubscriptionElements();" \
      "  setInterval(removeSubscriptionElements, 300);" \
      "  setTimeout(() => {observer.disconnect();}, 10000);" \
      "</script>" \
      "" >> "$MOBILE_TPL"
fi
EOF
    chmod 755 /usr/local/bin/pve-remove-nag.sh

    cat >/etc/apt/apt.conf.d/no-nag-script <<'EOF'
DPkg::Post-Invoke { "/usr/local/bin/pve-remove-nag.sh"; };
EOF
    chmod 644 /etc/apt/apt.conf.d/no-nag-script

    msg_ok "Disabled subscription nag (Delete browser cache)"
    ;;
  no)
    whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "Support Subscriptions" "Supporting the software's development team is essential. Check their official website's Support Subscriptions for pricing. Without their dedicated work, we wouldn't have this exceptional software." 10 58
    msg_error "Selected no to Disabling subscription nag"
    rm /etc/apt/apt.conf.d/no-nag-script 2>/dev/null
    ;;
  esac
  apt --reinstall install proxmox-widget-toolkit &>/dev/null || msg_error "Widget toolkit reinstall failed"
  if ! systemctl is-active --quiet pve-ha-lrm; then
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "HIGH AVAILABILITY" --menu "Enable high availability?" 10 58 2 \
      "yes" " " \
      "no" " " 3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      msg_info "Enabling high availability"
      systemctl enable -q --now pve-ha-lrm
      systemctl enable -q --now pve-ha-crm
      systemctl enable -q --now corosync
      msg_ok "Enabled high availability"
      ;;
    no) msg_error "Selected no to Enabling high availability" ;;
    esac
  fi

  if systemctl is-active --quiet pve-ha-lrm; then
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "HIGH AVAILABILITY" --menu "If you plan to utilize a single node instead of a clustered environment, you can disable unnecessary high availability (HA) services, thus reclaiming system resources.\n\nIf HA becomes necessary at a later stage, the services can be re-enabled.\n\nDisable high availability?" 18 58 2 \
      "yes" " " \
      "no" " " 3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      msg_info "Disabling high availability"
      systemctl disable -q --now pve-ha-lrm
      systemctl disable -q --now pve-ha-crm
      msg_ok "Disabled high availability"
      CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "COROSYNC" --menu "Disable Corosync for a Proxmox VE Cluster?" 10 58 2 \
        "yes" " " \
        "no" " " 3>&2 2>&1 1>&3)
      case $CHOICE in
      yes)
        msg_info "Disabling Corosync"
        systemctl disable -q --now corosync
        msg_ok "Disabled Corosync"
        ;;
      no) msg_error "Selected no to Disabling Corosync" ;;
      esac
      ;;
    no) msg_error "Selected no to Disabling high availability" ;;
    esac
  fi

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "UPDATE" --menu "\nUpdate Proxmox VE now?" 11 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Updating Proxmox VE (Patience)"
    apt update &>/dev/null || msg_error "apt update failed"
    apt -y dist-upgrade &>/dev/null || msg_error "apt dist-upgrade failed"
    msg_ok "Updated Proxmox VE"
    ;;
  no) msg_error "Selected no to Updating Proxmox VE" ;;
  esac

  # Final message for all hosts in cluster and browser cache
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "Post-Install Reminder" --msgbox \
    "IMPORTANT:

If you have multiple Proxmox VE hosts in a cluster, please make sure to run this script on every node individually.

After completing these steps, it is strongly recommended to REBOOT your node.

After the upgrade or post-install routines, always clear your browser cache or perform a hard reload (Ctrl+Shift+R) before using the Proxmox VE Web UI to avoid UI display issues.
" 20 80

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "REBOOT" --menu "\nReboot Proxmox VE now? (recommended)" 11 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Rebooting Proxmox VE"
    sleep 2
    msg_ok "Completed Post Install Routines"
    reboot
    ;;
  no)
    msg_error "Selected no to Rebooting Proxmox VE (Reboot recommended)"
    msg_ok "Completed Post Install Routines"
    ;;
  esac
}

main
