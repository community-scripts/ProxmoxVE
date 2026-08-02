#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gotify.net/ | Github: https://github.com/gotify/server

APP="Gotify"
var_tags="${var_tags:-notification}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/gotify ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "gotify" "gotify/server"; then
    msg_info "Stopping Service"
    systemctl stop gotify
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "gotify" "gotify/server" "prebuild" "latest" "/opt/gotify" "gotify-linux-$(arch_resolve).zip"
    chmod +x /opt/gotify/gotify-linux-$(arch_resolve)

    if [[ ! -f /opt/gotify/gotify-server.env ]]; then
      gotify_old_config=""
      for f in /opt/gotify/config.yml /etc/gotify/config.yml; do
        [[ -f "$f" ]] && gotify_old_config="$f" && break
      done
      if [[ -n "$gotify_old_config" ]]; then
        msg_info "Migrating ${gotify_old_config} to env format (Gotify 3.x)"
        if /opt/gotify/gotify-linux-$(arch_resolve) migrate-config "$gotify_old_config" >/opt/gotify/gotify-server.env 2>/dev/null; then
          mv "$gotify_old_config" "${gotify_old_config}.bak"
          msg_ok "Migrated config to /opt/gotify/gotify-server.env (backup: ${gotify_old_config}.bak)"
        else
          rm -f /opt/gotify/gotify-server.env
          msg_warn "Config migration failed — left ${gotify_old_config} in place, review manually"
        fi
      fi
    fi

    if ! grep -qE '^ExecStart=.* serve' /etc/systemd/system/gotify.service 2>/dev/null; then
      msg_info "Migrating service to serve subcommand (Gotify 3.x)"
      sed -i -E 's|^(ExecStart=/opt/gotify/.*gotify-linux-[^ ]+)$|\1 serve|' /etc/systemd/system/gotify.service
      systemctl daemon-reload
      msg_ok "Migrated service to serve subcommand"
    fi

    msg_info "Starting Service"
    systemctl start gotify
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
