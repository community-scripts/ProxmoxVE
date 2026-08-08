#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/portainer/portainer
if ! command -v curl &>/dev/null; then
  printf "\r\e[2K%b" '\033[93m Setup Source \033[m' >&2
  apt-get update >/dev/null 2>&1
  apt-get install -y curl >/dev/null 2>&1
fi
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "portainer" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# ==============================================================================
# CONFIGURATION
# ==============================================================================
APP="Portainer"
APP_TYPE="addon"
INSTALL_PATH="/opt/portainer"
COMPOSE_FILE="${INSTALL_PATH}/compose.yaml"
DEFAULT_PORT=9443
PORTAINER_IMAGE=""
COMPOSE_WORKDIR=""
COMPOSE_SERVICE=""
COMPOSE_CONFIG_FILES=""

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "Uninstalling ${APP}"

  if [[ -f "$COMPOSE_FILE" ]]; then
    msg_info "Stopping and removing Docker containers"
    cd "$INSTALL_PATH"
    $STD docker compose down --volumes --remove-orphans
    msg_ok "Stopped and removed Docker containers"
  fi

  rm -rf "$INSTALL_PATH"
  rm -f "/usr/local/bin/update_portainer"
  msg_ok "${APP} has been uninstalled"
}

# ==============================================================================
# UPDATE SCRIPT HELPER
# ==============================================================================
function ensure_update_script() {
  [[ -f /usr/local/bin/update_portainer ]] && return 0

  msg_info "Creating update script"
  cat <<'UPDATEEOF' >/usr/local/bin/update_portainer
#!/usr/bin/env bash
# Portainer Update Script
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/portainer.sh)"
UPDATEEOF
  chmod +x /usr/local/bin/update_portainer
  msg_ok "Created update script (/usr/local/bin/update_portainer)"
}

# ==============================================================================
# DETECT EXISTING INSTALLATION
# ==============================================================================
function detect_portainer() {
  PORTAINER_IMAGE=""
  COMPOSE_WORKDIR=""
  COMPOSE_SERVICE=""
  COMPOSE_CONFIG_FILES=""

  if ! docker container inspect portainer &>/dev/null; then
    return 0
  fi

  PORTAINER_IMAGE=$(docker inspect portainer --format '{{.Config.Image}}')
  if [[ ! "$PORTAINER_IMAGE" =~ (^|/)portainer-(ce|ee)(:|@) ]]; then
    msg_error "A container named 'portainer' exists but does not use an official Portainer CE or BE image."
    exit 10
  fi

  COMPOSE_WORKDIR=$(docker inspect portainer --format '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' 2>/dev/null || true)
  COMPOSE_SERVICE=$(docker inspect portainer --format '{{index .Config.Labels "com.docker.compose.service"}}' 2>/dev/null || true)
  COMPOSE_CONFIG_FILES=$(docker inspect portainer --format '{{index .Config.Labels "com.docker.compose.project.config_files"}}' 2>/dev/null || true)
  if [[ "$COMPOSE_WORKDIR" == "<no value>" ]]; then
    COMPOSE_WORKDIR=""
  fi
  if [[ "$COMPOSE_SERVICE" == "<no value>" ]]; then
    COMPOSE_SERVICE=""
  fi
  if [[ "$COMPOSE_CONFIG_FILES" == "<no value>" ]]; then
    COMPOSE_CONFIG_FILES=""
  fi
  return 0
}

# ==============================================================================
# UPDATE COMPOSE INSTALLATION
# ==============================================================================
function update_compose() {
  local workdir="$1"
  local service="$2"
  local config_files="$3"
  local config
  local -a configs=()
  local -a compose_args=()

  if [[ -n "$config_files" ]]; then
    IFS=',' read -ra configs <<<"$config_files"
    for config in "${configs[@]}"; do
      compose_args+=(--file "$config")
    done
  fi

  msg_info "Pulling latest ${APP} image"
  if [[ -n "$service" ]]; then
    (cd "$workdir" && $STD docker compose "${compose_args[@]}" pull "$service")
  else
    (cd "$workdir" && $STD docker compose pull)
  fi
  msg_ok "Pulled latest image"

  msg_info "Restarting ${APP}"
  if [[ -n "$service" ]]; then
    (cd "$workdir" && $STD docker compose "${compose_args[@]}" up -d "$service")
  else
    (cd "$workdir" && $STD docker compose up -d --remove-orphans)
  fi
  msg_ok "Restarted ${APP}"
}

# ==============================================================================
# UPDATE STANDALONE INSTALLATION
# ==============================================================================
function update_standalone() {
  local old_image_id latest_image_id restart_name restart_max network_mode container_port host_ip host_port source destination mode writable
  local was_running privileged user
  local -a run_args=(-d --name portainer)
  local -a command=()

  old_image_id=$(docker inspect portainer --format '{{.Image}}')
  was_running=$(docker inspect portainer --format '{{.State.Running}}')
  restart_name=$(docker inspect portainer --format '{{.HostConfig.RestartPolicy.Name}}')
  restart_max=$(docker inspect portainer --format '{{.HostConfig.RestartPolicy.MaximumRetryCount}}')
  network_mode=$(docker inspect portainer --format '{{.HostConfig.NetworkMode}}')
  privileged=$(docker inspect portainer --format '{{.HostConfig.Privileged}}')
  user=$(docker inspect portainer --format '{{.Config.User}}')

  if [[ -n "$restart_name" && "$restart_name" != "no" ]]; then
    if [[ "$restart_name" == "on-failure" && "$restart_max" -gt 0 ]]; then
      run_args+=(--restart "${restart_name}:${restart_max}")
    else
      run_args+=(--restart "$restart_name")
    fi
  fi
  [[ "$network_mode" != "default" ]] && run_args+=(--network "$network_mode")
  [[ "$privileged" == "true" ]] && run_args+=(--privileged)
  [[ -n "$user" ]] && run_args+=(--user "$user")

  while IFS='|' read -r container_port host_ip host_port; do
    [[ -z "$container_port" || -z "$host_port" ]] && continue
    [[ "$host_ip" == *:* ]] && host_ip="[${host_ip}]"
    if [[ -n "$host_ip" && "$host_ip" != "0.0.0.0" ]]; then
      run_args+=(-p "${host_ip}:${host_port}:${container_port}")
    else
      run_args+=(-p "${host_port}:${container_port}")
    fi
  done < <(docker inspect portainer --format '{{range $port, $bindings := .HostConfig.PortBindings}}{{range $bindings}}{{printf "%s|%s|%s\n" $port .HostIp .HostPort}}{{end}}{{end}}')

  while IFS='|' read -r source destination mode writable; do
    [[ -z "$source" || -z "$destination" ]] && continue
    if [[ "$writable" == "false" ]]; then
      mode="${mode:+${mode},}ro"
    fi
    run_args+=(-v "${source}:${destination}${mode:+:${mode}}")
  done < <(docker inspect portainer --format '{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}}{{else}}{{.Source}}{{end}}|{{.Destination}}|{{.Mode}}|{{.RW}}{{println}}{{end}}')

  while IFS= read -r environment; do
    [[ -n "$environment" ]] && run_args+=(-e "$environment")
  done < <(docker inspect portainer --format '{{range .Config.Env}}{{println .}}{{end}}')

  while IFS= read -r argument; do
    [[ -n "$argument" ]] && command+=("$argument")
  done < <(docker inspect portainer --format '{{range .Config.Cmd}}{{println .}}{{end}}')

  msg_info "Pulling latest ${APP} image"
  $STD docker pull "$PORTAINER_IMAGE"
  latest_image_id=$(docker image inspect "$PORTAINER_IMAGE" --format '{{.Id}}')
  msg_ok "Pulled latest image"

  if [[ "$old_image_id" == "$latest_image_id" ]]; then
    msg_ok "${APP} is already up to date"
    return 0
  fi

  msg_info "Recreating ${APP}"
  [[ "$was_running" == "true" ]] && $STD docker stop portainer
  $STD docker rm portainer
  if ! $STD docker run "${run_args[@]}" "$PORTAINER_IMAGE" "${command[@]}"; then
    msg_warn "Update failed, restoring the previous ${APP} image"
    docker rm -f portainer &>/dev/null || true
    if $STD docker run "${run_args[@]}" "$old_image_id" "${command[@]}"; then
      [[ "$was_running" != "true" ]] && $STD docker stop portainer
      msg_error "Failed to update ${APP}; restored the previous container."
    else
      msg_error "Failed to update or restore ${APP}."
    fi
    exit 10
  fi
  msg_ok "Recreated ${APP}"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  if [[ -f "$COMPOSE_FILE" ]]; then
    update_compose "$INSTALL_PATH" "" ""
  elif [[ -n "$COMPOSE_WORKDIR" && -n "$COMPOSE_SERVICE" && -d "$COMPOSE_WORKDIR" ]]; then
    update_compose "$COMPOSE_WORKDIR" "$COMPOSE_SERVICE" "$COMPOSE_CONFIG_FILES"
  else
    update_standalone
  fi

  ensure_update_script

  msg_ok "Updated successfully"
  exit
}

# ==============================================================================
# CHECK DOCKER
# ==============================================================================
function check_docker() {
  if ! command -v docker &>/dev/null; then
    msg_error "Docker is not installed. This script requires an existing Docker LXC. Exiting."
    exit 10
  fi
  if ! docker compose version &>/dev/null; then
    msg_error "Docker Compose plugin is not available. Please install it before running this script. Exiting."
    exit 10
  fi
  msg_ok "Docker $(docker --version | cut -d' ' -f3 | tr -d ',') and Docker Compose are available"
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  check_docker
  detect_portainer
  if [[ -n "$PORTAINER_IMAGE" ]]; then
    msg_error "${APP} is already installed."
    exit 10
  fi

  msg_info "Creating install directory"
  mkdir -p "$INSTALL_PATH"
  msg_ok "Created ${INSTALL_PATH}"

  msg_info "Downloading Docker Compose file"
  curl -fsSL "https://downloads.portainer.io/ce-sts/portainer-compose.yaml" -o "$COMPOSE_FILE"
  msg_ok "Downloaded Docker Compose file"

  msg_info "Starting ${APP}"
  cd "$INSTALL_PATH"
  $STD docker compose up -d
  msg_ok "Started ${APP}"

  ensure_update_script

  echo ""
  msg_ok "${APP} is reachable at: ${BL}https://${LOCAL_IP}:${DEFAULT_PORT}${CL}"
  echo ""
  msg_warn "On first access, you'll be prompted to create an admin account."
}

# ==============================================================================
# MAIN
# ==============================================================================

# Handle type=update (called from update script)
if [[ "${type:-}" == "update" ]]; then
  header_info
  check_docker
  detect_portainer
  if [[ -f "$COMPOSE_FILE" || -n "$PORTAINER_IMAGE" ]]; then
    update
  else
    msg_error "${APP} is not installed. Nothing to update."
    exit 233
  fi
  exit 0
fi

header_info
get_lxc_ip

check_docker
detect_portainer

# Check if already installed
if [[ -f "$COMPOSE_FILE" || -n "$PORTAINER_IMAGE" ]]; then
  msg_warn "${APP} is already installed."
  echo ""

  if [[ -f "$COMPOSE_FILE" ]]; then
    echo -n "${TAB}Uninstall ${APP}? (y/N): "
    read -r uninstall_prompt
    if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
      uninstall
      exit 0
    fi
  fi

  echo -n "${TAB}Update ${APP}? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    update
    exit 0
  fi

  msg_warn "No action selected. Exiting."
  exit 0
fi

# Fresh installation
msg_warn "${APP} is not installed."
echo ""
echo -e "${TAB}${INFO} This will install:"
echo -e "${TAB}  - Portainer (via Docker Compose)"
echo ""

echo -n "${TAB}Install ${APP}? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "Installation cancelled. Exiting."
  exit 0
fi
