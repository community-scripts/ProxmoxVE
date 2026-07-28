#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.bazarr.media/ | Github: https://github.com/morpheus65535/bazarr

APP="Bazarr"
var_tags="${var_tags:-arr}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /var/lib/bazarr/ ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # One-time migration for installs created before Bazarr was given an explicit
  # data directory. Bazarr defaults to <install dir>/data, so those installs keep
  # config/ db/ backup/ cache/ log/ restore/ inside /opt/bazarr - the directory
  # fetch_and_deploy_gh_release redeploys over. Move it to /var/lib/bazarr (already
  # created and guarded on above) and pass -c, matching the -data= flag the other
  # *arr scripts use. Runs outside the release check so installs already on the
  # latest version still get migrated. Skipped entirely if the unit already names
  # a data directory, so a hand-picked location is left alone.
  if ! grep -qE -- "bazarr\.py.*[[:space:]](-c|--config)([[:space:]]|=)" /etc/systemd/system/bazarr.service 2>/dev/null; then
    # Bail out before stopping anything, so a refusal leaves the install running.
    if [[ -d /opt/bazarr/data && ! -L /opt/bazarr/data && -n "$(ls -A /var/lib/bazarr/ 2>/dev/null)" ]]; then
      msg_error "/opt/bazarr/data and /var/lib/bazarr both contain data - refusing to merge them. Keep the copy you want in /var/lib/bazarr, remove /opt/bazarr/data, then run the update again."
      exit 1
    fi

    msg_info "Moving Bazarr data to /var/lib/bazarr"
    systemctl stop bazarr
    if [[ -L /opt/bazarr/data ]]; then
      # Symlinked to /var/lib/bazarr by hand as a workaround; -c replaces it.
      rm -f /opt/bazarr/data
    elif [[ -d /opt/bazarr/data ]]; then
      # Copy first and only delete once it succeeded, so a failure here (a full
      # disk, most likely) leaves the original database untouched.
      if ! cp -a /opt/bazarr/data/. /var/lib/bazarr/; then
        systemctl start bazarr
        msg_error "Could not copy /opt/bazarr/data to /var/lib/bazarr - nothing was removed."
        exit 1
      fi
      rm -rf /opt/bazarr/data
    fi
    sed -i -E "s|^(ExecStart=.*bazarr\.py.*)$|\1 -c /var/lib/bazarr|" /etc/systemd/system/bazarr.service
    systemctl daemon-reload
    systemctl start bazarr
    msg_ok "Moved Bazarr data to /var/lib/bazarr"
  fi

  if check_for_gh_release "bazarr" "morpheus65535/bazarr"; then
    msg_info "Stopping Service"
    systemctl stop bazarr
    msg_ok "Stopped Service"

    PYTHON_VERSION="3.12" setup_uv
    fetch_and_deploy_gh_release "bazarr" "morpheus65535/bazarr" "prebuild" "latest" "/opt/bazarr" "bazarr.zip"

    msg_info "Setup Bazarr"
    mkdir -p /var/lib/bazarr/
    chmod 775 /opt/bazarr /var/lib/bazarr/
    # Always ensure venv exists
    if [[ ! -d /opt/bazarr/venv/ ]]; then
      $STD uv venv --clear /opt/bazarr/venv --python 3.12
    fi
    
    # Always check and fix service file if needed
    if [[ -f /etc/systemd/system/bazarr.service ]] && grep -q "ExecStart=/usr/bin/python3" /etc/systemd/system/bazarr.service; then
      sed -i "s|ExecStart=/usr/bin/python3 /opt/bazarr/bazarr.py|ExecStart=/opt/bazarr/venv/bin/python3 /opt/bazarr/bazarr.py|g" /etc/systemd/system/bazarr.service
      systemctl daemon-reload
    fi
    sed -i.bak 's/--only-binary=Pillow//g' /opt/bazarr/requirements.txt
    $STD uv pip install -r /opt/bazarr/requirements.txt --python /opt/bazarr/venv/bin/python3
    msg_ok "Setup Bazarr"

    msg_info "Starting Service"
    systemctl start bazarr
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
echo -e "${GATEWAY}${BGN}http://${IP}:6767${CL}"
