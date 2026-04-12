#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Sander Koenders (sanderkoenders)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.borgbackup.org/

APP="Alpine-BorgBackup-Server"
var_tags="${var_tags:-alpine;backup}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-20}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.23}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info

  if [[ ! -f /usr/bin/borg ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  CHOICE=$(msg_menu "BorgBackup Server Update Options" \
    "1" "Update BorgBackup Server" \
    "2" "Reset SSH Access" \
    "3" "Enable password authentication for backup user (not recommended, use SSH key instead)" \
    "4" "Disable password authentication for backup user (recommended for security, use SSH key)")

  case $CHOICE in
  1)
    msg_info "Updating $APP LXC"
    $STD apk -U upgrade
    msg_ok "Updated $APP LXC successfully!"
    ;;
  2)
    if [[ "${PHS_SILENT:-0}" == "1" ]]; then
      msg_warn "Reset SSH Public key requires interactive mode, skipping."
      exit
    fi

    msg_info "Setting up SSH Public Key for backup user"

    msg_info "Please paste your SSH public key (e.g., ssh-rsa AAAAB3... user@host): \n"
    read -p "Key: " SSH_PUBLIC_KEY
    echo

    if [[ -z "$SSH_PUBLIC_KEY" ]]; then
      msg_error "No SSH public key provided!"
      exit 1
    fi

    if [[ ! "$SSH_PUBLIC_KEY" =~ ^(ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-) ]]; then
      msg_error "Invalid SSH public key format!"
      exit 1
    fi

    msg_info "Setting up SSH access"
    mkdir -p /home/backup/.ssh
    echo "$SSH_PUBLIC_KEY" >/home/backup/.ssh/authorized_keys

    chown -R backup:backup /home/backup/.ssh
    chmod 700 /home/backup/.ssh
    chmod 600 /home/backup/.ssh/authorized_keys

    msg_ok "SSH access configured for backup user"
    ;;
  3)
    if [[ "${PHS_SILENT:-0}" == "1" ]]; then
      msg_warn "Enabling password authentication requires interactive mode, skipping."
      exit
    fi

    msg_info "Enabling password authentication for backup user"
    msg_warn "Password authentication is less secure than using SSH keys. Consider using SSH keys instead."
    passwd backup
    sed -i 's/^#*\s*PasswordAuthentication\s\+\(yes\|no\)/PasswordAuthentication yes/' /etc/ssh/sshd_config
    rc-service sshd restart
    msg_ok "Password authentication enabled for backup user"
    ;;
  4)
    msg_info "Disabling password authentication for backup user"
    sed -i 's/^#*\s*PasswordAuthentication\s\+\(yes\|no\)/PasswordAuthentication no/' /etc/ssh/sshd_config
    rc-service sshd restart
    msg_ok "Password authentication disabled for backup user"
    ;;
  esac

  exit 0
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Connection information:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}ssh backup@${IP}${CL}"
echo -e "${TAB}${VERIFYPW}${YW}To set SSH key, run this script with the 'update' option and select option 2${CL}"
