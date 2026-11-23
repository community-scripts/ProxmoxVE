#!/usr/bin/env bash

# community-scripts ORG | wg-easy Addon Installer
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wg-easy/wg-easy

if command -v curl >/dev/null 2>&1; then
  source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/core.func")
  load_functions
elif command -v wget >/dev/null 2>&1; then
  source <(wget -qO- "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/core.func")
  load_functions
fi
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/lib/tools.func")
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/error_handler.func")

color
catch_errors

APP="wg-easy"
APP_TYPE="addon"

header_info "$APP"
require_debian_like
confirm_not_pve_host
get_lxc_ip

function build_wgeasy() {
  cd /opt/wg-easy/src || exit
  $STD pnpm install --frozen-lockfile
  $STD pnpm build
  mkdir -p .output/server/database
  cp -r server/database/migrations .output/server/database/
}

function install_wgeasy() {
  if [[ -d /etc/wgdashboard ]]; then
    msg_error "WGDashboard is installed in this container. wg-easy and WGDashboard would both manage wg0 - install wg-easy in its own LXC."
    exit 1
  fi
  if [[ -f /etc/wireguard/wg0.conf ]]; then
    msg_error "/etc/wireguard/wg0.conf already exists and wg-easy would overwrite it - install wg-easy in its own LXC."
    exit 1
  fi
  if ! ip link add wgeasy-probe type wireguard &>/dev/null; then
    msg_error "wg-easy cannot create a WireGuard interface in this container."
    msg_error "Load the module on the Proxmox VE host: modprobe wireguard && echo wireguard >/etc/modules-load.d/wireguard.conf"
    exit 1
  fi
  ip link del wgeasy-probe

  local MEM_MB
  MEM_MB=$(awk '/MemTotal/ {printf "%.0f", $2/1024}' /proc/meminfo)
  if ((MEM_MB < 2048)); then
    msg_error "Insufficient memory: ${MEM_MB} MB detected. At least 2048 MB RAM is required to build wg-easy."
    exit 1
  fi

  cat <<EOF >/etc/sysctl.d/99-wg-easy.conf
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
EOF
  sysctl -q -p /etc/sysctl.d/99-wg-easy.conf &>/dev/null || true
  if [[ "$(sysctl -n net.ipv4.ip_forward)" != "1" ]]; then
    rm -f /etc/sysctl.d/99-wg-easy.conf
    msg_error "wg-easy needs IP forwarding, but net.ipv4.ip_forward cannot be enabled in this container."
    exit 1
  fi

  local DISABLE_IPV6="false"
  [[ "$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null)" == "0" ]] || DISABLE_IPV6="true"
  if [[ "$(ip route show default | awk '{print $5; exit}')" != "eth0" ]]; then
    msg_warn "The default route is not on eth0 - set the device in wg-easy under Admin > Interface after setup."
  fi

  local WG_HOST ADMIN_PASS
  WG_HOST=$(prompt_input_required "wg-easy endpoint (public DNS name or IP your clients connect to):" "$LOCAL_IP" 120 "var_wg_host")
  [[ "$WG_HOST" == *:* && "$WG_HOST" != \[* ]] && WG_HOST="[${WG_HOST}]"

  msg_info "Installing Dependencies"
  ensure_dependencies wireguard-tools iptables
  msg_ok "Installed Dependencies"

  NODE_VERSION="24" NODE_MODULE="corepack" setup_nodejs
  fetch_and_deploy_gh_release "wg-easy" "wg-easy/wg-easy" "tarball"

  msg_info "Building wg-easy"
  build_wgeasy
  mv /opt/wg-easy/src/.output /opt/wg-easy/app
  msg_ok "Built wg-easy"

  msg_info "Configuring wg-easy"
  ADMIN_PASS=$(random_password)
  cat <<EOF >/opt/wg-easy/.env
PORT=51821
HOST=0.0.0.0
INSECURE=true
DISABLE_IPV6=${DISABLE_IPV6}
DEBUG=Server,WireGuard,Database,CMD,Firewall
INIT_ENABLED=true
INIT_USERNAME=admin
INIT_PASSWORD=${ADMIN_PASS}
INIT_HOST=${WG_HOST}
INIT_PORT=51820
EOF
  chmod 600 /opt/wg-easy/.env
  cat <<'EOF' >/usr/local/bin/wg-easy-cli
#!/usr/bin/env bash
set -a
source /opt/wg-easy/.env
set +a
exec node /opt/wg-easy/app/server/cli.mjs "$@"
EOF
  chmod +x /usr/local/bin/wg-easy-cli
  cat <<EOF >/etc/systemd/system/wg-easy.service
[Unit]
Description=wg-easy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/wg-easy/app
EnvironmentFile=/opt/wg-easy/.env
ExecStart=/usr/bin/node server/index.mjs
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now wg-easy
  msg_ok "Configured wg-easy"

  echo ""
  msg_ok "wg-easy is reachable at: ${BL}http://${LOCAL_IP}:51821${CL}"
  echo -e "${INFO}${YW}Username:${CL} admin"
  echo -e "${INFO}${YW}Password:${CL} ${ADMIN_PASS}"
  echo -e "${INFO}${YW}Clients connect to ${CL}${WG_HOST}:51820/udp${YW} - forward UDP 51820 on your router to ${CL}${LOCAL_IP}${YW}, keep TCP 51821 on the LAN.${CL}"
  if [[ "$WG_HOST" == "$LOCAL_IP" ]]; then
    msg_warn "No public endpoint was set - change the host in wg-easy under Admin > Config before adding clients."
  fi
}

function update_wgeasy() {
  if check_for_gh_release "wg-easy" "wg-easy/wg-easy"; then
    NODE_VERSION="24" NODE_MODULE="corepack" setup_nodejs
    CLEAN_INSTALL=1 CLEAN_INSTALL_KEEP=".env app" fetch_and_deploy_gh_release "wg-easy" "wg-easy/wg-easy" "tarball"

    msg_info "Building wg-easy"
    build_wgeasy
    msg_ok "Built wg-easy"

    # Swapped only after the build: the tunnel stays up meanwhile, so an update run over the VPN does not cut itself off
    msg_info "Restarting wg-easy"
    rm -rf /opt/wg-easy/app
    mv /opt/wg-easy/src/.output /opt/wg-easy/app
    systemctl restart wg-easy
    msg_ok "Restarted wg-easy"
    msg_ok "Updated wg-easy"
  fi
}

function uninstall_wgeasy() {
  msg_info "Uninstalling wg-easy"
  systemctl disable -q --now wg-easy
  wg-quick down wg0 &>/dev/null || true
  rm -f /etc/systemd/system/wg-easy.service /usr/local/bin/wg-easy-cli /etc/sysctl.d/99-wg-easy.conf "$HOME/.wg-easy"
  systemctl daemon-reload
  rm -rf /opt/wg-easy /etc/wireguard/wg-easy.db /etc/wireguard/wg0.conf
  msg_ok "Uninstalled wg-easy"
}

if [[ -f /etc/systemd/system/wg-easy.service ]]; then
  if [[ "${type:-}" == "update" ]]; then
    update_wgeasy
    exit 0
  fi
  read -r -p "${TAB}Update (1), Uninstall (2), Cancel (3)? [1/2/3]: " action || action=""
  action="${action//[[:space:]]/}"
  case "$action" in
  1) update_wgeasy ;;
  2) uninstall_wgeasy ;;
  3) msg_warn "No changes made to wg-easy" ;;
  *) msg_error "Invalid input - no changes made to wg-easy" ;;
  esac
else
  read -r -p "${TAB}Install wg-easy? (y/n): " answer || answer=""
  answer="${answer//[[:space:]]/}"
  if [[ "${answer,,}" =~ ^(y|yes)$ ]]; then
    install_wgeasy
  else
    msg_warn "wg-easy installation skipped"
  fi
fi
