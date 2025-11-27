#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: community-scripts
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rommapp/romm

APP="ROMM"
var_tags="${var_tags:-gaming;media;roms}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

# Override for testing from fork
INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/onionrings29/ProxmoxVE/claude/dockerfile-ubuntu-setup-01Abox2T6edmGTHazHrG3QFw/install/romm-install.sh"

# Save original build_container function
eval "original_$(declare -f build_container)"

# Override build_container to use custom install script URL
build_container() {
  # Call original function but override the var_install behavior
  export INSTALL_SCRIPT_URL
  # Temporarily modify var_install to trigger our custom download
  original_build_container_impl() {
    # This wraps the original, replacing the install script download
    original_build_container "$@"
  }

  # Execute the original but with lxc-attach pointing to our fork
  TEMP_DIR=$(mktemp -d)
  pushd "$TEMP_DIR" >/dev/null
  if [ "$var_os" == "alpine" ]; then
    export FUNCTIONS_FILE_PATH="$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/alpine-install.func)"
  else
    export FUNCTIONS_FILE_PATH="$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/install.func)"
  fi

  export DIAGNOSTICS="$DIAGNOSTICS"
  export RANDOM_UUID="$RANDOM_UUID"
  export CACHER="$APT_CACHER"
  export CACHER_IP="$APT_CACHER_IP"
  export tz="${timezone:-Etc/UTC}"
  export APPLICATION="$APP"
  export app="$NSAPP"
  export PASSWORD="$PW"
  export VERBOSE="$VERBOSE"
  export SSH_ROOT="${SSH}"
  export SSH_AUTHORIZED_KEY
  export CTID="$CT_ID"
  export CTTYPE="$CT_TYPE"
  export ENABLE_FUSE="$ENABLE_FUSE"
  export ENABLE_TUN="$ENABLE_TUN"
  export PCT_OSTYPE="$var_os"
  export PCT_OSVERSION="$var_version"
  export PCT_DISK_SIZE="$DISK_SIZE"

  # Build NET_STRING for network configuration
  NET_STRING="-net0 name=eth0,bridge=$BRG$MAC,ip=$NET$GATE$VLAN$MTU"
  if [ "$CT_TYPE" == "1" ]; then
    FEATURES="keyctl=1,nesting=1"
  else
    FEATURES="nesting=1"
  fi
  if [ "$ENABLE_FUSE" == "yes" ]; then
    FEATURES="$FEATURES,fuse=1"
  fi

  export PCT_OPTIONS="
    -features $FEATURES
    -hostname $HN
    -tags $TAGS
    $SD
    $NS
    $NET_STRING
    -onboot 1
    -cores $CORE_COUNT
    -memory $RAM_SIZE
    -unprivileged $CT_TYPE
    $PW
  "

  # Create container
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/create_lxc.sh)" $?

  msg_info "Starting LXC Container"
  pct start "$CTID"

  # Wait for container to be running
  for i in {1..10}; do
    if pct status "$CTID" | grep -q "status: running"; then
      msg_ok "Started LXC Container"
      break
    fi
    sleep 1
    if [ "$i" -eq 10 ]; then
      msg_error "LXC Container did not reach running state"
      exit 1
    fi
  done

  # Customize container (minimal version)
  msg_info "Customizing LXC Container"
  if [ "$var_os" != "alpine" ]; then
    sleep 3
    pct exec "$CTID" -- bash -c "apt-get update >/dev/null && apt-get install -y sudo curl >/dev/null"
  fi
  msg_ok "Customized LXC Container"

  # Use our custom install script URL instead of the default
  lxc-attach -n "$CTID" -- bash -c "$(curl -fsSL $INSTALL_SCRIPT_URL)"

  popd >/dev/null
  rm -rf "$TEMP_DIR"
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/romm ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping Service"
  systemctl stop romm
  msg_ok "Stopped Service"

  msg_info "Updating ${APP}"
  cd /opt/romm
  git pull origin main
  msg_ok "Updated Repository"

  msg_info "Updating Python Dependencies"
  /usr/local/bin/uv sync --all-extras
  msg_ok "Updated Python Dependencies"

  msg_info "Updating Frontend Dependencies"
  cd /opt/romm/frontend
  $STD npm install
  msg_ok "Updated Frontend Dependencies"

  msg_info "Starting Service"
  systemctl start romm
  msg_ok "Started Service"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
