#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.paperless-ngx.com/ | Github: https://github.com/paperless-ngx/paperless-ngx

APP="Paperless-ngx"
var_tags="${var_tags:-document;management}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
var_disk="${var_disk:-12}"
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
  if [[ ! -d /opt/paperless ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # Check for old data structure and prompt migration (exclude symlinks)
  if [[ -f /opt/paperless/paperless.conf ]]; then
    local OLD_DIRS=()
    [[ -d /opt/paperless/consume && ! -L /opt/paperless/consume ]] && OLD_DIRS+=("consume")
    [[ -d /opt/paperless/data && ! -L /opt/paperless/data ]] && OLD_DIRS+=("data")
    [[ -d /opt/paperless/media && ! -L /opt/paperless/media ]] && OLD_DIRS+=("media")

    if [[ ${#OLD_DIRS[@]} -gt 0 ]]; then
      msg_error "Old data structure detected in /opt/paperless/"
      msg_custom "📂" "Found directories: ${OLD_DIRS[*]}"
      echo -e ""
      msg_custom "🔄" "Migration required to new data structure (/opt/paperless_data/)"
      msg_custom "📖" "Please follow the migration guide:"
      echo -e "${GATEWAY}${BGN}https://github.com/community-scripts/ProxmoxVE/discussions/9223${CL}"
      echo -e ""
      msg_custom "⚠️" "Update aborted. Please migrate your data first."
      exit 253
    fi
  fi

  local PAPERLESS_INSTALLED_VERSION="" BRIDGE_UPDATE=0
  [[ -f ~/.paperless ]] && PAPERLESS_INSTALLED_VERSION="$(<~/.paperless)"
  PAPERLESS_INSTALLED_VERSION="${PAPERLESS_INSTALLED_VERSION#v}"
  if [[ "$PAPERLESS_INSTALLED_VERSION" == 2.* && "$PAPERLESS_INSTALLED_VERSION" != "2.20.15" ]]; then
    BRIDGE_UPDATE=1
  fi

  if check_for_gh_release "paperless" "paperless-ngx/paperless-ngx"; then
    if [[ "$PAPERLESS_INSTALLED_VERSION" == "2.20.15" ]]; then
      msg_warn "Paperless-ngx v3 does not support encrypted documents anymore."
      echo -e "${GATEWAY}${BGN}https://docs.paperless-ngx.com/migration-v3/#encryption-support${CL}"
      msg_warn "Before continuing make sure that you do not use encryption or have decrypted all documents."
      echo ""
      read -rp "Do you want to continue with the update? (y/N): " MIGRATE
      echo
      if [[ ! "$MIGRATE" =~ ^[Yy]$ ]]; then
        msg_info "Update aborted. Decrypt all documents before upgrading to v3."
        exit 0
      fi
    fi

    msg_info "Stopping all Paperless-ngx Services"
    systemctl stop paperless-consumer paperless-webserver paperless-scheduler paperless-task-queue
    msg_ok "Stopped all Paperless-ngx Services"

    if grep -q "uv run" /etc/systemd/system/paperless-webserver.service; then
      msg_info "Backing up configuration"
      local BACKUP_DIR="/opt/paperless_backup_$$"
      mkdir -p "$BACKUP_DIR"
      [[ -f /opt/paperless/paperless.conf ]] && cp /opt/paperless/paperless.conf "$BACKUP_DIR/"
      msg_ok "Backup completed to $BACKUP_DIR"

      PG_VERSION="18" setup_postgresql
      PYTHON_VERSION="3.13" setup_uv  
      if ((BRIDGE_UPDATE)); then
        CLEAN_INSTALL=1 fetch_and_deploy_gh_release "paperless" "paperless-ngx/paperless-ngx" "prebuild" "v2.20.15" "/opt/paperless" "paperless*tar.xz"
      else
        CLEAN_INSTALL=1 fetch_and_deploy_gh_release "paperless" "paperless-ngx/paperless-ngx" "prebuild" "latest" "/opt/paperless" "paperless*tar.xz"
      fi
      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "jbig2enc" "ie13/jbig2enc" "tarball" "latest" "/opt/jbig2enc"

      . /etc/os-release
      if [ "$VERSION_CODENAME" = "bookworm" ]; then
        setup_gs
      else
        ensure_dependencies ghostscript
      fi
      ensure_dependencies gnupg

      msg_info "Updating Paperless-ngx"
      cp -r "$BACKUP_DIR"/* /opt/paperless/
      if ((BRIDGE_UPDATE == 0)) && [[ "$PAPERLESS_INSTALLED_VERSION" == 2.* ]]; then
        msg_info "Migrating Paperless-ngx v2 configuration to v3"
        PAPERLESS_CONF="/opt/paperless/paperless.conf"

        SECRET_KEY_CURRENT="$(sed -n 's|^PAPERLESS_SECRET_KEY=||p' "$PAPERLESS_CONF" | tail -n1)"
        DBENGINE="$(sed -n 's|^PAPERLESS_DBENGINE=||p' "$PAPERLESS_CONF" | tail -n1)"
        DB_OPTIONS_DEPRECATED="$(sed -n '/^PAPERLESS_DBSSLMODE=/p;/^PAPERLESS_DBSSLROOTCERT=/p;/^PAPERLESS_DBSSLCERT=/p;/^PAPERLESS_DBSSLKEY=/p;/^PAPERLESS_DB_POOLSIZE=/p;/^PAPERLESS_DB_TIMEOUT=/p' "$PAPERLESS_CONF")"
        CONSUMER_POLLING="$(sed -n 's|^PAPERLESS_CONSUMER_POLLING=||p' "$PAPERLESS_CONF" | tail -n1)"
        CONSUMER_POLLING_INTERVAL="$(sed -n 's|^PAPERLESS_CONSUMER_POLLING_INTERVAL=||p' "$PAPERLESS_CONF" | tail -n1)"
        CONSUMER_INOTIFY_DELAY="$(sed -n 's|^PAPERLESS_CONSUMER_INOTIFY_DELAY=||p' "$PAPERLESS_CONF" | tail -n1)"
        CONSUMER_STABILITY_DELAY="$(sed -n 's|^PAPERLESS_CONSUMER_STABILITY_DELAY=||p' "$PAPERLESS_CONF" | tail -n1)"
        OCR_MODE="$(sed -n 's|^PAPERLESS_OCR_MODE=||p' "$PAPERLESS_CONF" | tail -n1)"
        OCR_SKIP_ARCHIVE="$(sed -n 's|^PAPERLESS_OCR_SKIP_ARCHIVE_FILE=||p' "$PAPERLESS_CONF" | tail -n1)"
        ARCHIVE_FILE_GENERATION="$(sed -n 's|^PAPERLESS_ARCHIVE_FILE_GENERATION=||p' "$PAPERLESS_CONF" | tail -n1)"
        CONSUMER_DELETE_DUPLICATES="$(sed -n 's|^PAPERLESS_CONSUMER_DELETE_DUPLICATES=||p' "$PAPERLESS_CONF" | tail -n1)"

        sed -i \
          -e '/^PAPERLESS_CONSUMER_POLLING=/d' \
          -e '/^PAPERLESS_CONSUMER_INOTIFY_DELAY=/d' \
          -e '/^PAPERLESS_CONSUMER_POLLING_DELAY=/d' \
          -e '/^PAPERLESS_CONSUMER_POLLING_RETRY_COUNT=/d' \
          -e '/^PAPERLESS_CONSUMER_BARCODE_SCANNER=/d' \
          -e '/^PAPERLESS_PASSPHRASE=/d' \
          -e '/^PAPERLESS_OCR_SKIP_ARCHIVE_FILE=/d' \
          -e 's|^PAPERLESS_OCR_MODE="\?skip"\?$|PAPERLESS_OCR_MODE=auto|' \
          -e 's|^PAPERLESS_OCR_MODE="\?skip_noarchive"\?$|PAPERLESS_OCR_MODE=auto|' \
          "$PAPERLESS_CONF"

        [[ -n "$DB_OPTIONS_DEPRECATED" ]] &&
          msg_warn "Deprecated Paperless DB options detected; migrate them manually to PAPERLESS_DB_OPTIONS."
        if [[ -z "$SECRET_KEY_CURRENT" || "$SECRET_KEY_CURRENT" == "change-me" ]]; then
          SECRET_KEY="$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | od -An -tx1 | tr -d ' \n')"
          sed -i \
            -e '/^#\?PAPERLESS_SECRET_KEY=/d' \
            -e "\$a\\PAPERLESS_SECRET_KEY=$SECRET_KEY" \
            "$PAPERLESS_CONF"
          printf "Paperless-ngx Secret Key: %s\n" "$SECRET_KEY" >>~/paperless-ngx.creds
        fi
        [[ -z "$DBENGINE" ]] && sed -i '$a\PAPERLESS_DBENGINE=postgresql' "$PAPERLESS_CONF"
        [[ -n "$CONSUMER_POLLING" && -z "$CONSUMER_POLLING_INTERVAL" ]] &&
          sed -i "\$a\\PAPERLESS_CONSUMER_POLLING_INTERVAL=$CONSUMER_POLLING" "$PAPERLESS_CONF"
        [[ -n "$CONSUMER_INOTIFY_DELAY" && -z "$CONSUMER_STABILITY_DELAY" ]] &&
          sed -i "\$a\\PAPERLESS_CONSUMER_STABILITY_DELAY=$CONSUMER_INOTIFY_DELAY" "$PAPERLESS_CONF"
        [[ -z "$CONSUMER_DELETE_DUPLICATES" ]] &&
          sed -i '$a\PAPERLESS_CONSUMER_DELETE_DUPLICATES=true' "$PAPERLESS_CONF"
        if [[ -z "$ARCHIVE_FILE_GENERATION" ]]; then
          if [[ "$OCR_MODE" == "skip_noarchive" || "$OCR_MODE" == "\"skip_noarchive\"" ]]; then
            sed -i '$a\PAPERLESS_ARCHIVE_FILE_GENERATION=never' "$PAPERLESS_CONF"
          elif [[ "$OCR_SKIP_ARCHIVE" == "never" || "$OCR_SKIP_ARCHIVE" == "\"never\"" ]]; then
            sed -i '$a\PAPERLESS_ARCHIVE_FILE_GENERATION=always' "$PAPERLESS_CONF"
          elif [[ "$OCR_SKIP_ARCHIVE" == "with_text" || "$OCR_SKIP_ARCHIVE" == "\"with_text\"" ]]; then
            sed -i '$a\PAPERLESS_ARCHIVE_FILE_GENERATION=auto' "$PAPERLESS_CONF"
          elif [[ "$OCR_SKIP_ARCHIVE" == "always" || "$OCR_SKIP_ARCHIVE" == "\"always\"" ]]; then
            sed -i '$a\PAPERLESS_ARCHIVE_FILE_GENERATION=never' "$PAPERLESS_CONF"
          fi
        fi
        [[ -n "$(sed -n '/^PAPERLESS_CONSUMER_IGNORE_PATTERNS=/p' "$PAPERLESS_CONF")" ]] &&
          msg_warn "PAPERLESS_CONSUMER_IGNORE_PATTERNS now uses regex patterns; please verify custom values."
        [[ -n "$(sed -n '/^PAPERLESS_PRE_CONSUME_SCRIPT=/p;/^PAPERLESS_POST_CONSUME_SCRIPT=/p' "$PAPERLESS_CONF")" ]] &&
          msg_warn "Pre/post consume scripts no longer receive positional arguments in v3; please verify custom scripts."
        msg_ok "Migrated Paperless-ngx configuration"
      fi

      if ((BRIDGE_UPDATE == 0)); then
        sed -i 's|^ExecStart=.*|ExecStart=uv run -- granian --interface asginl --ws --loop uvloop "paperless.asgi:application"|' /etc/systemd/system/paperless-webserver.service
        $STD systemctl daemon-reload
      fi
      cd /opt/paperless
      $STD uv sync --all-extras
      cd /opt/paperless/src
      $STD uv run -- python manage.py migrate
      msg_ok "Updated Paperless-ngx"

      if ((BRIDGE_UPDATE == 0)) && [[ "$PAPERLESS_INSTALLED_VERSION" == "2.20.15" ]]; then
        $STD apt -y purge libzbar0t64 libzbar0 2>/dev/null || true
        $STD apt -y autoremove 2>/dev/null || true
      fi

      rm -rf "$BACKUP_DIR"

    else
      BRIDGE_UPDATE=1
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
        ["paperless-consumer.service"]="ExecStart=uv run -- python manage.py document_consumer"
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
      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "paperless" "paperless-ngx/paperless-ngx" "prebuild" "v2.20.15" "/opt/paperless" "paperless*tar.xz"
      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "jbig2enc" "ie13/jbig2enc" "tarball" "latest" "/opt/jbig2enc"

      . /etc/os-release
      if [ "$VERSION_CODENAME" = "bookworm" ]; then
        setup_gs
      else
        msg_info "Installing Ghostscript"
        ensure_dependencies ghostscript
        msg_ok "Installed Ghostscript"
      fi
      ensure_dependencies gnupg

      msg_info "Updating Paperless-ngx to v2.20.15"
      cp -r "$BACKUP_DIR"/* /opt/paperless/
      cd /opt/paperless
      $STD uv sync --all-extras
      cd /opt/paperless/src
      $STD uv run -- python manage.py migrate
      msg_ok "Migrated to uv and updated to v2.20.15 (required before v3)"

      rm -rf "$BACKUP_DIR"
      if [[ -d /opt/paperless/backup ]]; then
        rm -rf /opt/paperless/backup
        msg_ok "Removed old backup directory"
      fi
    fi

    setup_nltk "snowball_data stopwords punkt_tab" "/usr/share/nltk_data"

    msg_info "Starting all Paperless-ngx Services"
    systemctl start paperless-consumer paperless-webserver paperless-scheduler paperless-task-queue
    sleep 1
    msg_ok "Started all Paperless-ngx Services"
    if ((BRIDGE_UPDATE)); then
      msg_custom "ℹ️" "${YW}" "Paperless-ngx is now on v2.20.15. Run the update again to upgrade to v3."
      exit
    fi
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
echo -e "${GATEWAY}${BGN}http://${IP}:8000${CL}"
