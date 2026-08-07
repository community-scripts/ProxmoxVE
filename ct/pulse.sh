#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: rcourtman & vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rcourtman/Pulse

APP="Pulse"
var_tags="${var_tags:-monitoring;proxmox}"
var_cpu="${var_cpu:-1}"
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

function pulse_enable_unit_from_state() {
  local unit="$1"
  local state="$2"

  case "$state" in
  enabled)
    systemctl enable -q "$unit" || return
    ;;
  enabled-runtime)
    systemctl enable -q --runtime "$unit" || return
    ;;
  esac
  return 0
}

function pulse_prepare_update_backup() {
  local backup_root="$1"
  local service_path="$2"
  local version_file="$3"
  local unit

  mkdir -p "$backup_root/systemd" || return
  for unit in pulse.service pulse-backend.service; do
    if [[ -e "$service_path/$unit" || -L "$service_path/$unit" ]]; then
      cp -a "$service_path/$unit" "$backup_root/systemd/$unit" || return
    fi
  done
  if [[ -e "$version_file" || -L "$version_file" ]]; then
    cp -a "$version_file" "$backup_root/version" || return
  fi
  if [[ -e /usr/local/bin/pulse || -L /usr/local/bin/pulse ]]; then
    cp -a /usr/local/bin/pulse "$backup_root/usr-local-bin-pulse" || return
  fi
}

function pulse_apply_update() {
  local backup_root="$1"
  local service_path="$2"
  local backend_enablement="$3"

  msg_info "Stopping Services"
  systemctl stop pulse*.service || return
  msg_ok "Stopped Services"

  mv /opt/pulse "$backup_root/pulse" || return
  CLEAN_INSTALL=1 fetch_and_deploy_gh_release "pulse" "rcourtman/Pulse" "prebuild" "latest" "/opt/pulse" "pulse-v*-linux-$(arch_resolve).tar.gz" || return
  if [[ ! -x /opt/pulse/bin/pulse ]]; then
    msg_error "The deployed archive does not contain an executable Pulse binary"
    return 252
  fi

  ln -sf /opt/pulse/bin/pulse /usr/local/bin/pulse || return
  mkdir -p /etc/pulse || return
  chown pulse:pulse /etc/pulse || return
  chown -R pulse:pulse /opt/pulse || return
  chmod 700 /etc/pulse || return
  if [[ -f "$service_path/pulse-backend.service" ]]; then
    systemctl disable -q pulse-backend.service 2>/dev/null || true
    mv "$service_path/pulse-backend.service" "$service_path/pulse.service" || return
  fi
  sed -i -e 's|pulse/pulse|pulse/bin/pulse|' \
    -e 's/^Environment="API.*$//' "$service_path/pulse.service" || return
  systemctl daemon-reload || return
  if [[ -f "$backup_root/systemd/pulse-backend.service" ]]; then
    pulse_enable_unit_from_state pulse.service "$backend_enablement" || return
  fi

  msg_info "Starting Services"
  systemctl start pulse || return
  systemctl is-active -q pulse || return
  msg_ok "Started Services"

  if grep -q 'pulse-home:/bin/bash' /etc/passwd; then
    usermod -s /usr/sbin/nologin pulse || msg_warn "Could not disable shell access for the pulse user"
  fi
}

function pulse_restore_update() {
  local backup_root="$1"
  local service_path="$2"
  local version_file="$3"
  local pulse_enablement="$4"
  local backend_enablement="$5"
  local restore_failed=0
  local unit

  msg_error "Update failed - restoring the previous ${APP} installation"
  systemctl stop pulse.service pulse-backend.service 2>/dev/null || true

  if [[ -d "$backup_root/pulse" ]]; then
    rm -rf /opt/pulse || restore_failed=1
    if [[ "$restore_failed" == "0" ]]; then
      mv "$backup_root/pulse" /opt/pulse || restore_failed=1
    fi
  elif [[ ! -d /opt/pulse ]]; then
    restore_failed=1
  fi

  rm -f /usr/local/bin/pulse || restore_failed=1
  if [[ -e "$backup_root/usr-local-bin-pulse" || -L "$backup_root/usr-local-bin-pulse" ]]; then
    cp -a "$backup_root/usr-local-bin-pulse" /usr/local/bin/pulse || restore_failed=1
  fi

  for unit in pulse.service pulse-backend.service; do
    rm -f "$service_path/$unit" || restore_failed=1
    if [[ -e "$backup_root/systemd/$unit" || -L "$backup_root/systemd/$unit" ]]; then
      cp -a "$backup_root/systemd/$unit" "$service_path/$unit" || restore_failed=1
    fi
  done

  if [[ -e "$backup_root/version" || -L "$backup_root/version" ]]; then
    cp -a "$backup_root/version" "$version_file" || restore_failed=1
  else
    rm -f "$version_file" || restore_failed=1
  fi

  systemctl daemon-reload || restore_failed=1
  systemctl disable -q pulse.service 2>/dev/null || true
  systemctl disable -q pulse-backend.service 2>/dev/null || true
  pulse_enable_unit_from_state pulse.service "$pulse_enablement" || restore_failed=1
  pulse_enable_unit_from_state pulse-backend.service "$backend_enablement" || restore_failed=1

  if systemctl start pulse 2>/dev/null || systemctl start pulse-backend 2>/dev/null; then
    if [[ "$restore_failed" == "0" ]]; then
      msg_ok "Restored and restarted the previous ${APP} installation"
    else
      msg_warn "Restarted ${APP}, but some rollback steps need manual verification"
    fi
  else
    restore_failed=1
    msg_error "${APP} could not be restarted - reinstall it or restore the container from a backup"
  fi

  if [[ "$restore_failed" == "0" ]]; then
    rm -rf "$backup_root" || msg_warn "Rollback succeeded, but the snapshot remains at $backup_root"
  else
    msg_error "Rollback was incomplete; the snapshot remains at $backup_root"
  fi
  return 0
}

function update_script() {
  local service_path="/etc/systemd/system"
  local version_file="$HOME/.pulse"
  local backup_root=""
  local pulse_enablement=""
  local backend_enablement=""
  local update_exit_code=0

  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/pulse ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "pulse" "rcourtman/Pulse"; then
    backup_root=$(mktemp -d /opt/.pulse-update.XXXXXX) || exit 73
    if ! pulse_prepare_update_backup "$backup_root" "$service_path" "$version_file"; then
      rm -rf "$backup_root"
      msg_error "Could not prepare a rollback snapshot; the running installation was not changed"
      exit 74
    fi

    pulse_enablement=$(systemctl is-enabled pulse.service 2>/dev/null || true)
    backend_enablement=$(systemctl is-enabled pulse-backend.service 2>/dev/null || true)

    if pulse_apply_update "$backup_root" "$service_path" "$backend_enablement"; then
      rm -rf "$backup_root" || msg_warn "Updated successfully, but could not remove the temporary rollback snapshot"
    else
      update_exit_code=$?
      pulse_restore_update "$backup_root" "$service_path" "$version_file" "$pulse_enablement" "$backend_enablement"
      exit "$update_exit_code"
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
echo -e "${GATEWAY}${BGN}http://${IP}:7655${CL}"
