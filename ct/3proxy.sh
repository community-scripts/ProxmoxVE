#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Arm (Sub-Creator)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/3proxy/3proxy

APP="3proxy"
var_tags="${var_tags:-proxy}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/3proxy/3proxy.cfg ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # 3proxy does not use gh-release versioned filenames; we have to look up the
  # latest release ourselves and pull the matching .deb for the current arch.
  RELEASE=$(get_latest_github_release "3proxy/3proxy")
  ARCH=$(dpkg --print-architecture)
  case "$ARCH" in
    amd64) DEB_FILE="3proxy-${RELEASE}.x86_64.deb" ;;
    arm64) DEB_FILE="3proxy-${RELEASE}.arm64.deb" ;;
    armhf) DEB_FILE="3proxy-${RELEASE}.arm.deb"   ;;
    *)
      msg_error "Unsupported architecture: $ARCH"
      exit 1
      ;;
  esac
  DEB_URL="https://github.com/3proxy/3proxy/releases/download/${RELEASE}/${DEB_FILE}"

  if ! dpkg -s 3proxy &>/dev/null; then
    msg_error "3proxy package is not installed (cannot compare versions)"
    exit 1
  fi
  INSTALLED_VERSION=$(dpkg-query -W -f='${Version}' 3proxy 2>/dev/null | cut -d'-' -f1)
  if [[ "${INSTALLED_VERSION}" == "${RELEASE}" ]]; then
    msg_ok "3proxy is already up-to-date (${RELEASE})"
    exit
  fi

  msg_info "Stopping Service"
  systemctl stop 3proxy
  msg_ok "Stopped Service"

  msg_info "Updating 3proxy ${INSTALLED_VERSION} -> ${RELEASE}"
  # Backup user config (apt will leave the .cfg alone, but be safe)
  cp /etc/3proxy/3proxy.cfg /tmp/3proxy.cfg.bak
  cp /etc/3proxy/conf/passwd /tmp/3proxy.passwd.bak
  curl -fsSL -o /tmp/3proxy.deb "$DEB_URL"
  $STD dpkg -i /tmp/3proxy.deb
  rm -f /tmp/3proxy.deb
  # Restore config in case the new .deb overwrote anything
  cp /tmp/3proxy.cfg.bak /etc/3proxy/3proxy.cfg 2>/dev/null || true
  cp /tmp/3proxy.passwd.bak /etc/3proxy/conf/passwd 2>/dev/null || true
  rm -f /tmp/3proxy.cfg.bak /tmp/3proxy.passwd.bak
  msg_ok "Updated 3proxy to ${RELEASE}"

  msg_info "Starting Service"
  systemctl start 3proxy
  msg_ok "Started Service"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access the proxy with the following URL:${CL}"
echo -e "${GATEWAY}${BGN}HTTP  ${IP}:3128${CL}"
echo -e "${GATEWAY}${BGN}SOCKS5 ${IP}:1080${CL}"
echo -e "${INFO}${YW} Credentials are stored at: ${BGN}/root/3proxy.creds${CL}"
echo -e "${INFO}${YW} Config file: ${BGN}/etc/3proxy/3proxy.cfg${CL}"
echo -e "${INFO}${YW} Run 'systemctl status 3proxy' inside the LXC to verify.${CL}"
