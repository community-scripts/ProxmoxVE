#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://overseerr.dev/

APP="Overseerr"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/overseerr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if [[ -f "$HOME/.overseerr" ]] && [[ "$(cat "$HOME/.overseerr")" == "1.34.0" ]]; then
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Overseerr v1.34.0 detected."
    echo
    echo "Seerr is the new unified Jellyseerr and Overseerr."
    echo "More info: https://docs.seerr.dev/blog/seerr-release"
    echo
    read -rp "Do you want to migrate to Seerr now? (y/N): " MIGRATE
    echo
    if [[ ! "$MIGRATE" =~ ^[Yy]$ ]]; then
      msg_info "Migration cancelled. Exiting."
      exit 0
    fi

    msg_info "Switching update script to Seerr"
    cat <<'EOF' >/usr/bin/update
#!/usr/bin/env bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/seerr.sh)"
EOF
    chmod +x /usr/bin/update
    msg_ok "Switched update script to Seerr"
    msg_warn "Please type 'update' again to complete the migration"
    exit 0
  fi

  if check_for_gh_release "overseerr" "sct/overseerr"; then
    msg_info "Stopping Service"
    systemctl stop overseerr
    msg_ok "Service stopped"

    msg_info "Creating backup"
    mv /opt/overseerr/config /opt/config_backup
    msg_ok "Backup created"

    fetch_and_deploy_gh_release "overseerr" "sct/overseerr" "tarball"
    rm -rf /opt/overseerr/config

    msg_info "Configuring ${APP} (Patience)"
    cd /opt/overseerr
    $STD yarn install
    $STD yarn build
    mv /opt/config_backup /opt/overseerr/config
    msg_ok "Configured ${APP}"

    msg_info "Starting Service"
    systemctl start overseerr
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5055${CL}"
