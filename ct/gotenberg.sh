#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/gotenberg/gotenberg

APP="Gotenberg"
var_tags="${var_tags:-document;pdf}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-15}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /etc/systemd/system/gotenberg.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "gotenberg" "gotenberg/gotenberg"; then
    msg_info "Stopping Service"
    systemctl stop gotenberg
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "gotenberg" "gotenberg/gotenberg" "tarball" "latest" "/opt/gotenberg"

    GO_VERSION="$(awk '$1=="go"{print $2}' /opt/gotenberg/go.mod | cut -d. -f1,2)" setup_go

    msg_info "Building gotenberg (Patience)"
    cd /opt/gotenberg
    export CGO_ENABLED=0
    $STD go mod download
    $STD go build -o /usr/local/bin/gotenberg \
      -ldflags "-s -w -X 'github.com/gotenberg/gotenberg/v9/cmd.Version=$(cat ~/.gotenberg)'" \
      cmd/gotenberg/main.go
    msg_ok "Built gotenberg"

    LOK_VERSION="$(awk -F= '/^ARG LOK_VERSION=/{print $2}' /opt/gotenberg/build/Dockerfile)"
    fetch_and_deploy_gh_release "lok" "gotenberg/lok" "prebuild" "$LOK_VERSION" "/usr/local/bin" "lok_${LOK_VERSION#v}_linux_$(arch_resolve "amd64" "arm64").tar.gz"

    msg_info "Migrating to Gotenberg 9"
    CODENAME=$(get_os_info codename)
    setup_deb822_repo \
      "debian-backports" \
      "file:///usr/share/keyrings/debian-archive-keyring.gpg" \
      "http://deb.debian.org/debian" \
      "${CODENAME}-backports" \
      "main"
    $STD apt install -y fonts-urw-base35
    $STD apt install -y -t "${CODENAME}-backports" \
      libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-draw libreoffice-math
    $STD apt purge -y python3-uno python-is-python3 pdftk-java qpdf libimage-exiftool-perl
    $STD apt autoremove -y
    rm -rf /usr/local/bin/unoconverter /usr/local/bin/pdfcpu /opt/pdfcpu
    sed -i '/^Environment=\(UNOCONVERTER\|PDFTK\|QPDF\|EXIFTOOL\|PDFCPU\)_BIN_PATH=/d' /etc/systemd/system/gotenberg.service
    grep -q '^Environment=LOK_BIN_PATH=' /etc/systemd/system/gotenberg.service ||
      sed -i '/^Environment=LIBREOFFICE_BIN_PATH=/a Environment=LOK_BIN_PATH=/usr/local/bin/lok' /etc/systemd/system/gotenberg.service
    systemctl daemon-reload
    msg_ok "Migrated to Gotenberg 9"

    msg_info "Starting Service"
    systemctl start gotenberg
    msg_ok "Started Service"
    msg_ok "Updated Successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Gotenberg is a stateless API and has no web interface.${CL}"
echo -e "${INFO}${YW}Check the health endpoint using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000/health${CL}"
