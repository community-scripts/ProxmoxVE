#!/usr/bin/env bash
# Native Temporal + UI server with external PostgreSQL for Proxmox LXC
# Tested statically with Temporal 1.32.2 and UI 2.58.1 release layouts.
# License: MIT
set -Eeuo pipefail

if [[ -n "${FUNCTIONS_FILE_PATH:-}" ]]; then
  source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
  color
  catch_errors
  setting_up_container
  network_check
  update_os
else
  [[ $EUID -eq 0 ]] || { echo "Run as root" >&2; exit 1; }
  echo "Standalone installation inside an existing Debian LXC"
  apt-get update
fi

# Inputs propagated by ct/temporal.sh through Community Scripts Core.
TEMPORAL_CONFIG_SOURCE="${TEMPORAL_CONFIG_SOURCE:-${var_temporal_source:-}}"
POSTGRES_HOST="${POSTGRES_HOST:-${var_temporal_db_host:-}}"
POSTGRES_PORT="${POSTGRES_PORT:-${var_temporal_db_port:-5432}}"
POSTGRES_USER="${POSTGRES_USER:-${var_temporal_db_user:-temporal}}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-${var_temporal_db_password:-}}"
POSTGRES_DB="${POSTGRES_DB:-${var_temporal_db_name:-temporal}}"
POSTGRES_VISIBILITY_DB="${POSTGRES_VISIBILITY_DB:-${var_temporal_visibility_db:-temporal_visibility}}"
VAULT_ADDR="${VAULT_ADDR:-${var_temporal_vault_addr:-}}"
VAULT_KV_MOUNT="${VAULT_KV_MOUNT:-${var_temporal_vault_mount:-secret}}"
VAULT_KV_PATH="${VAULT_KV_PATH:-${var_temporal_vault_path:-temporal}}"
VAULT_ROLE_ID="${VAULT_ROLE_ID:-${var_temporal_vault_role_id:-}}"
VAULT_SECRET_ID="${VAULT_SECRET_ID:-${var_temporal_vault_secret_id:-}}"
TEMPORAL_VERSION="${TEMPORAL_VERSION:-1.32.2}"
UI_VERSION="${TEMPORAL_UI_VERSION:-2.58.1}"
CONFIG_DIR=/etc/temporalio
ENV_FILE=$CONFIG_DIR/lxc.env
PG_DB="${POSTGRES_DB:-temporal}"
PG_VIS_DB="${POSTGRES_VISIBILITY_DB:-temporal_visibility}"
GRPC_PORT="${TEMPORAL_GRPC_PORT:-7233}"
UI_PORT="${TEMPORAL_UI_PORT:-8080}"
SOURCE="${TEMPORAL_CONFIG_SOURCE:-}"
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"; unset POSTGRES_PASSWORD VAULT_TOKEN VAULT_ROLE_ID VAULT_SECRET_ID SQL_PASSWORD PGPASSWORD || true' EXIT
umask 077

say() { printf '\n[temporal] %s\n' "$*"; }
die() { echo "ERROR: $*" >&2; exit 1; }
ask() {
  local label="$1" default="$2" result
  if [[ -t 0 ]]; then
    read -r -p "$label [$default]: " result
    printf '%s' "${result:-$default}"
  else
    printf '%s' "$default"
  fi
}
require_value() { [[ -n "${!1:-}" ]] || die "$1 must be supplied (interactive terminal or environment)"; }
valid_port() { [[ "$1" =~ ^[0-9]+$ ]] && (( 10#$1 >= 1 && 10#$1 <= 65535 )); }
valid_db() { [[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || die "Unsupported PostgreSQL database name: $1"; }
json() { jq -Rn --arg value "$1" '$value'; }
fetch_release() {
  local url="$1" checksum_url="$2" archive="$3" checksums="$4"
  curl -fL --retry 3 --connect-timeout 15 -o "$archive" "$url"
  curl -fL --retry 3 --connect-timeout 15 -o "$checksums" "$checksum_url"
  (cd "$(dirname "$archive")"; grep -F "$(basename "$archive")" "$(basename "$checksums")" | sha256sum -c -) || die "SHA256 failed for $archive"
}

say "Installing minimal dependencies"
apt-get install -y --no-install-recommends ca-certificates curl jq tar gzip postgresql-client

if [[ -f "$ENV_FILE" ]]; then
  die "$ENV_FILE already exists; refusing to overwrite an installation. Back up or manually remove it first."
fi
mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

if [[ -z "$SOURCE" ]]; then
  if [[ -t 0 ]]; then
    read -r -p "Credential source [manual/vault] (manual): " SOURCE
    SOURCE="${SOURCE:-manual}"
  else
    SOURCE=manual
  fi
fi
[[ "$SOURCE" == manual || "$SOURCE" == vault ]] || die "Invalid source: $SOURCE"

if [[ "$SOURCE" == vault ]]; then
  VAULT_ADDR="${VAULT_ADDR:-}"
  VAULT_KV_MOUNT="${VAULT_KV_MOUNT:-secret}"
  VAULT_KV_PATH="${VAULT_KV_PATH:-temporal}"
  VAULT_ADDR="$(ask 'Vault URL (HTTPS recommended)' "$VAULT_ADDR")"
  VAULT_KV_MOUNT="$(ask 'Vault KV v2 mount' "$VAULT_KV_MOUNT")"
  VAULT_KV_PATH="$(ask 'Vault KV v2 secret path' "$VAULT_KV_PATH")"
  [[ "$VAULT_ADDR" =~ ^https?:// ]] || die "Vault URL must begin with http(s)://"
  [[ "$VAULT_ADDR" == https://* ]] || echo "WARNING: HTTP Vault connection exposes authentication secrets on the network" >&2
  [[ "$VAULT_KV_MOUNT" =~ ^[a-zA-Z0-9_/-]+$ && "$VAULT_KV_PATH" =~ ^[a-zA-Z0-9_/-]+$ ]] || die "Invalid Vault KV path"
  VAULT_ROLE_ID="${VAULT_ROLE_ID:-}"
  VAULT_SECRET_ID="${VAULT_SECRET_ID:-}"
  if [[ -t 0 ]]; then
    [[ -n "$VAULT_ROLE_ID" ]] || read -r -p "Vault AppRole role_id: " VAULT_ROLE_ID
    if [[ -z "$VAULT_SECRET_ID" ]]; then read -r -s -p "Vault AppRole secret_id: " VAULT_SECRET_ID; echo; fi
  fi
  require_value VAULT_ROLE_ID
  require_value VAULT_SECRET_ID
  login_body=$(jq -n --arg role_id "$VAULT_ROLE_ID" --arg secret_id "$VAULT_SECRET_ID" '{role_id:$role_id,secret_id:$secret_id}')
  vault_login=$(curl -fsS --connect-timeout 15 --request POST -H 'Content-Type: application/json' --data "$login_body" "${VAULT_ADDR%/}/v1/auth/approle/login") || die 'Vault AppRole authentication failed'
  VAULT_TOKEN=$(jq -er '.auth.client_token' <<<"$vault_login") || die 'Vault did not return a token'
  unset VAULT_ROLE_ID VAULT_SECRET_ID login_body vault_login
  vault_result=$(curl -fsS --connect-timeout 15 -H "X-Vault-Token: $VAULT_TOKEN" "${VAULT_ADDR%/}/v1/${VAULT_KV_MOUNT}/data/${VAULT_KV_PATH}") || die 'Vault KV read failed'
  POSTGRES_HOST=$(jq -er '.data.data.host' <<<"$vault_result")
  POSTGRES_PORT=$(jq -r '.data.data.port // 5432' <<<"$vault_result")
  POSTGRES_USER=$(jq -er '.data.data.username' <<<"$vault_result")
  POSTGRES_PASSWORD=$(jq -er '.data.data.password' <<<"$vault_result")
  PG_DB=$(jq -r '.data.data.database // "temporal"' <<<"$vault_result")
  PG_VIS_DB=$(jq -r '.data.data.visibility_database // "temporal_visibility"' <<<"$vault_result")
  unset vault_result VAULT_TOKEN
else
  POSTGRES_HOST="$(ask 'PostgreSQL host' "${POSTGRES_HOST:-}")"
  POSTGRES_PORT="$(ask 'PostgreSQL port' "${POSTGRES_PORT:-5432}")"
  POSTGRES_USER="$(ask 'PostgreSQL user' "${POSTGRES_USER:-temporal}")"
  PG_DB="$(ask 'Temporal database' "$PG_DB")"
  PG_VIS_DB="$(ask 'Visibility database' "$PG_VIS_DB")"
  POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-}"
  if [[ -z "$POSTGRES_PASSWORD" && -t 0 ]]; then
    read -r -s -p "PostgreSQL password: " POSTGRES_PASSWORD; echo
  fi
fi
require_value POSTGRES_HOST
require_value POSTGRES_USER
require_value POSTGRES_PASSWORD
valid_port "$POSTGRES_PORT" || die "Invalid PostgreSQL port"
valid_port "$GRPC_PORT" || die "Invalid Temporal gRPC port"
valid_port "$UI_PORT" || die "Invalid UI port"
valid_db "$PG_DB"
valid_db "$PG_VIS_DB"
[[ "$PG_DB" != "$PG_VIS_DB" ]] || die "Database names must differ"

# Explicitly limited to password-authenticated PostgreSQL on a trusted network.
# Set up PostgreSQL TLS separately before using outside a private network.
{
  printf 'TEMPORAL_CONFIG_SOURCE=%q\n' "$SOURCE"
  printf 'POSTGRES_HOST=%q\n' "$POSTGRES_HOST"
  printf 'POSTGRES_PORT=%q\n' "$POSTGRES_PORT"
  printf 'POSTGRES_USER=%q\n' "$POSTGRES_USER"
  printf 'POSTGRES_PASSWORD=%q\n' "$POSTGRES_PASSWORD"
  printf 'POSTGRES_DB=%q\n' "$PG_DB"
  printf 'POSTGRES_VISIBILITY_DB=%q\n' "$PG_VIS_DB"
  printf 'TEMPORAL_GRPC_PORT=%q\n' "$GRPC_PORT"
  printf 'TEMPORAL_UI_PORT=%q\n' "$UI_PORT"
} > "$ENV_FILE"
chmod 600 "$ENV_FILE"

say "Checking PostgreSQL connection"
export PGPASSWORD="$POSTGRES_PASSWORD"
psql -X -w -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres -Atqc 'select 1' >/dev/null || die "Cannot connect to PostgreSQL 'postgres' database with supplied credentials"

say "Downloading pinned official Temporal binaries"
case "$(dpkg --print-architecture)" in
  amd64|arm64) ARCH="$(dpkg --print-architecture)" ;;
  *) die "Only amd64/arm64 are supported" ;;
esac
TARBALL="temporal_${TEMPORAL_VERSION}_linux_${ARCH}.tar.gz"
UI_TARBALL="ui-server_${UI_VERSION}_linux_${ARCH}.tar.gz"
fetch_release \
  "https://github.com/temporalio/temporal/releases/download/v${TEMPORAL_VERSION}/${TARBALL}" \
  "https://github.com/temporalio/temporal/releases/download/v${TEMPORAL_VERSION}/checksums.txt" \
  "$WORKDIR/$TARBALL" "$WORKDIR/checksums.txt"
fetch_release \
  "https://github.com/temporalio/ui-server/releases/download/v${UI_VERSION}/${UI_TARBALL}" \
  "https://github.com/temporalio/ui-server/releases/download/v${UI_VERSION}/ui-server_${UI_VERSION}_checksums.txt" \
  "$WORKDIR/$UI_TARBALL" "$WORKDIR/ui-checksums.txt"
mkdir -p "$WORKDIR/server" "$WORKDIR/ui" "$WORKDIR/src"
tar -xzf "$WORKDIR/$TARBALL" -C "$WORKDIR/server"
tar -xzf "$WORKDIR/$UI_TARBALL" -C "$WORKDIR/ui"
[[ -f "$WORKDIR/server/temporal-server" && -f "$WORKDIR/server/temporal-sql-tool" && -f "$WORKDIR/ui/ui-server" ]] || die "Unexpected official release archive layout"
install -m 0755 "$WORKDIR/server/temporal-server" /usr/local/bin/temporal-server
install -m 0755 "$WORKDIR/server/temporal-sql-tool" /usr/local/bin/temporal-sql-tool
install -m 0755 "$WORKDIR/ui/ui-server" /usr/local/bin/temporal-ui-server

say "Downloading version-matched PostgreSQL schemas"
curl -fL --retry 3 --connect-timeout 15 -o "$WORKDIR/source.tar.gz" "https://github.com/temporalio/temporal/archive/refs/tags/v${TEMPORAL_VERSION}.tar.gz"
tar -xzf "$WORKDIR/source.tar.gz" -C "$WORKDIR/src"
SCHEMA_ROOT=$(find "$WORKDIR/src" -type d -path '*/schema/postgresql/v12' -print -quit)
[[ -n "$SCHEMA_ROOT" ]] || die "Temporal source archive did not include PostgreSQL v12 schemas"
mkdir -p /usr/local/share/temporal/schema
cp -a "$SCHEMA_ROOT" /usr/local/share/temporal/schema/postgresql-v12

say "Creating and migrating PostgreSQL schemas"
export SQL_PASSWORD="$POSTGRES_PASSWORD"
for db in "$PG_DB" "$PG_VIS_DB"; do
  present=$(psql -X -w -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres -Atqc "SELECT 1 FROM pg_database WHERE datname = '$db'" ) || die "Failed to inspect databases"
  if [[ "$present" != 1 ]]; then
    say "Creating database $db"
    /usr/local/bin/temporal-sql-tool --plugin postgres12 --ep "$POSTGRES_HOST" -p "$POSTGRES_PORT" -u "$POSTGRES_USER" --db "$db" create || die "Database creation failed. Grant CREATEDB or create databases manually."
  fi
  schema_present=$(psql -X -w -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$db" -Atqc "SELECT to_regclass('public.schema_version') IS NOT NULL") || die "Database $db unavailable"
  if [[ "$schema_present" != t ]]; then
    /usr/local/bin/temporal-sql-tool --plugin postgres12 --ep "$POSTGRES_HOST" -p "$POSTGRES_PORT" -u "$POSTGRES_USER" --db "$db" setup-schema -v 0.0
  fi
  if [[ "$db" == "$PG_DB" ]]; then kind=temporal; else kind=visibility; fi
  /usr/local/bin/temporal-sql-tool --plugin postgres12 --ep "$POSTGRES_HOST" -p "$POSTGRES_PORT" -u "$POSTGRES_USER" --db "$db" update-schema -d "/usr/local/share/temporal/schema/postgresql-v12/$kind/versioned"
done
unset SQL_PASSWORD PGPASSWORD

say "Writing native server configuration"
if ! id -u temporal >/dev/null 2>&1; then
  useradd --system --home-dir /var/lib/temporal --shell /usr/sbin/nologin temporal
fi
install -d -m 0750 -o temporal -g temporal /var/lib/temporal
install -d -m 0750 -o root -g temporal "$CONFIG_DIR"
HOST_IP=$(hostname -I | awk '{print $1}')
[[ -n "$HOST_IP" ]] || die "Container has no detected IPv4 address"
PG_ADDR=$(json "${POSTGRES_HOST}:${POSTGRES_PORT}")
PG_USERNAME=$(json "$POSTGRES_USER")
PG_PASS=$(json "$POSTGRES_PASSWORD")
DB1=$(json "$PG_DB")
DB2=$(json "$PG_VIS_DB")
BROADCAST=$(json "$HOST_IP")

cat > "$CONFIG_DIR/config.yaml" <<YAML
log:
  stdout: true
  level: info
persistence:
  defaultStore: default
  visibilityStore: visibility
  numHistoryShards: 4
  datastores:
    default:
      sql:
        pluginName: postgres12
        databaseName: $DB1
        connectAddr: $PG_ADDR
        connectProtocol: tcp
        user: $PG_USERNAME
        password: $PG_PASS
        maxConns: 10
        maxIdleConns: 10
        maxConnLifetime: 1h
    visibility:
      sql:
        pluginName: postgres12
        databaseName: $DB2
        connectAddr: $PG_ADDR
        connectProtocol: tcp
        user: $PG_USERNAME
        password: $PG_PASS
        maxConns: 5
        maxIdleConns: 5
        maxConnLifetime: 1h
global:
  membership:
    maxJoinDuration: 30s
    broadcastAddress: $BROADCAST
  pprof:
    port: 0
services:
  frontend:
    rpc:
      grpcPort: $GRPC_PORT
      membershipPort: 6933
      bindOnLocalHost: false
      httpPort: 7243
  matching:
    rpc:
      grpcPort: 7235
      membershipPort: 6935
      bindOnLocalHost: true
  history:
    rpc:
      grpcPort: 7234
      membershipPort: 6934
      bindOnLocalHost: true
  worker:
    rpc:
      grpcPort: 7239
      membershipPort: 6939
      bindOnLocalHost: true
clusterMetadata:
  enableGlobalNamespace: false
  failoverVersionIncrement: 10
  masterClusterName: active
  currentClusterName: active
  clusterInformation:
    active:
      enabled: true
      initialFailoverVersion: 1
      rpcName: frontend
      rpcAddress: "127.0.0.1:$GRPC_PORT"
dcRedirectionPolicy:
  policy: noop
archival:
  history:
    state: disabled
  visibility:
    state: disabled
namespaceDefaults:
  archival:
    history:
      state: disabled
    visibility:
      state: disabled
dynamicConfigClient:
  filepath: "$CONFIG_DIR/dynamicconfig.yaml"
  pollInterval: 10s
YAML
printf '{}\n' > "$CONFIG_DIR/dynamicconfig.yaml"
chmod 640 "$CONFIG_DIR/config.yaml" "$CONFIG_DIR/dynamicconfig.yaml"
chown root:temporal "$CONFIG_DIR/config.yaml" "$CONFIG_DIR/dynamicconfig.yaml"

mkdir -p "$CONFIG_DIR/ui"
cat > "$CONFIG_DIR/ui/base.yaml" <<YAML
temporalGrpcAddress: "127.0.0.1:$GRPC_PORT"
port: $UI_PORT
YAML
cp "$CONFIG_DIR/ui/base.yaml" "$CONFIG_DIR/ui/development.yaml"
chmod 644 "$CONFIG_DIR/ui/"*.yaml
cat > /etc/systemd/system/temporal.service <<'UNIT'
[Unit]
Description=Temporal Server (native, all services)
Wants=network-online.target
After=network-online.target
[Service]
Type=simple
User=temporal
Group=temporal
WorkingDirectory=/var/lib/temporal
ExecStart=/usr/local/bin/temporal-server --config-file /etc/temporalio/config.yaml start
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/temporal
[Install]
WantedBy=multi-user.target
UNIT
cat > /etc/systemd/system/temporal-ui.service <<'UNIT'
[Unit]
Description=Temporal Web UI (native)
After=network-online.target temporal.service
Wants=network-online.target
[Service]
Type=simple
User=temporal
Group=temporal
WorkingDirectory=/var/lib/temporal
ExecStart=/usr/local/bin/temporal-ui-server --config /etc/temporalio/ui --env development start
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now temporal.service temporal-ui.service
sleep 5
systemctl is-active --quiet temporal.service || { journalctl -u temporal -n 60 --no-pager; die "Temporal did not start"; }
systemctl is-active --quiet temporal-ui.service || { journalctl -u temporal-ui -n 60 --no-pager; die "Temporal UI did not start"; }

say "Temporal running. UI: http://${HOST_IP}:${UI_PORT} | gRPC: ${HOST_IP}:${GRPC_PORT}"
echo 'NOTE: No TLS or authentication on Temporal endpoints; expose only over a trusted LAN/VPN.'
unset POSTGRES_PASSWORD PG_PASS

if [[ -n "${FUNCTIONS_FILE_PATH:-}" ]]; then
  motd_ssh
  customize
  cleanup_lxc
fi
