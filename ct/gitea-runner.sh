#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

# Copyright (c) 2021-2026 community-scripts ORG
# Author: community-scripts
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gitea.com/gitea/runner

APP="Gitea-Runner"
var_tags="${var_tags:-ci;git}"
var_cpu="${var_cpu:-2}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
# Needed for container-based workflow execution (Docker/Podman inside LXC)
var_nesting="${var_nesting:-1}"
var_keyctl="${var_keyctl:-1}"

if [[ -z "${var_os:-}" ]] && command -v pveversion >/dev/null 2>&1; then
  var_os=$(msg_menu "Choose the container OS" \
    "debian" "Debian 13" \
    "alpine" "Alpine 3.24 (smaller)")
fi

var_os="${var_os:-debian}"
if [[ "${var_os:-}" == "alpine" ]]; then
  var_ram="${var_ram:-1024}"
  var_disk="${var_disk:-4}"
  var_version="${var_version:-3.24}"
else
  var_ram="${var_ram:-2048}"
  var_disk="${var_disk:-8}"
  var_version="${var_version:-13}"
fi

export var_gitea_url="${var_gitea_url:-}"
export var_gitea_token="${var_gitea_token:-}"

header_info "$APP"
variables
color
catch_errors

update_deb_based() {
  if [[ ! -f /usr/local/bin/gitea-runner ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  ensure_dependencies git

  RELEASE=$(curl -fsSL https://gitea.com/api/v1/repos/gitea/runner/releases/latest | jq -r .tag_name | sed 's/^v//')
  if [[ "${RELEASE}" == "$(cat ~/.gitea-runner 2>/dev/null)" ]]; then
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
    exit
  fi

  msg_info "Stopping Service"
  systemctl stop gitea-runner
  msg_ok "Stopped Service"

  msg_info "Updating ${APP} to v${RELEASE}"
  $STD curl -fsSL -o /usr/local/bin/gitea-runner "https://gitea.com/gitea/runner/releases/download/v${RELEASE}/gitea-runner-${RELEASE}-linux-$(arch_resolve)"
  chmod +x /usr/local/bin/gitea-runner
  ln -sf /usr/local/bin/gitea-runner /usr/local/bin/act_runner
  echo "${RELEASE}" >~/.gitea-runner
  msg_ok "Updated ${APP} to v${RELEASE}"

  msg_info "Starting Service"
  systemctl start gitea-runner
  msg_ok "Started Service"
  msg_ok "Updated successfully!"
}

update_alpine() {
  if [[ ! -f /usr/local/bin/gitea-runner ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  msg_info "Updating Alpine Packages"
  $STD apk -U upgrade
  $STD apk add --no-cache git
  msg_ok "Updated Alpine Packages"

  RELEASE=$(curl -fsSL https://gitea.com/api/v1/repos/gitea/runner/releases/latest | jq -r .tag_name | sed 's/^v//')
  if [[ "${RELEASE}" == "$(cat ~/.gitea-runner 2>/dev/null)" ]]; then
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
    exit
  fi

  msg_info "Stopping Service"
  $STD rc-service gitea-runner stop
  msg_ok "Stopped Service"

  msg_info "Updating ${APP} to v${RELEASE}"
  $STD curl -fsSL -o /usr/local/bin/gitea-runner "https://gitea.com/gitea/runner/releases/download/v${RELEASE}/gitea-runner-${RELEASE}-linux-$(arch_resolve)"
  chmod +x /usr/local/bin/gitea-runner
  ln -sf /usr/local/bin/gitea-runner /usr/local/bin/act_runner
  echo "${RELEASE}" >~/.gitea-runner
  msg_ok "Updated ${APP} to v${RELEASE}"

  msg_info "Starting Service"
  $STD rc-service gitea-runner start
  msg_ok "Started Service"
  msg_ok "Updated successfully!"
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  run_os_update
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}To register the runner, execute the following command in the container console:${CL}"
if [[ -n "${var_gitea_url:-}" ]]; then
  echo -e "${TAB}${BGN}gitea-runner -c /etc/gitea-runner/config.yaml register --instance ${var_gitea_url} --token <REGISTRATION_TOKEN>${CL}"
else
  echo -e "${TAB}${BGN}gitea-runner -c /etc/gitea-runner/config.yaml register --instance <GITEA_INSTANCE_URL> --token <REGISTRATION_TOKEN>${CL}"
fi
echo -e "${INFO}${YW}After registering, start the runner daemon:${CL}"
if [[ "${var_os:-}" == "alpine" ]]; then
  echo -e "${TAB}${BGN}rc-service gitea-runner start${CL}"
else
  echo -e "${TAB}${BGN}systemctl start gitea-runner${CL}"
fi
echo -e "${INFO}${YW}Official registration documentation:${CL}"
echo -e "${GATEWAY}${BGN}https://docs.gitea.com/runner/registration/${CL}"
