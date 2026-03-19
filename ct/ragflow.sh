#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/infiniflow/ragflow

APP="RAGFlow"
var_tags="${var_tags:-ai;rag;llm;knowledge-base}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-16384}"
var_disk="${var_disk:-50}"
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

  if [[ ! -d /opt/ragflow ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # Function to download RAGFlow directly from GitHub (bypasses API)
  download_ragflow_direct() {
    local target_dir="/opt/ragflow"
    local tmpdir
    tmpdir=$(mktemp -d) || return 1

    # Get latest release tag from GitHub redirects
    local latest_tag=""
    latest_tag=$(curl -fsSLI --connect-timeout 10 --max-time 30 "https://github.com/infiniflow/ragflow/releases/latest" 2>/dev/null | grep -i "location:" | tail -1 | sed 's/.*\/tag\/\([^ ]*\).*/\1/' | tr -d '\r\n')

    if [[ -z "$latest_tag" ]]; then
      msg_warn "Could not determine latest release tag, trying v0.17.0"
      latest_tag="v0.17.0"
    fi

    msg_info "Found RAGFlow release: $latest_tag"

    # Download tarball directly from GitHub
    local tarball_url="https://github.com/infiniflow/ragflow/archive/refs/tags/${latest_tag}.tar.gz"
    local filename="ragflow-${latest_tag}.tar.gz"

    if ! curl -fsSL --connect-timeout 15 --max-time 600 -o "$tmpdir/$filename" "$tarball_url"; then
      msg_error "Failed to download from $tarball_url"
      rm -rf "$tmpdir"
      return 1
    fi

    # Extract
    mkdir -p "$target_dir"
    if [[ "${CLEAN_INSTALL:-0}" == "1" ]]; then
      rm -rf "${target_dir:?}/"*
    fi

    tar --no-same-owner -xzf "$tmpdir/$filename" -C "$tmpdir" || {
      msg_error "Failed to extract tarball"
      rm -rf "$tmpdir"
      return 1
    }

    # Find extracted directory and copy contents
    local unpack_dir
    unpack_dir=$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -n1)

    shopt -s dotglob nullglob
    cp -r "$unpack_dir"/* "$target_dir/"
    shopt -u dotglob nullglob

    # Store version
    local version="${latest_tag#v}"
    echo "$version" > "$HOME/.ragflow"

    rm -rf "$tmpdir"
    return 0
  }

  # Try API-based check first, fall back to direct check
  UPDATE_AVAILABLE=false

  if getent hosts api.github.com >/dev/null 2>&1; then
    if check_for_gh_release "ragflow" "infiniflow/ragflow"; then
      UPDATE_AVAILABLE=true
    fi
  else
    # Direct check: compare current version with latest tag
    local current_version=""
    [[ -f "$HOME/.ragflow" ]] && current_version=$(<"$HOME/.ragflow")

    local latest_tag=""
    latest_tag=$(curl -fsSLI --connect-timeout 10 --max-time 30 "https://github.com/infiniflow/ragflow/releases/latest" 2>/dev/null | grep -i "location:" | tail -1 | sed 's/.*\/tag\/\([^ ]*\).*/\1/' | tr -d '\r\n')

    if [[ -n "$latest_tag" ]]; then
      local latest_version="${latest_tag#v}"
      if [[ -z "$current_version" || "$current_version" != "$latest_version" ]]; then
        CHECK_UPDATE_RELEASE="$latest_tag"
        msg_ok "Update available: ${APP} ${current_version:-not installed} → ${latest_version}"
        UPDATE_AVAILABLE=true
      else
        msg_ok "No update available: ${APP} (${latest_version})"
      fi
    fi
  fi

  if [[ "$UPDATE_AVAILABLE" == "true" ]]; then
    # Check if MCP service is enabled before stopping
    MCP_WAS_ENABLED=false
    if systemctl is-enabled ragflow-mcp.service 2>/dev/null | grep -q "enabled"; then
      MCP_WAS_ENABLED=true
    fi

    msg_info "Stopping Services"
    systemctl stop ragflow-mcp || true
    systemctl stop ragflow-task-executor || true
    systemctl stop ragflow-server || true
    msg_ok "Stopped Services"

    msg_info "Backing up Data"
    cp -r /opt/ragflow/conf /opt/ragflow_conf_backup
    cp -r /opt/ragflow/data /opt/ragflow_data_backup 2>/dev/null || true
    cp /opt/ragflow/.env /opt/ragflow_env_backup 2>/dev/null || true
    msg_ok "Backed up Data"

    # Try API-based download first, fall back to direct download
    DOWNLOAD_SUCCESS=false
    if getent hosts api.github.com >/dev/null 2>&1; then
      if CLEAN_INSTALL=1 fetch_and_deploy_gh_release "ragflow" "infiniflow/ragflow" "tarball" "latest" "/opt/ragflow" 2>/dev/null; then
        DOWNLOAD_SUCCESS=true
      fi
    fi

    if [[ "$DOWNLOAD_SUCCESS" != "true" ]]; then
      msg_warn "GitHub API method failed, trying direct download..."
      CLEAN_INSTALL=1 download_ragflow_direct || {
        msg_error "Failed to download RAGFlow"
        msg_error "Set GITHUB_TOKEN or check network connectivity"
        exit 1
      }
    fi

    msg_info "Reinstalling Python Dependencies"
    cd /opt/ragflow || exit
    export UV_SYSTEM_PYTHON=1
    $STD /usr/local/bin/uv sync --python 3.12 --frozen --index-strategy unsafe-best-match
    $STD /usr/local/bin/uv run download_deps.py
    msg_ok "Reinstalled Python Dependencies"

    msg_info "Rebuilding Frontend"
    cd /opt/ragflow/web || exit
    $STD npm install
    $STD npm run build
    cp -r /opt/ragflow/web/dist/* /var/www/ragflow/
    msg_ok "Rebuilt Frontend"

    msg_info "Restoring Configuration"
    cp -r /opt/ragflow_conf_backup/. /opt/ragflow/conf/
    cp -r /opt/ragflow_data_backup/. /opt/ragflow/data/ 2>/dev/null || true
    cp /opt/ragflow_env_backup /opt/ragflow/.env 2>/dev/null || true
    rm -rf /opt/ragflow_conf_backup /opt/ragflow_data_backup /opt/ragflow_env_backup
    msg_ok "Restored Configuration"

    msg_info "Starting Services"
    systemctl start ragflow-server
    sleep 5
    systemctl start ragflow-task-executor
    
    # Restart MCP service if it was enabled before update
    if [[ "$MCP_WAS_ENABLED" == "true" ]]; then
      msg_info "Restarting MCP Server"
      systemctl start ragflow-mcp || true
      msg_ok "Restarted MCP Server"
    fi
    
    msg_ok "Started Services"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:80${CL}"
echo -e "${INFO}${YW} API endpoint: http://${IP}:9380${CL}"
echo -e ""
echo -e "${INFO}${YW} Optional MCP Server (for AI assistant integration):${CL}"
echo -e "${TAB}- MCP endpoint: http://${IP}:9382"
echo -e "${TAB}- Enable with: systemctl enable --now ragflow-mcp.service"
echo -e "${TAB}- Requires RAGFlow API key from web interface"
