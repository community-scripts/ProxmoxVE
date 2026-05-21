

# Copyright (c) 2021-2026 community-scripts ORG
# Author: pshankinclarke (lazarillo)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://valkey.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

CONNECTION_MODE="standard"
VALKEY_TCP_ENABLED="yes"
VALKEY_TLS_ENABLED="no"
VALKEY_TCP_PORT="6379"
VALKEY_TLS_PORT=""
VALKEY_TLS_CERT_TYPE="none"
VALKEY_HOST="$(hostname -I | awk '{print $1}')"

emit_valkey_command() {
  local label="$1"
  local port="$2"
  local tls_args="${3:-}"

  printf "%s:\n" "$label"

  if [[ -n "$tls_args" ]]; then
    printf 'VALKEYCLI_AUTH="$(cat /root/valkey.creds)" valkey-cli -h %s -p %s %s ping\n\n' \
      "$VALKEY_HOST" "$port" "$tls_args"
  else
    printf 'VALKEYCLI_AUTH="$(cat /root/valkey.creds)" valkey-cli -h %s -p %s ping\n\n' \
      "$VALKEY_HOST" "$port"
  fi
}

write_valkey_connection_info() {
  {
    printf 'Valkey Connection Details\n\n'
    printf 'Connection Mode: %s\n' "$CONNECTION_MODE"
    printf 'Password file: /root/valkey.creds\n\n'

    if [[ "$VALKEY_TCP_ENABLED" == "yes" ]]; then
      printf 'Plain TCP: %s:%s\n' "$VALKEY_HOST" "$VALKEY_TCP_PORT"
      emit_valkey_command "Plain TCP test" "$VALKEY_TCP_PORT"
    else
      printf 'Plain TCP: disabled\n'
    fi

    if [[ "$VALKEY_TLS_ENABLED" == "yes" ]]; then
      printf 'TLS: %s:%s\n' "$VALKEY_HOST" "$VALKEY_TLS_PORT"
      printf 'TLS Certificate Type: %s\n\n' "$VALKEY_TLS_CERT_TYPE"

      emit_valkey_command \
        "Quick TLS test" \
        "$VALKEY_TLS_PORT" \
        "--tls --insecure"

      emit_valkey_command \
        "Verified TLS from this container" \
        "$VALKEY_TLS_PORT" \
        "--tls --cacert /etc/ssl/valkey/valkey.crt"

    else
      printf 'TLS: disabled\n\n'
    fi
  } > ~/valkey.connection-info
  chmod 600 ~/valkey.connection-info
}

validate_valkey() {
  msg_info "Validating Valkey"

  if ! systemctl is-active --quiet valkey-server; then
    msg_error "Valkey service failed to start"
    journalctl -u valkey-server -n 20 --no-pager || true
    exit 1
  fi

  if [[ "$VALKEY_TCP_ENABLED" == "yes" ]]; then
    if ! VALKEYCLI_AUTH="$PASS" valkey-cli -p "$VALKEY_TCP_PORT" ping 2>/dev/null | grep -q PONG; then
      msg_error "Valkey did not respond to TCP port ${VALKEY_TCP_PORT}"
      journalctl -u valkey-server -n 20 --no-pager || true
      exit 1
    fi
    msg_ok "Validated TCP connection on port ${VALKEY_TCP_PORT}"
  fi

  if [[ "$VALKEY_TLS_ENABLED" == "yes" ]]; then
    if ! VALKEYCLI_AUTH="$PASS" valkey-cli -p "$VALKEY_TLS_PORT" --tls --insecure ping 2>/dev/null | grep -q PONG; then
      msg_error "Valkey did not respond over TLS on port ${VALKEY_TLS_PORT}"
      journalctl -u valkey-server -n 20 --no-pager || true
      exit 1
    fi
    msg_ok "Validated TLS connection on port ${VALKEY_TLS_PORT}"
  fi

  if [[ "$CONNECTION_MODE" == "tls-only" ]]; then
    if VALKEYCLI_AUTH="$PASS" valkey-cli -p "$VALKEY_TLS_PORT" ping >/dev/null 2>&1; then
      msg_error "Plain TCP unexpectedly responded on port ${VALKEY_TLS_PORT}"
      exit 1
    fi
    msg_ok "Confirmed plain TCP is disabled on port ${VALKEY_TLS_PORT}"
  fi
  msg_ok "Validated Valkey"
}


msg_info "Installing Valkey"
$STD apt update
$STD apt install -y valkey openssl
sed -i 's/^bind .*/bind 0.0.0.0/' /etc/valkey/valkey.conf

PASS="$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | head -c32)"
echo "requirepass $PASS" >> /etc/valkey/valkey.conf
echo "$PASS" >~/valkey.creds
chmod 600 ~/valkey.creds

MEMTOTAL_MB=$(free -m | grep ^Mem: | awk '{print $2}')
# reserve 25% of a node type's maxmemory value for system use
MAXMEMORY_MB=$((MEMTOTAL_MB * 75 / 100))

echo "" >> /etc/valkey/valkey.conf
echo "# Memory-optimized settings for small-scale deployments" >> /etc/valkey/valkey.conf
echo "maxmemory ${MAXMEMORY_MB}mb" >> /etc/valkey/valkey.conf
echo "maxmemory-policy allkeys-lru" >> /etc/valkey/valkey.conf
echo "maxmemory-samples 10" >> /etc/valkey/valkey.conf
msg_ok "Installed Valkey"

echo
echo -e "${TAB3}Valkey Connection Mode"
echo -e "${TAB3}1) Standard - non-TLS connections over TCP on port 6379"
echo -e "${TAB3}2) Dual     - non-TLS connections on port 6379 and TLS connections on port 6380"
echo -e "${TAB3}3) TLS-only - TLS connections on port 6379, non-TLS port disabled"
read -r -p "${TAB3}Select connection mode [1]: " connection_choice || connection_choice="1"
connection_choice="${connection_choice:-1}"

case "$connection_choice" in
  1)
    CONNECTION_MODE="standard"
    VALKEY_TCP_ENABLED="yes"
    VALKEY_TLS_ENABLED="no"
    VALKEY_TCP_PORT="6379"
    VALKEY_TLS_PORT=""
    VALKEY_TLS_CERT_TYPE="none"
    msg_ok "Configured standard mode"
    ;;
  2|3)
    msg_info "Configuring TLS for Valkey..."

    create_self_signed_cert "Valkey"
    TLS_DIR="/etc/ssl/valkey"
    TLS_CERT="$TLS_DIR/valkey.crt"
    TLS_KEY="$TLS_DIR/valkey.key"
    chown valkey:valkey "$TLS_CERT" "$TLS_KEY"

    if [[ "$connection_choice" == "3" ]]; then
      CONNECTION_MODE="tls-only"
      VALKEY_TCP_ENABLED="no"
      VALKEY_TLS_ENABLED="yes"
      VALKEY_TCP_PORT=""
      VALKEY_TLS_PORT="6379"
      VALKEY_TLS_CERT_TYPE="self-signed"

      {
        echo ""
        echo "# TLS configuration generated by Proxmox VE Valkey helper-script"
        echo "port 0"
        echo "tls-port 6379"
        echo "tls-cert-file $TLS_DIR/valkey.crt"
        echo "tls-key-file $TLS_DIR/valkey.key"
        echo "tls-auth-clients no"
      } >> /etc/valkey/valkey.conf

      msg_ok "Configured TLS-only mode"
    else
      CONNECTION_MODE="dual"
      VALKEY_TCP_ENABLED="yes"
      VALKEY_TLS_ENABLED="yes"
      VALKEY_TCP_PORT="6379"
      VALKEY_TLS_PORT="6380"
      VALKEY_TLS_CERT_TYPE="self-signed"

      {
        echo ""
        echo "# TLS configuration generated by Proxmox VE Valkey helper-script"
        echo "tls-port 6380"
        echo "tls-cert-file $TLS_DIR/valkey.crt"
        echo "tls-key-file $TLS_DIR/valkey.key"
        echo "tls-auth-clients no"
      } >> /etc/valkey/valkey.conf

      msg_ok "Configured dual mode"
    fi
    ;;
  *)
    msg_warn "Invalid connection mode selected; using standard mode"
    CONNECTION_MODE="standard"
    VALKEY_TCP_ENABLED="yes"
    VALKEY_TLS_ENABLED="no"
    VALKEY_TCP_PORT="6379"
    VALKEY_TLS_PORT=""
    VALKEY_TLS_CERT_TYPE="none"
    msg_ok "Configured standard mode"
    ;;
esac

write_valkey_connection_info
msg_ok "Saved connection details"

systemctl enable -q --now valkey-server
systemctl restart valkey-server

validate_valkey

motd_ssh
customize
cleanup_lxc
