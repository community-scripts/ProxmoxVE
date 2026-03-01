#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.jellyseerr.dev/

APP="Jellyseerr"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/jellyseerr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if [[ -f "/opt/jellyseerr/package.json" ]] && [[ "$(grep -m1 '"version"' /opt/jellyseerr/package.json | awk -F'"' '{print $4}')" == "2.7.3" ]]; then
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Jellyseerr v2.7.3 detected."
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
    exit
  fi

  msg_info "Updating Jellyseerr"
  cd /opt/jellyseerr
  systemctl stop jellyseerr
  output=$(git pull --no-rebase)
  pnpm_desired=$(grep -Po '"pnpm":\s*"\K[^"]+' /opt/jellyseerr/package.json)
  NODE_VERSION="22" NODE_MODULE="pnpm@$pnpm_desired" setup_nodejs
  if echo "$output" | grep -q "Already up to date."; then
    msg_ok "$APP is already up to date."
    exit
  fi
  rm -rf dist .next node_modules
  export CYPRESS_INSTALL_BINARY=0
  cd /opt/jellyseerr
  $STD pnpm install --frozen-lockfile
  export NODE_OPTIONS="--max-old-space-size=3072"
  $STD pnpm build
  cat <<EOF >/etc/systemd/system/jellyseerr.service
[Unit]
Description=jellyseerr Service
After=network.target

[Service]
EnvironmentFile=/etc/jellyseerr/jellyseerr.conf
Environment=NODE_ENV=production
Type=exec
WorkingDirectory=/opt/jellyseerr
ExecStart=/usr/bin/node dist/index.js

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl start jellyseerr
  msg_ok "Updated Jellyseerr"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5055${CL}"
