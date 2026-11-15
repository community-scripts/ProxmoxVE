#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://opencloud.eu | Github: https://github.com/opencloud-eu/opencloud

APP="OpenCloud"
var_tags="${var_tags:-files;cloud}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /etc/opencloud ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # Collabora 26.04.4 ignores frame-ancestors in content_security_policy; outside the release
  # check so installs already on the current release get it too
  if [[ -f /etc/coolwsd/coolwsd.xml ]] && ! grep -q '<frame_ancestors[^>]*>[^<[:space:]]' /etc/coolwsd/coolwsd.xml; then
    msg_info "Allowing OpenCloud to embed Collabora"
    $STD sudo -u cool coolconfig set net.frame_ancestors "$(sed -n 's/^OC_URL=//p' /etc/opencloud/opencloud.env)"
    systemctl restart coolwsd
    msg_ok "Allowed OpenCloud to embed Collabora"
  fi

  RELEASE="v9.0.0"
  if check_for_gh_release "OpenCloud" "opencloud-eu/opencloud" "${RELEASE}" "each release is tested individually before the version is updated. Please do not open issues for this"; then
    OLD_VERSION="$(cat ~/.opencloud 2>/dev/null)"
    msg_info "Stopping services"
    systemctl stop opencloud opencloud-wopi
    msg_ok "Stopped services"

    msg_info "Updating packages"
    apt_update_safe
    $STD apt dist-upgrade -y
    ensure_dependencies "inotify-tools"
    msg_ok "Updated packages"

    rm -f /usr/bin/{OpenCloud,opencloud}
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "OpenCloud" "opencloud-eu/opencloud" "singlefile" "${RELEASE}" "/usr/bin" "opencloud-*-linux-$(arch_resolve)"
    mv /usr/bin/OpenCloud /usr/bin/opencloud

    if ! grep -q 'POSIX_WATCH' /etc/opencloud/opencloud.env; then
      sed -i '/^## External/i ## Uncomment below to enable PosixFS Collaborative Mode\
## Increase inotify watch/instance limits on your PVE host:\
### sysctl -w fs.inotify.max_user_watches=1048576\
### sysctl -w fs.inotify.max_user_instances=1024\
# STORAGE_USERS_POSIX_ENABLE_COLLABORATION=true\
# STORAGE_USERS_POSIX_WATCH_TYPE=inotifywait\
# STORAGE_USERS_POSIX_WATCH_FS=true\
# STORAGE_USERS_POSIX_WATCH_PATH=<path-to-storage-or-bind-mount>' /etc/opencloud/opencloud.env
    fi

    # Every OpenCloud service falls back to OC_SERVICE_ACCOUNT_ID/SECRET, so services that newly
    # need the service account (sharing in 8.0, auth_guest in 9.0) work without editing opencloud.yaml
    if ! grep -q '^OC_SERVICE_ACCOUNT_ID=' /etc/opencloud/opencloud.env; then
      ACCOUNT_ID="$(awk '/service_account_id:/ {gsub(/["'\'']/, "", $2); print $2; exit}' /etc/opencloud/opencloud.yaml)"
      ACCOUNT_SECRET="$(awk '/service_account_secret:/ {sub(/^[^:]*:[[:space:]]*/, ""); gsub(/^["'\'']|["'\'']$/, ""); print; exit}' /etc/opencloud/opencloud.yaml)"
      if [[ -n "$ACCOUNT_ID" && -n "$ACCOUNT_SECRET" && "$ACCOUNT_SECRET" != *"'"* ]]; then
        printf "OC_SERVICE_ACCOUNT_ID=%s\nOC_SERVICE_ACCOUNT_SECRET='%s'\n" "$ACCOUNT_ID" "$ACCOUNT_SECRET" |
          sed -i '/^STORAGE_SYSTEM_OC_ROOT=/r /dev/stdin' /etc/opencloud/opencloud.env
      else
        msg_warn "Could not read the service account from opencloud.yaml; set OC_SERVICE_ACCOUNT_ID/SECRET in opencloud.env"
      fi
    fi

    if ! grep -q 'OC_ENABLE_GUEST_LINKS' /etc/opencloud/opencloud.env; then
      sed -i '/^## Start additional services/i ## Guest links - share with external people by email\
## Requires the SMTP settings above and notifications in OC_ADD_RUN_SERVICES\
# OC_ENABLE_GUEST_LINKS=true\
' /etc/opencloud/opencloud.env
    fi

    # 9.0: the default space quota is read only under its new name, and thumbnails are cached in thumbnails/cache
    sed -i 's/^GRAPH_SPACES_DEFAULT_QUOTA=/OC_SPACES_DEFAULT_QUOTA=/' /etc/opencloud/opencloud.env
    rm -rf /var/lib/opencloud/thumbnails/files

    msg_info "Starting services"
    systemctl start opencloud opencloud-wopi
    msg_ok "Started services"

    if [[ -z "$OLD_VERSION" || "${OLD_VERSION#v}" =~ ^[0-7]\. ]]; then
      # The index CLI cancels the rebuild when interrupted, so it runs as its own unit and the
      # update only waits for it. Restart covers a search service that is still starting.
      msg_info "Rebuilding search index (safe to interrupt, it continues in the background)"
      REINDEX_START="$(date '+%Y-%m-%d %H:%M:%S')"
      systemctl reset-failed opencloud-reindex &>/dev/null || true
      $STD systemd-run --unit=opencloud-reindex --uid=opencloud --gid=opencloud \
        -p EnvironmentFile=/etc/opencloud/opencloud.env -p Restart=on-failure -p RestartSec=15 \
        -p StartLimitIntervalSec=900 -p StartLimitBurst=20 \
        /usr/bin/opencloud search index --all-spaces --force-rescan --insecure
      while [[ "$(systemctl show -p ActiveState --value opencloud-reindex)" =~ ^(active|activating)$ ]]; do
        sleep 10
      done
      if [[ "$(systemctl show -p ActiveState --value opencloud-reindex)" == "failed" ]]; then
        msg_ok "Stopped waiting for the search index rebuild"
        msg_warn "The rebuild did not complete, see: journalctl -u opencloud-reindex"
        msg_warn "Retry with: systemctl reset-failed opencloud-reindex; systemd-run --unit=opencloud-reindex \
          --uid=opencloud --gid=opencloud -p EnvironmentFile=/etc/opencloud/opencloud.env \
          /usr/bin/opencloud search index --all-spaces --force-rescan --insecure"
      else
        msg_ok "Rebuilt search index"
        if journalctl -u opencloud-reindex --since "$REINDEX_START" --no-pager | grep -qE '/[0-9]+ ERROR'; then
          msg_warn "Some spaces could not be indexed, see: journalctl -u opencloud-reindex"
        fi
        msg_warn "Once search finds older files, remove the old index: rm -rf /var/lib/opencloud/search/bleve"
      fi
    fi
    msg_ok "Updated successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}https://<your-OpenCloud-FQDN>${CL}"
