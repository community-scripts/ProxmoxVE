#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: rrole
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wanderer.to

APP="Wanderer"
var_tags="${var_tags:-travelling;sport}"
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

    if [[ ! -f /opt/wanderer/start.sh ]]; then
        msg_error "No wanderer Installation Found!"
        exit
    fi

    if check_for_gh_release "wanderer" "Flomp/wanderer"; then
        msg_info "Stopping service"
        systemctl stop wanderer-web
        msg_ok "Stopped service"
        
				fetch_and_deploy_gh_release "wanderer" "Flomp/wanderer"  "tarball" "latest" "/opt/wanderer/source"
				
        msg_info "Updating wanderer"
        cd /opt/wanderer/source/db
        $STD go mod tidy
       	$STD go build
        cd /opt/wanderer/source/web
        $STD npm ci --omit=dev
        $STD npm run build
        msg_ok "Updated wanderer"

        msg_info "Starting service"
        systemctl start wanderer-web
        msg_ok "Started service"
        msg_ok "Update Successful"
    fi
    if check_for_gh_release "meilisearch" "meilisearch/meilisearch"; then
        msg_info "Stopping service"
        systemctl stop wanderer-web
        msg_ok "Stopped service"

    		fetch_and_deploy_gh_release "meilisearch" "meilisearch/meilisearch" "binary" "latest" "/opt/wanderer/source/search"

        msg_info "Preparing start script for database migration"
        if grep -q "meilisearch --master-key" /opt/wanderer/start.sh; then
            sed -i 's|meilisearch --master-key|meilisearch --experimental-dumpless-upgrade --master-key|g' /opt/wanderer/start.sh
            msg_ok "Prepared start script"
        else
            msg_error "Could not find expected meilisearch command in start script"
            exit 1
        fi

        msg_info "Starting service with database migration"
        systemctl start wanderer-web
        if systemctl is-active --quiet wanderer-web; then
            msg_ok "Started service"
        else
            msg_error "Failed to start service"
            exit 1
        fi

        msg_info "Allowing time for database migration (30 seconds)"
        sleep 30
        msg_ok "Migration time elapsed"

        msg_info "Stopping service"
        systemctl stop wanderer-web
        msg_ok "Stopped service"

        msg_info "Restoring start script to normal operation"
        if grep -q "meilisearch --experimental-dumpless-upgrade --master-key" /opt/wanderer/start.sh; then
            sed -i 's|meilisearch --experimental-dumpless-upgrade --master-key|meilisearch --master-key|g' /opt/wanderer/start.sh
            msg_ok "Restored start script"
        else
            msg_error "Could not find experimental upgrade flag in start script"
            exit 1
        fi

        msg_info "Starting service"
        systemctl start wanderer-web
        if systemctl is-active --quiet wanderer-web; then
            msg_ok "Started service"
        else
            msg_error "Failed to start service"
            exit 1
        fi
        msg_ok "Update Successful"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
