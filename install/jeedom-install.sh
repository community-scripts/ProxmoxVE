#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Mips2648
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://jeedom.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies"
$STD apt-get install -y \
  lsb-release \
  git
msg_ok "Dependencies installed"

DEFAULT_BRANCH="master"
REPO_URL="https://github.com/jeedom/core.git"

echo
while true; do
  read -rp "${TAB3}Enter branch to use (master, beta, alpha...) (Default: ${DEFAULT_BRANCH}): " BRANCH
  BRANCH="${BRANCH:-$DEFAULT_BRANCH}"

  if git ls-remote --heads "$REPO_URL" "refs/heads/$BRANCH" | grep -q .; then
    break
  else
    msg_error "Branch '$BRANCH' does not exist on remote. Please try again."
  fi
done

msg_info "Downloading Jeedom installation script"
cd /tmp
wget -q https://raw.githubusercontent.com/jeedom/core/"${BRANCH}"/install/install.sh
chmod +x install.sh
msg_ok "Installation script downloaded"

msg_info "Install Jeedom main dependencies, please wait"
$STD ./install.sh -v "$BRANCH" -s 2
msg_ok "Installed Jeedom main dependencies"

msg_info "Install Database"
$STD ./install.sh -v "$BRANCH" -s 3
msg_ok "Database installed"

msg_info "Install Apache"
$STD ./install.sh -v "$BRANCH" -s 4
msg_ok "Apache installed"

msg_info "Install PHP and dependencies"
$STD ./install.sh -v "$BRANCH" -s 5
msg_ok "PHP installed"

msg_info "Download Jeedom core"
$STD ./install.sh -v "$BRANCH" -s 6
msg_ok "Download done"

msg_info "Database customisation"
$STD ./install.sh -v "$BRANCH" -s 7
msg_ok "Database customisation done"

msg_info "Jeedom customisation"
$STD ./install.sh -v "$BRANCH" -s 8
msg_ok "Jeedom customisation done"

msg_info "Configuring Jeedom"
$STD ./install.sh -v "$BRANCH" -s 9
msg_ok "Jeedom configured"

msg_info "Installing Jeedom"
$STD ./install.sh -v "$BRANCH" -s 10
msg_ok "Jeedom installed"

msg_info "Post installation"
$STD ./install.sh -v "$BRANCH" -s 11
msg_ok "Post installation done"

msg_info "Check installation"
$STD ./install.sh -v "$BRANCH" -s 12
msg_ok "Installation checked, everything is successfuly installed. A reboot is recommended."

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /tmp/install.sh
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
