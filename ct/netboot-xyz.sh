#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://netboot.xyz

APP="netboot.xyz"
var_tags="${var_tags:-network;pxe;boot}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
NSAPP="netboot-xyz"
var_install="${NSAPP}-install"
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f ~/.netboot-xyz ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "netboot-xyz" "netbootxyz/netboot.xyz"; then
    msg_info "Backing up Configuration"
    cp /var/www/html/boot.cfg /opt/netboot-xyz-boot.cfg.bak
    msg_ok "Backed up Configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "netboot-xyz" "netbootxyz/netboot.xyz" "prebuild" "latest" "/var/www/html" "menus.tar.gz"

    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-efi" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz.efi"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-efi-dsk" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz.efi.dsk"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-snp" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-snp.efi"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-snp-dsk" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-snp.efi.dsk"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-snponly" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-snponly.efi"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-metal" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-metal.efi"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-metal-dsk" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-metal.efi.dsk"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-metal-snp" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-metal-snp.efi"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-metal-snp-dsk" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-metal-snp.efi.dsk"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-metal-snponly" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-metal-snponly.efi"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-kpxe" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz.kpxe"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-undionly" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-undionly.kpxe"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-metal-kpxe" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-metal.kpxe"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-lkrn" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz.lkrn"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-linux-bin" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-linux.bin"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-dsk" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz.dsk"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-pdsk" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz.pdsk"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-arm64" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-arm64.efi"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-arm64-snp" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-arm64-snp.efi"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-arm64-snponly" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-arm64-snponly.efi"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-metal-arm64" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-metal-arm64.efi"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-metal-arm64-snp" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-metal-arm64-snp.efi"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-metal-arm64-snponly" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-metal-arm64-snponly.efi"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-iso" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz.iso"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-img" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz.img"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-arm64-iso" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-arm64.iso"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-arm64-img" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-arm64.img"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-multiarch-iso" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-multiarch.iso"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-multiarch-img" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-multiarch.img"
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "netboot-xyz-checksums" "netbootxyz/netboot.xyz" "singlefile" "latest" "/var/www/html" "netboot.xyz-sha256-checksums.txt"

    msg_info "Restoring Configuration"
    cp /opt/netboot-xyz-boot.cfg.bak /var/www/html/boot.cfg
    rm -f /opt/netboot-xyz-boot.cfg.bak
    msg_ok "Restored Configuration"

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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
