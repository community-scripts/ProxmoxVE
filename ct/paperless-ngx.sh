#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.paperless-ngx.com/

APP="Paperless-ngx"
var_tags="${var_tags:-document;management}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-12}"
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
  if [[ ! -d /opt/paperless ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # Check for old data structure and prompt migration
  if [[ -f /opt/paperless/paperless.conf ]]; then
    local OLD_DIRS=()
    [[ -d /opt/paperless/consume ]] && OLD_DIRS+=("consume")
    [[ -d /opt/paperless/data ]] && OLD_DIRS+=("data")
    [[ -d /opt/paperless/media ]] && OLD_DIRS+=("media")

    if [[ ${#OLD_DIRS[@]} -gt 0 ]]; then
      msg_error "Old data structure detected in /opt/paperless/"
      msg_custom "📂" "Found directories: ${OLD_DIRS[*]}"
      echo -e ""
      msg_custom "🔄" "Migration required to new data structure (/opt/paperless_data/)"
      msg_custom "📖" "Please follow the migration guide:"
      echo -e "${TAB}${GATEWAY}${BGN}https://github.com/community-scripts/ProxmoxVE/discussions/9223${CL}"
      echo -e ""
      msg_custom "⚠️" "Update aborted. Please migrate your data first."
      exit 1
    fi
  fi

  if check_for_gh_release "paperless" "paperless-ngx/paperless-ngx"; then
    msg_info "Stopping all Paperless-ngx Services"
    systemctl stop paperless-consumer paperless-webserver paperless-scheduler paperless-task-queue
    msg_ok "Stopped all Paperless-ngx Services"

    if grep -q "uv run" /etc/systemd/system/paperless-webserver.service; then

      msg_info "Backing up configuration"
      local BACKUP_DIR="/opt/paperless_backup_$$"
      mkdir -p "$BACKUP_DIR"
      [[ -f /opt/paperless/paperless.conf ]] && cp /opt/paperless/paperless.conf "$BACKUP_DIR/"
      msg_ok "Backup completed to $BACKUP_DIR"

      PYTHON_VERSION="3.13" setup_uv
      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "paperless" "paperless-ngx/paperless-ngx" "prebuild" "latest" "/opt/paperless" "paperless*tar.xz"
      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "jbig2enc" "ie13/jbig2enc" "tarball" "latest" "/opt/jbig2enc"

      . /etc/os-release
      if [ "$VERSION_CODENAME" = "bookworm" ]; then
        setup_gs
      else
        $STD apt install -y ghostscript
      fi

      msg_info "Updating Paperless-ngx"
      cp -r "$BACKUP_DIR"/* /opt/paperless/
      cd /opt/paperless
      $STD uv sync --all-extras
      cd /opt/paperless/src
      $STD uv run -- python manage.py migrate
      msg_ok "Updated Paperless-ngx"

      rm -rf "$BACKUP_DIR"

    else
      msg_warn "You are about to migrate your Paperless-ngx installation to uv!"
      msg_custom "🔒" "It is strongly recommended to take a Proxmox snapshot first:"
      echo -e "   1. Stop the container:  pct stop <CTID>"
      echo -e "   2. Create a snapshot:  pct snapshot <CTID> pre-paperless-uv-migration"
      echo -e "   3. Start the container again\n"

      read -rp "Have you created a snapshot? [y/N]: " confirm
      if [[ ! "$confirm" =~ ^([yY]|[yY][eE][sS])$ ]]; then
        msg_error "Migration aborted. Please create a snapshot first."
        exit
      fi
      msg_info "Migrating old Paperless-ngx installation to uv"
      rm -rf /opt/paperless/venv
      find /opt/paperless -name "__pycache__" -type d -exec rm -rf {} +

      msg_info "Backing up configuration"
      local BACKUP_DIR="/opt/paperless_backup_$$"
      mkdir -p "$BACKUP_DIR"
      [[ -f /opt/paperless/paperless.conf ]] && cp /opt/paperless/paperless.conf "$BACKUP_DIR/"
      msg_ok "Backup completed to $BACKUP_DIR"

      declare -A PATCHES=(
        ["paperless-scheduler.service"]="ExecStart=uv run -- celery --app paperless beat --loglevel INFO"
        ["paperless-task-queue.service"]="ExecStart=uv run -- celery --app paperless worker --loglevel INFO"
        ["paperless-webserver.service"]="ExecStart=uv run -- granian --interface asgi --ws \"paperless.asgi:application\""
      )

      for svc in "${!PATCHES[@]}"; do
        path=$(systemctl show -p FragmentPath "$svc" | cut -d= -f2)
        if [[ -n "$path" && -f "$path" ]]; then
          sed -i "s|^ExecStart=.*|${PATCHES[$svc]}|" "$path"
          if [[ "$svc" == "paperless-webserver.service" ]]; then
            grep -q "^Environment=GRANIAN_HOST=" "$path" ||
              sed -i '/^\[Service\]/a Environment=GRANIAN_HOST=::' "$path"
            grep -q "^Environment=GRANIAN_PORT=" "$path" ||
              sed -i '/^\[Service\]/a Environment=GRANIAN_PORT=8000' "$path"
            grep -q "^Environment=GRANIAN_WORKERS=" "$path" ||
              sed -i '/^\[Service\]/a Environment=GRANIAN_WORKERS=1' "$path"
          fi
          msg_ok "Patched $svc"
        else
          msg_error "Service file for $svc not found!"
        fi
      done

      $STD systemctl daemon-reload
      msg_info "Backing up configuration"
      BACKUP_DIR="/opt/paperless_backup_$$"
      mkdir -p "$BACKUP_DIR"
      [[ -f /opt/paperless/paperless.conf ]] && cp /opt/paperless/paperless.conf "$BACKUP_DIR/"
      msg_ok "Backup completed to $BACKUP_DIR"

      PYTHON_VERSION="3.13" setup_uv
      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "paperless" "paperless-ngx/paperless-ngx" "prebuild" "latest" "/opt/paperless" "paperless*tar.xz"
      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "jbig2enc" "ie13/jbig2enc" "tarball" "latest" "/opt/jbig2enc"

      . /etc/os-release
      if [ "$VERSION_CODENAME" = "bookworm" ]; then
        setup_gs
      else
        msg_info "Installing Ghostscript"
        $STD apt install -y ghostscript
        msg_ok "Installed Ghostscript"
      fi

      msg_info "Updating Paperless-ngx"
      cp -r "$BACKUP_DIR"/* /opt/paperless/
      cd /opt/paperless
      $STD uv sync --all-extras
      cd /opt/paperless/src
      $STD uv run -- python manage.py migrate
      msg_ok "Paperless-ngx migration and update completed"

      rm -rf "$BACKUP_DIR"
      if [[ -d /opt/paperless/backup ]]; then
        rm -rf /opt/paperless/backup
        msg_ok "Removed old backup directory"
      fi
    fi

    msg_info "Starting all Paperless-ngx Services"
    systemctl start paperless-consumer paperless-webserver paperless-scheduler paperless-task-queue
    sleep 1
    msg_ok "Started all Paperless-ngx Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
