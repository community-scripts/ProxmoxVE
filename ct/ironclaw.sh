#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/nearai/ironclaw

APP="IronClaw"
var_tags="${var_tags:-ai;agent;security}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
if [[ -z "${var_os:-}" ]] && command -v pveversion >/dev/null 2>&1; then
  var_os=$(msg_menu "Choose the container OS" \
    "debian" "Debian 13" \
    "alpine" "Alpine (smaller footprint)")
fi

if [[ "${var_os:-}" == "alpine" ]]; then
  var_cpu="${var_cpu:-1}"
  var_ram="${var_ram:-1024}"
  var_disk="${var_disk:-8}"
  var_version="${var_version:-3.24}"
else
  var_cpu="${var_cpu:-2}"
  var_ram="${var_ram:-2048}"
  var_disk="${var_disk:-8}"
  var_version="${var_version:-13}"
fi

header_info "$APP"
variables
color
catch_errors

# IronClaw 1.x ("Reborn") is a ground-up rearchitecture of 0.29.x: the config
# home moved from /root/.ironclaw/.env to /root/.ironclaw/reborn/ and the
# service is a systemd *user* unit (ironclaw-reborn.service) installed by the
# binary itself via `ironclaw service install`. Pre-1.0 installs used a
# system-scope unit named ironclaw.service, whose CLI no longer exists in 1.x.
ironclaw_running() {
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -x ironclaw >/dev/null 2>&1
  else
    local p
    for p in /proc/[0-9]*/comm; do
      [[ "$(cat "$p" 2>/dev/null)" == "ironclaw" ]] && return 0
    done
    return 1
  fi
}

# Returns 1 if a daemon is still running after the stop attempts - the live
# executable would then block the binary replacement with ETEXTBSY.
stop_ironclaw_service() {
  systemctl --user stop ironclaw-reborn 2>/dev/null \
    || systemctl stop ironclaw-reborn 2>/dev/null \
    || systemctl stop ironclaw 2>/dev/null \
    || rc-service ironclaw stop 2>/dev/null \
    || true
  local i
  for i in 1 2 3 4 5; do
    ironclaw_running || return 0
    sleep 1
  done
  return 1
}

start_ironclaw_service() {
  /usr/local/bin/ironclaw service start 2>/dev/null \
    || systemctl --user start ironclaw-reborn 2>/dev/null \
    || systemctl start ironclaw 2>/dev/null
}

back_up_ironclaw_configuration() {
  if [[ -d /root/.ironclaw/reborn ]]; then
    msg_info "Backing up Configuration"
    tar -czf /root/ironclaw-reborn.bak.tar.gz -C /root/.ironclaw reborn
    msg_ok "Backed up Configuration"
  elif [[ -f /root/.ironclaw/.env ]]; then
    msg_info "Backing up Configuration"
    cp /root/.ironclaw/.env /root/ironclaw.env.bak
    msg_ok "Backed up Configuration"
  fi
}

restore_ironclaw_configuration() {
  if [[ -f /root/ironclaw-reborn.bak.tar.gz ]]; then
    msg_info "Restoring Configuration"
    rm -rf /root/.ironclaw/reborn
    tar -xzf /root/ironclaw-reborn.bak.tar.gz -C /root/.ironclaw
    rm -f /root/ironclaw-reborn.bak.tar.gz
    msg_ok "Restored Configuration"
  elif [[ -f /root/ironclaw.env.bak ]]; then
    msg_info "Restoring Configuration"
    cp /root/ironclaw.env.bak /root/.ironclaw/.env
    rm -f /root/ironclaw.env.bak
    msg_ok "Restored Configuration"
  fi
}

# Pre-1.0 system units cannot run the 1.x binary (incompatible CLI); remove
# them so `systemctl start ironclaw` does not keep failing on every boot.
remove_ironclaw_legacy_unit() {
  if systemctl list-unit-files 2>/dev/null | grep -q '^ironclaw\.service'; then
    msg_info "Removing legacy pre-1.0 system unit (ironclaw.service)"
    systemctl disable --now ironclaw 2>/dev/null || true
    rm -f /etc/systemd/system/ironclaw.service
    systemctl daemon-reload
    msg_ok "Removed legacy unit"
  fi
}

update_deb_based() {
  if [[ ! -f /usr/local/bin/ironclaw ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE="ironclaw-v1.4.0"
  if check_for_gh_release "ironclaw-bin" "nearai/ironclaw" "${RELEASE}" "verified against IronClaw 1.4 (Reborn); bump once a newer release is tested"; then
    msg_info "Stopping Service"
    if ! stop_ironclaw_service; then
      msg_error "An ${APP} process is still running and could not be stopped - update aborted"
      exit 1
    fi
    msg_ok "Stopped Service"

    back_up_ironclaw_configuration

    fetch_and_deploy_gh_release "ironclaw-bin" "nearai/ironclaw" "prebuild" "${RELEASE}" "/usr/local/bin" \
      "ironclaw-$(uname -m)-unknown-linux-gnu.tar.gz"
    chmod +x /usr/local/bin/ironclaw

    restore_ironclaw_configuration
    remove_ironclaw_legacy_unit

    msg_info "Starting Service"
    if start_ironclaw_service; then
      msg_ok "Started Service"
    else
      msg_warn "Could not start the service automatically. Inside the container run: ${BGN}/usr/local/bin/ironclaw service install${CL} (pre-1.0 installs) or ${BGN}/usr/local/bin/ironclaw service start${CL}"
    fi
    msg_ok "Updated successfully!"
  fi
}

update_alpine() {
  if [[ ! -f /usr/local/bin/ironclaw ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE="ironclaw-v1.4.0"
  if check_for_gh_release "ironclaw-bin" "nearai/ironclaw" "${RELEASE}" "verified against IronClaw 1.4 (Reborn); bump once a newer release is tested"; then
    msg_info "Stopping Service"
    if ! stop_ironclaw_service; then
      msg_error "An ${APP} process is still running and could not be stopped - update aborted"
      exit 1
    fi
    msg_ok "Stopped Service"

    back_up_ironclaw_configuration

    fetch_and_deploy_gh_release "ironclaw-bin" "nearai/ironclaw" "prebuild" "${RELEASE}" "/usr/local/bin" \
      "ironclaw-$(uname -m)-unknown-linux-musl.tar.gz"
    chmod +x /usr/local/bin/ironclaw

    restore_ironclaw_configuration

    msg_info "Starting Service"
    if rc-service ironclaw start 2>/dev/null; then
      msg_ok "Started Service"
    else
      msg_warn "No openrc service found. IronClaw 1.x has no openrc integration (its ${BGN}service${CL} command needs systemd/launchd) - supervise ${BGN}/usr/local/bin/ironclaw serve${CL} yourself"
    fi
    msg_ok "Updated successfully!"
  fi
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  run_os_update
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Next Steps (inside the container):${CL}"
echo -e "${TAB}1. Complete setup (config, LLM provider, WebUI token, OS service):${CL}"
echo -e "${TAB}${TAB}${BGN}/usr/local/bin/ironclaw onboard${CL}"
echo -e "${TAB}${TAB}(non-interactive sessions skip service install - do it manually):${CL}"
echo -e "${TAB}${TAB}${BGN}/usr/local/bin/ironclaw service install && /usr/local/bin/ironclaw service start${CL}"
echo -e "${TAB}${TAB}${BGN}loginctl enable-linger root${CL}"
echo -e "${TAB}2. To reach the WebUI from outside the container, bind it to all interfaces${CL}"
echo -e "${TAB}${TAB}(append to /root/.ironclaw/reborn/config.toml, then ${BGN}ironclaw service restart${CL}):${CL}"
echo -e "${TAB}${TAB}${TAB}${BGN}[webui]${CL}"
echo -e "${TAB}${TAB}${TAB}${BGN}listen_host = \"0.0.0.0\"${CL}"
echo -e "${TAB}3. Access the Web UI at:${CL}"
echo -e "${TAB}${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
echo -e "${INFO}${YW} Log in with the WebUI token (URL: http://${IP}:3000/login?token=<token>):${CL}"
echo -e "${TAB}${TAB}${BGN}cat /root/.ironclaw/reborn/webui-token${CL}"
