#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Thieneret
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/goauthentik/authentik

APP="authentik"
var_tags="${var_tags:-auth}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-16}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
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

  read -r MAJOR MINOR PATCH <<<"$(sed 's/^version\///; s/\./ /g' "$HOME/.authentik")"

  if [[ $MAJOR == 2026 && $MINOR -lt 5 ]]; then
	msg_error "Updating from version ${MAJOR}.${MINOR}.${PATCH} is not supported. A minimum version of 2026.5.x is required to update. See: https://docs.goauthentik.io/releases/2026.8/"
	exit
  fi

  msg_info "Update dependencies"
  ensure_dependencies crossbuild-essential-$(arch_resolve) gcc-$(arch_resolve "x86-64" "aarch64")-linux-gnu cmake clang libunwind-18-dev
  msg_ok "Update dependencies"

  NODE_VERSION="26" NODE_MODULE=pnpm@11 setup_nodejs
  $STD uv cache clean
  UV_PYTHON_INSTALL_DIR="/usr/local/bin" PYTHON_VERSION="3.14.7" setup_uv
  RUST_PROFILE="minimal" RUST_TOOLCHAIN="stable" setup_rust
  setup_yq

  AUTHENTIK_VERSION="version/2026.8.1"
  # Source: https://github.com/goauthentik/fips/blob/main/Makefile#L26
  XMLSEC_VERSION="1.3.12"

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

    if [[ ! -d /opt/authentik-data/blueprints ]]; then
      msg_info "Moving blueprints to presistent directory"
      cp -r /opt/authentik/blueprints /opt/authentik-data/
      rm -r /opt/authentik/blueprints
      chown -Rf authentik:authentik /opt/authentik-data
      yq -i ".blueprints_dir = \"/opt/authentik-data/blueprints\"" /etc/authentik/config.yml
      msg_ok "blueprints moved to presistent directory"
      msg_warn "The blueprints provided by authentik are always overwritten when updated! Only manually created custom blueprints remain unchanged between updates."
    fi

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "authentik" "goauthentik/authentik" "tarball" "${AUTHENTIK_VERSION}" "/opt/authentik"
    GO_VERSION="$(grep -m1 '^go ' /opt/authentik/go.mod | awk '{print $2}')" setup_go

    msg_info "Configuring rust"
    cd /opt/authentik
    $STD rustup install
    $STD rustup default "$(sed -n 's/channel = "\(.*\)"/\1/p' rust-toolchain.toml)"
    msg_ok "Configured rust"

    msg_info "Updating web"
    export NODE_ENV="production"
	  cd /opt/authentik
	  $STD node ./scripts/node/lint-runtime.mjs ./web
	  cd /opt/authentik/web
	  $STD pnpm install --frozen-lockfile
	  $STD pnpm run build
	  $STD pnpm run build:sfe
    msg_ok "Updated web"

    msg_info "Updating outposts"
    cd /opt/authentik
	  mkdir -p /opt/authentik/bin
    export CGO_ENABLED="1"
    export CC="$(arch_resolve "x86_64" "aarch64")-linux-gnu-gcc"
    $STD go mod download
    $STD go build -o /opt/authentik/bin/ldap ./cmd/ldap
    $STD go build -o /opt/authentik/bin/rac ./cmd/rac
    $STD go build -o /opt/authentik/bin/radius ./cmd/radius
    msg_ok "Updated outposts"

    msg_info "Building binary. It may take more than 10 minutes, please be patient."
	  export AWS_LC_FIPS_SYS_CC="clang"
	  cd /opt/authentik
	  $STD cargo build --package authentik --no-default-features --features core --locked --release
	  cp ./target/release/authentik /opt/authentik/bin/
	  rm -r ./target
    msg_ok "Built worker"

    msg_info "Updating python server"
    export UV_NO_BINARY_PACKAGE="cryptography lxml python-kadmin-rs xmlsec"
    export UV_COMPILE_BYTECODE="1"
    export UV_LINK_MODE="copy"
    export UV_NATIVE_TLS="1"
    export UV_HTTP_TIMEOUT="300"
    export RUSTUP_PERMIT_COPY_RENAME="true"
    export UV_PYTHON_INSTALL_DIR="/usr/local/bin"
    cd /opt/authentik
    for attempt in 1 2 3; do
      if [[ $attempt -eq 3 ]]; then
        $STD uv sync --locked --no-install-project --no-dev
        break
      fi
      $STD uv sync --locked --no-install-project --no-dev && break
      msg_warn "uv sync attempt $attempt failed, retrying..."
      sleep $((attempt * 15))
    done
    chown -R authentik:authentik /opt/authentik
    msg_ok "Updated python server"

    cp -r /opt/authentik/blueprints /opt/authentik-data/
    rm -r /opt/authentik/blueprints
    chown -Rf authentik:authentik /opt/authentik-data
    
    if [[ $MAJOR == 2026 && $MINOR -lt 8 ]]; then
	    msg_info "Updating Worker and Server config (from $MAJOR.$MINOR)"
      cat <<EOF >>/etc/default/authentik-server
RUST_BACKTRACE=full
EOF
      cat <<EOF >>/etc/default/authentik-worker
RUST_BACKTRACE=full
EOF
      msg_ok "Updated Worker and Server config (from $MAJOR.$MINOR)"

      msg_info "Updating services (from $MAJOR.$MINOR)"
	    sed -i "s|ExecStart=/opt/authentik/authentik-server|ExecStart=/opt/authentik/bin/authentik server|g" /etc/systemd/system/authentik-server.service
	    sed -i "s|ExecStart=/opt/authentik/authentik-worker worker|ExecStart=/opt/authentik/bin/authentik worker|g" /etc/systemd/system/authentik-worker.service
	    sed -i "s|ExecStart=/opt/authentik/ldap|ExecStart=/opt/authentik/bin/ldap|g" /etc/systemd/system/authentik-ldap.service
	    sed -i "s|ExecStart=/opt/authentik/radius|ExecStart=/opt/authentik/bin/radius|g" /etc/systemd/system/authentik-radius.service
	    sed -i "s|ExecStart=/opt/authentik/rac|ExecStart=/opt/authentik/bin/rac|g" /etc/systemd/system/authentik-rac.service
      systemctl daemon-reload
      msg_ok "Updated services (from $MAJOR.$MINOR)"
    fi

    msg_info "Updating Worker and Server config"
    sed -i "s|/dev/shm$|/dev/shm/authentik-server|g" /etc/default/authentik-server
	  sed -i "s|/dev/shm$|/dev/shm/authentik-worker|g" /etc/default/authentik-worker
    msg_ok "Updated Worker and Server config"

    msg_info "Updating services"
    sed -i 's/authentik Go Server (API Gateway)/authentik Server/g' /etc/systemd/system/authentik-server.service
	  sed -i '/ExecStart=/i ExecStartPre=/usr/bin/mkdir -p "${TMPDIR}"' /etc/systemd/system/authentik-server.service
    sed -i '/ExecStart=/i ExecStartPre=/usr/bin/mkdir -p "${TMPDIR}"' /etc/systemd/system/authentik-worker.service
    systemctl daemon-reload
    msg_ok "Updated services"

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
  fi
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
  cp -r /opt/authentik/blueprints /opt/authentik-data/; \
  rm -r /opt/authentik/blueprints; \
  chown -Rf authentik:authentik /opt/authentik-data"
msg_ok "Attached data storage volume"

msg_info "Starting Services"
pct exec "$CTID" -- systemctl enable -q --now authentik-server authentik-worker
msg_ok "Started Services"

description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}https://${IP}:9443${CL}"
