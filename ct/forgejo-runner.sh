#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Simon Friedrich (lengschder97)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://forgejo.org/

APP="Forgejo-Runner"
var_tags="${var_tags:-ci}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
var_nesting="${var_nesting:-1}"
var_keyctl="${var_keyctl:-1}"

# App-specific variables (not in build.func whitelist)
# Export so they survive lxc-attach into the container
export var_forgejo_instance="${var_forgejo_instance:-}"
export var_forgejo_runner_token="${var_forgejo_runner_token:-}"
export var_runner_labels="${var_runner_labels:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /usr/local/bin/forgejo-runner ]]; then
    msg_error "No ${APP} installation found!"
    exit 1
  fi

  RELEASE=$(curl -fsSL https://data.forgejo.org/api/v1/repos/forgejo/runner/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+' | sed 's/^v//')
  if [[ "${RELEASE}" == "$(cat ~/.forgejo-runner 2>/dev/null)" ]]; then
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
    exit
  fi

  msg_info "Stopping Services"
  systemctl stop forgejo-runner
  msg_ok "Stopped Services"

  msg_info "Updating Forgejo Runner to v${RELEASE}"
  curl -fsSL "https://code.forgejo.org/forgejo/runner/releases/download/v${RELEASE}/forgejo-runner-${RELEASE}-linux-amd64" -o /usr/local/bin/forgejo-runner
  chmod +x /usr/local/bin/forgejo-runner
  echo "${RELEASE}" >~/.forgejo-runner
  msg_ok "Updated Forgejo Runner"

  msg_info "Starting Services"
  systemctl start forgejo-runner
  msg_ok "Started Services"
  msg_ok "Updated successfully!"
  exit
}

# Fail early if running unattended without required values
# mode is only set when the user explicitly passes it (automating);
# bare "bash -c $(curl ...)" leaves mode empty and shows the whiptail menu
if [[ -n "${mode:-}" ]]; then
  if [[ -z "${var_forgejo_instance:-}" ]]; then
    msg_error "var_forgejo_instance is required for unattended installs."
    exit 1
  fi
  if [[ -z "${var_forgejo_runner_token:-}" ]]; then
    msg_error "var_forgejo_runner_token is required for unattended installs."
    exit 1
  fi
fi

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
