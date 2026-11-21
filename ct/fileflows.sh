#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: kkroboth
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://fileflows.com/

APP="FileFlows"
var_tags="${var_tags:-media;automation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
var_gpu="${var_gpu:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/fileflows ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # Since 26.10 the REST API is off by default and answers 404, so compare the
  # installed build with the version FileFlows' own updater asks for.
  current_version=$(grep -h -m1 -oP '"FileFlows\.(Server|Agent)/\K[0-9.]+' /opt/fileflows/Server/FileFlows.Server.deps.json /opt/fileflows/Agent/FileFlows.Agent.deps.json 2>/dev/null | head -n1 || true)
  latest_version=$(curl -fsSL --max-time 20 "https://fileflows.com/auto-update/latest-version?platform=linux" 2>/dev/null | tr -d '[:space:]' || true)

  if [[ "${FORCE_UPDATE:-}" == "1" ]]; then
    msg_warn "FORCE_UPDATE=1: updating without the version check"
  elif [[ ! "$latest_version" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
    msg_warn "Could not get the latest ${APP} version from fileflows.com"
    if ! prompt_confirm "${TAB3}Update without the version check?" "n" 60; then
      msg_warn "Update skipped. Run 'FORCE_UPDATE=1 update' to update without the version check."
      exit
    fi
  elif [[ -n "$current_version" && "$(printf '%s\n' "$current_version" "$latest_version" | sort -V | tail -n1)" == "$current_version" ]]; then
    msg_ok "No update required. ${APP} is already at v${current_version}"
    exit
  else
    msg_ok "Update available: ${current_version:-unknown} -> ${latest_version}"
  fi

  msg_info "Stopping Service"
  systemctl --all stop 'fileflows*'
  msg_ok "Stopped Service"

  msg_info "Creating Backup"
  ls /opt/*.tar.gz &>/dev/null && rm -f /opt/*.tar.gz
  backup_filename="/opt/${APP}_backup_$(date +%F).tar.gz"
  tar -czf "$backup_filename" -C /opt/fileflows Data
  msg_ok "Backup Created"

  msg_info "Ensuring ASP.NET Core Runtime"
  if [[ "$(arch_resolve)" == "arm64" ]]; then
    if [[ ! -x /usr/lib/dotnet10/dotnet ]]; then
      curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
      $STD bash /tmp/dotnet-install.sh --channel 10.0 --runtime aspnetcore --install-dir /usr/lib/dotnet10
      ln -sf /usr/lib/dotnet10/dotnet /usr/bin/dotnet
      rm -f /tmp/dotnet-install.sh
    fi
  elif ! is_package_installed "aspnetcore-runtime-10.0"; then
    $STD apt remove -y aspnetcore-runtime-8.0 aspnetcore-runtime-9.0 2>/dev/null || true
    setup_deb822_repo \
      "microsoft" \
      "https://packages.microsoft.com/keys/microsoft-2025.asc" \
      "https://packages.microsoft.com/debian/13/prod/" \
      "trixie"
    $STD apt install -y aspnetcore-runtime-10.0
  fi
  msg_ok "Ensured ASP.NET Core Runtime"

  rm -rf /opt/fileflows/{Server,FlowRunner,Libraries,Agent}
  fetch_and_deploy_from_url "https://fileflows.com/downloads/ff-latest.tar.xz" "/opt/fileflows"

  msg_info "Starting Service"
  systemctl --all start 'fileflows*'
  msg_ok "Started Service"
  msg_ok "Updated successfully!"

  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:19200${CL}"
