#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/woodpecker-ci/woodpecker

APP="Woodpecker-CI"
var_tags="${var_tags:-ci;devops;git}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

export var_forge="${var_forge:-}"
export var_forge_url="${var_forge_url:-}"
export var_forge_client="${var_forge_client:-}"
export var_forge_secret="${var_forge_secret:-}"
export var_forge_admin="${var_forge_admin:-}"

if [[ -n "${var_forge}" ]]; then
  if [[ ! "${var_forge}" =~ ^(forgejo|gitea|github|gitlab|bitbucket)$ ]] ||
    [[ -z "${var_forge_client}" || -z "${var_forge_secret}" || -z "${var_forge_admin}" ]] ||
    [[ "${var_forge}" =~ ^(forgejo|gitea)$ && -z "${var_forge_url}" ]]; then
    msg_error "var_forge must be forgejo, gitea, github, gitlab or bitbucket and needs var_forge_client, var_forge_secret and var_forge_admin (Forgejo and Gitea also var_forge_url)"
    exit 1
  fi
fi

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/woodpecker ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "woodpecker-server" "woodpecker-ci/woodpecker"; then
    msg_info "Stopping Woodpecker CI"
    systemctl stop woodpecker-agent woodpecker-server
    msg_ok "Stopped Woodpecker CI"

    fetch_and_deploy_gh_release "woodpecker-server" "woodpecker-ci/woodpecker" "prebuild" "latest" "/opt/woodpecker" "woodpecker-server_linux_$(arch_resolve).tar.gz"
    fetch_and_deploy_gh_release "woodpecker-agent" "woodpecker-ci/woodpecker" "prebuild" "latest" "/opt/woodpecker" "woodpecker-agent_linux_$(arch_resolve).tar.gz"
    fetch_and_deploy_gh_release "plugin-git" "woodpecker-ci/plugin-git" "singlefile" "latest" "/usr/local/bin" "linux-$(arch_resolve)_plugin-git"

    msg_info "Starting Woodpecker CI"
    systemctl start woodpecker-server woodpecker-agent
    msg_ok "Started Woodpecker CI"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
if [[ -z "${var_forge}" ]]; then
  echo -e "${INFO}${YW}Woodpecker CI signs in through a forge. Create an OAuth app on Forgejo, Gitea, GitHub, GitLab or Bitbucket with the callback URL:${CL}"
  echo -e "${TAB}${BGN}http://${IP}:8000/authorize${CL}"
  echo -e "${INFO}${YW}Fill in the forge block and WOODPECKER_ADMIN in /opt/woodpecker_data/server.env, then start Woodpecker CI:${CL}"
  echo -e "${TAB}${BGN}systemctl enable --now woodpecker-server woodpecker-agent${CL}"
fi
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8000${CL}"
