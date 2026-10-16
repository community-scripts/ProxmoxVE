#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/kikootwo/ReadMeABook

APP="ReadMeABook"
var_tags="${var_tags:-arr;audiobook}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/readmeabook ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if ! grep -q '^ExecStartPost=-/usr/local/bin/readmeabook-init$' /etc/systemd/system/readmeabook.service; then
    msg_info "Starting the scheduler with the service"
    cat <<'EOF' >/usr/local/bin/readmeabook-init
#!/usr/bin/env bash
# Upstream's image calls /api/init after every start: it creates the scheduled jobs and starts the scheduler
url="http://127.0.0.1:${PORT:-3030}"
for _ in $(seq 1 60); do curl -sf -o /dev/null "$url/api/health" && break; sleep 1; done
for _ in $(seq 1 30); do [[ "$(redis-cli ping 2>/dev/null)" == PONG ]] && break; sleep 1; done
for attempt in 1 2 3 4 5; do
  curl -sf -o /dev/null "$url/api/init" && exit 0
  sleep "$attempt"
done
echo "ReadMeABook did not answer /api/init, scheduled jobs will not run" >&2
exit 1
EOF
    chmod +x /usr/local/bin/readmeabook-init
    sed -i '/^ExecStart=/a ExecStartPost=-/usr/local/bin/readmeabook-init\nTimeoutStartSec=180' /etc/systemd/system/readmeabook.service
    systemctl daemon-reload
    systemctl restart readmeabook
    msg_ok "Started the scheduler with the service"
  fi

  if check_for_gh_release "readmeabook" "kikootwo/ReadMeABook"; then
    msg_info "Stopping Service"
    systemctl stop readmeabook
    msg_ok "Stopped Service"

    create_backup /opt/readmeabook/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "readmeabook" "kikootwo/ReadMeABook" "tarball"

    restore_backup

    msg_info "Building ReadMeABook (Patience)"
    cd /opt/readmeabook
    $STD npm ci
    set -a
    source /opt/readmeabook/.env
    set +a
    $STD npx prisma generate
    $STD npx prisma db push --skip-generate --accept-data-loss
    $STD npm run build
    if [[ -f /opt/readmeabook/.next/standalone/server.js ]]; then
      cp -r /opt/readmeabook/.next/static /opt/readmeabook/.next/standalone/.next/static
      [[ -d /opt/readmeabook/public ]] && cp -r /opt/readmeabook/public /opt/readmeabook/.next/standalone/public
    fi
    msg_ok "Built ReadMeABook"

    msg_info "Starting Service"
    systemctl start readmeabook
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3030${CL}"
