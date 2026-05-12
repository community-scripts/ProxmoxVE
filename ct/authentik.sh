#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Thieneret
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/goauthentik/authentik

APP="authentik"
var_tags="${var_tags:-auth}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
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

  if [[ ! -d /opt/authentik ]]; then
    msg_error "No authentik Installation Found!"
    exit
  fi

  NODE_VERSION="24" setup_nodejs
  setup_go
  UV_PYTHON_INSTALL_DIR="/usr/local/bin" PYTHON_VERSION="3.14.3" setup_uv
  setup_rust

  AUTHENTIK_VERSION="version/2026.2.2"
  XMLSEC_VERSION="1.3.11"

  if check_for_gh_release "geoipupdate" "maxmind/geoipupdate"; then
    fetch_and_deploy_gh_release "geoipupdate" "maxmind/geoipupdate" "binary"
  fi

  if check_for_gh_release "xmlsec" "lsh123/xmlsec" "${XMLSEC_VERSION}"; then
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "xmlsec" "lsh123/xmlsec" "tarball" "${XMLSEC_VERSION}" "/opt/xmlsec"

    msg_info "Updating xmlsec"
    cd /opt/xmlsec
    $STD ./autogen.sh
    $STD make -j $(nproc)
    $STD make check
    $STD make install
    $STD ldconfig
    msg_ok "Updated xmlsec"
  fi

  if check_for_gh_release "authentik" "goauthentik/authentik" "${AUTHENTIK_VERSION}"; then
    msg_info "Stopping Services"
    systemctl stop authentik-server authentik-worker
	if [[ $(systemctl is-active authentik-ldap) == active ]]; then
		systemctl stop authentik-ldap
	fi
	if [[ $(systemctl is-active authentik-rac) == active ]]; then
		systemctl stop authentik-rac
	fi
	if [[ $(systemctl is-active authentik-radius) == active ]]; then
		systemctl stop authentik-radius
	fi
    msg_ok "Stopped Services"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "authentik" "goauthentik/authentik" "tarball" "${AUTHENTIK_VERSION}" "/opt/authentik"

    msg_info "Updating web"
    cd /opt/authentik/web
    export NODE_ENV="production"
    $STD npm install
    $STD npm run build
    $STD npm run build:sfe
    msg_ok "Updated web"

    msg_info "Updating go proxy"
    cd /opt/authentik
    export CGO_ENABLED="1"
    $STD go mod download
    $STD go build -o /opt/authentik/authentik-server ./cmd/server
	$STD go build -o /opt/authentik/ldap ./cmd/ldap
	$STD go build -o /opt/authentik/rac ./cmd/rac
	$STD go build -o /opt/authentik/radius ./cmd/radius
    msg_ok "Updated go proxy"

    msg_info "Updating python server"
    export UV_NO_BINARY_PACKAGE="cryptography lxml python-kadmin-rs xmlsec"
    export UV_COMPILE_BYTECODE="1"
    export UV_LINK_MODE="copy"
    export UV_NATIVE_TLS="1"
    export RUSTUP_PERMIT_COPY_RENAME="true"
    export UV_PYTHON_INSTALL_DIR="/usr/local/bin"
    cd /opt/authentik
    $STD uv sync --frozen --no-install-project --no-dev
    chown -R authentik:authentik /opt/authentik
    msg_ok "Updated python server"
  fi

  msg_info "Starting Services"
  systemctl start authentik-server authentik-worker
  if [[ $(systemctl is-enabled authentik-ldap) == enabled ]]; then
  	systemctl start authentik-ldap
  fi
  if [[ $(systemctl is-enabled authentik-rac) == enabled ]]; then
  	systemctl start authentik-rac
  fi
  if [[ $(systemctl is-enabled authentik-radius) == enabled ]]; then
  	systemctl start authentik-radius
  fi
  msg_ok "Started Services"
  msg_ok "Updated successfully!"
  exit
}

start
build_container

msg_info "Attaching data storage volume"
$STD pct stop "$CTID"
if [ "${PROTECT_CT:-}" == "1" ] || [ "${PROTECT_CT:-}" == "yes" ]; then
  $STD pct set "$CTID" --protection 0
  $STD pct set "$CTID" -mp0 "${CONTAINER_STORAGE}":1,mp=/opt/authentik-data,backup=1
  $STD pct set "$CTID" --protection 1
else
  $STD pct set "$CTID" -mp0 "${CONTAINER_STORAGE}":1,mp=/opt/authentik-data,backup=1
fi
$STD pct start "$CTID"
for i in {1..10}; do
  pct status "$CTID" | grep -q "status: running" && break
  sleep 1
done
$STD pct exec "$CTID" -- bash -c "mkdir -p /opt/authentik-data/{certs,media,geoip,templates}; \
  cp /opt/authentik/tests/GeoLite2-ASN-Test.mmdb /opt/authentik-data/geoip/GeoLite2-ASN.mmdb; \
  cp /opt/authentik/tests/GeoLite2-City-Test.mmdb /opt/authentik-data/geoip/GeoLite2-City.mmdb; \
  chown authentik:authentik /opt/authentik-data; \
  chown -R authentik:authentik /opt/authentik-data/{certs,media,geoip,templates}"
msg_ok "Attached data storage volume"

msg_info "Starting Services"
pct exec "$CTID" -- systemctl enable -q --now authentik-server authentik-worker
msg_ok "Started Services"

description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Initial setup URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9000/if/flow/initial-setup/${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9000${CL}"
