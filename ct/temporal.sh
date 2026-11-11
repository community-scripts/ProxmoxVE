#!/usr/bin/env bash
# Temporal self-hosted LXC - Community Scripts compatible wrapper
# License: MIT
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

APP="Temporal"
var_tags="${var_tags:-automation;development}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  if [[ ! -x /usr/local/bin/temporal-server ]]; then
    msg_error "Temporal installation not found"
    exit 1
  fi
  msg_error "Automated upgrades are intentionally disabled. Back up PostgreSQL and migrate schemas before upgrading."
  exit 1
}

# Installer inputs must be exported from the host to the LXC lifecycle.
# Prefer supplying var_temporal_* from the environment for unattended runs.
if [[ -z "${var_temporal_source:-}" ]]; then
  read -r -p "Temporal credentials [manual/vault] (manual): " var_temporal_source
  var_temporal_source="${var_temporal_source:-manual}"
fi
case "$var_temporal_source" in
  manual)
    if [[ -z "${var_temporal_db_host:-}" ]]; then read -r -p "PostgreSQL host: " var_temporal_db_host; fi
    if [[ -z "${var_temporal_db_user:-}" ]]; then read -r -p "PostgreSQL user [temporal]: " var_temporal_db_user; fi
    var_temporal_db_user="${var_temporal_db_user:-temporal}"
    if [[ -z "${var_temporal_db_password:-}" ]]; then read -r -s -p "PostgreSQL password: " var_temporal_db_password; echo; fi
    [[ -n "$var_temporal_db_host" && -n "$var_temporal_db_password" ]] || { echo "Database host and password are required" >&2; exit 1; }
    ;;
  vault)
    if [[ -z "${var_temporal_vault_addr:-}" ]]; then read -r -p "Vault URL: " var_temporal_vault_addr; fi
    if [[ -z "${var_temporal_vault_role_id:-}" ]]; then read -r -p "Vault role_id: " var_temporal_vault_role_id; fi
    if [[ -z "${var_temporal_vault_secret_id:-}" ]]; then read -r -s -p "Vault secret_id: " var_temporal_vault_secret_id; echo; fi
    [[ -n "$var_temporal_vault_addr" && -n "$var_temporal_vault_role_id" && -n "$var_temporal_vault_secret_id" ]] || { echo "Vault parameters required" >&2; exit 1; }
    ;;
  *) echo "Invalid credentials mode" >&2; exit 1 ;;
esac
export var_temporal_source var_temporal_db_host var_temporal_db_user var_temporal_db_password
export var_temporal_db_port var_temporal_db_name var_temporal_visibility_db
export var_temporal_vault_addr var_temporal_vault_mount var_temporal_vault_path
export var_temporal_vault_role_id var_temporal_vault_secret_id

start
build_container
description
msg_ok "Temporal installation completed!"
echo -e "${INFO}${YW} Temporal gRPC: ${IP}:7233${CL}"
echo -e "${INFO}${YW} Temporal UI: http://${IP}:8080${CL}"
