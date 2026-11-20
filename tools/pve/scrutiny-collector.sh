#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/AnalogJ/scrutiny

source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/core.func")
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/api/api.func") 2>/dev/null || true
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/lib/tools.func")
load_functions
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "scrutiny-collector" "pve"

set -Eeuo pipefail

APP="Scrutiny-Collector"
APP_TYPE="tools"
BIN="/usr/local/bin/scrutiny-collector-metrics"
CONFIG_DIR="/etc/scrutiny"
CONFIG="${CONFIG_DIR}/collector.yaml"
SERVICE="scrutiny-collector"
REPO="AnalogJ/scrutiny"

header_info

if [[ "$(id -u)" -ne 0 ]]; then
  msg_error "Run this as root (sudo) on the machine that has the disks."
  exit 1
fi
if systemd-detect-virt -cq 2>/dev/null; then
  msg_warn "This looks like a container: only disks passed through to it can be read."
fi
if ! command -v apt &>/dev/null; then
  msg_error "This tool needs a Debian or Ubuntu based host (apt)."
  exit 1
fi
command -v whiptail &>/dev/null || $STD apt install -y whiptail

function deploy_binary() {
  fetch_and_deploy_gh_release "scrutiny-collector-metrics" "$REPO" "singlefile" "latest" "/usr/local/bin" "scrutiny-collector-metrics-linux-$(arch_resolve "amd64" "arm64")"
  # Only catch_errors' on_exit clears this marker, and tools run without it.
  rm -f ~/.scrutiny-collector-metrics.pending
}

function install_collector() {
  local url="${var_scrutiny_url:-}"
  while true; do
    if [[ -z "$url" ]]; then
      url=$(whiptail --backtitle "Community Scripts" --title "Scrutiny URL" \
        --inputbox "URL of your Scrutiny web UI, e.g. http://192.168.1.50:8080" 10 64 "" 3>&1 1>&2 2>&3)
    fi
    url="${url%/}"
    [[ "$url" =~ ^https?://[A-Za-z0-9._-]+(:[0-9]{1,5})?(/.*)?$ ]] && break
    whiptail --backtitle "Community Scripts" --title "Scrutiny URL" \
      --msgbox "'${url}' is not a valid URL. Use http(s)://host:port" 8 64
    url=""
  done

  if ! curl -fsS --max-time 5 "${url}/api/health" &>/dev/null; then
    msg_warn "Scrutiny does not answer at ${url}/api/health yet; the collector will retry every 15 minutes."
  fi

  msg_info "Installing smartmontools"
  $STD apt install -y smartmontools
  msg_ok "Installed smartmontools"

  deploy_binary

  msg_info "Configuring ${APP}"
  mkdir -p "$CONFIG_DIR"
  cat <<EOF >"$CONFIG"
version: 1
host:
  id: "$(hostname)"
api:
  endpoint: "${url}"
EOF
  cat <<EOF >/etc/systemd/system/${SERVICE}.service
[Unit]
Description=Scrutiny S.M.A.R.T. collector
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=${BIN} run --config ${CONFIG}
EOF
  cat <<EOF >/etc/systemd/system/${SERVICE}.timer
[Unit]
Description=Run the Scrutiny collector every 15 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=15min
Persistent=true

[Install]
WantedBy=timers.target
EOF
  systemctl daemon-reload
  systemctl enable -q --now ${SERVICE}.timer
  systemctl start --no-block ${SERVICE}.service
  msg_ok "Configured ${APP}"

  echo ""
  msg_ok "The disks of $(hostname) show up in Scrutiny at ${BL}${url}${CL} after the first run."
  msg_ok "Follow it with: ${BL}journalctl -u ${SERVICE} -f${CL}"
}

function update_collector() {
  if check_for_gh_release "scrutiny-collector-metrics" "$REPO"; then
    deploy_binary
    msg_ok "Updated ${APP}"
  else
    msg_ok "${APP} is already up-to-date"
  fi
}

function uninstall_collector() {
  msg_info "Removing ${APP}"
  systemctl disable -q --now ${SERVICE}.timer 2>/dev/null || true
  systemctl stop ${SERVICE}.service 2>/dev/null || true
  rm -f /etc/systemd/system/${SERVICE}.service /etc/systemd/system/${SERVICE}.timer "$BIN" ~/.scrutiny-collector-metrics
  rm -rf "$CONFIG_DIR"
  systemctl daemon-reload
  msg_ok "Removed ${APP} (smartmontools stays installed)"
}

ACTION="${1:-}"
if [[ -z "$ACTION" && -x "$BIN" ]]; then
  ACTION=$(whiptail --backtitle "Community Scripts" --title "${APP}" \
    --menu "The Scrutiny collector is installed on this host." 12 58 2 \
    "update" "Update the collector binary" \
    "uninstall" "Remove the collector" 3>&1 1>&2 2>&3)
fi

case "${ACTION:-install}" in
install) install_collector ;;
update) update_collector ;;
uninstall) uninstall_collector ;;
*)
  msg_error "Unknown action '${ACTION}'. Use install, update or uninstall."
  exit 1
  ;;
esac
