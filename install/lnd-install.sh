#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/lightningnetwork/lnd | https://github.com/Ride-The-Lightning/RTL | https://raspibolt.org/guide/lightning/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

LND_DATA_DIR="/data/lnd"
LND_HOME="/home/lnd"
LND_CONF="${LND_DATA_DIR}/lnd.conf"
LND_PASSWORD_FILE="${LND_DATA_DIR}/password.txt"
RTL_DIR="/opt/RTL"
RTL_CONFIG="${RTL_DIR}/RTL-Config.json"
RTL_CONFIG_DIR="${RTL_DIR}"
RTL_DB_DIR="/var/lib/rtl"
SCB_SCRIPT="/usr/local/bin/scb-backup"
SCB_SERVICE="/etc/systemd/system/scb-backup.service"
SCB_ENV_FILE="/etc/lnd-scb-backup.env"
SCB_GIT_ASKPASS="/usr/local/bin/scb-git-askpass"
TOR_RTL_SERVICE_DIR="/var/lib/tor/hidden_service_rtl"

prompt_input() {
  local prompt="$1"
  local default_value="${2:-}"

  if [[ -n "$default_value" ]]; then
    printf "%s%s [%s]: " "${TAB3}" "${prompt}" "${default_value}"
    read -r PROMPT_RESULT
    PROMPT_RESULT="${PROMPT_RESULT:-$default_value}"
  else
    printf "%s%s: " "${TAB3}" "${prompt}"
    read -r PROMPT_RESULT
  fi
}

prompt_yes_no() {
  local prompt="$1"
  local default="${2:-N}"

  printf "%s%s <y/N> " "${TAB3}" "${prompt}"
  read -r PROMPT_RESULT
  PROMPT_RESULT="${PROMPT_RESULT:-$default}"
  [[ "${PROMPT_RESULT,,}" =~ ^(y|yes)$ ]]
}

prompt_secret() {
  local prompt="$1"

  printf "%s%s: " "${TAB3}" "${prompt}"
  read -r -s PROMPT_RESULT
  printf "\n"
}

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf "%s" "$value"
}

parse_git_host() {
  local remote_url="$1"
  if [[ "$remote_url" =~ ^https?://([^/@]+@)?([^/:]+) ]]; then
    printf "%s" "${BASH_REMATCH[2]}"
  elif [[ "$remote_url" =~ ^ssh://([^/@]+@)?([^/:]+) ]]; then
    printf "%s" "${BASH_REMATCH[2]}"
  elif [[ "$remote_url" =~ ^[^@]+@([^:]+): ]]; then
    printf "%s" "${BASH_REMATCH[1]}"
  fi
}

configure_defaults() {
  BITCOIN_NETWORK="${BITCOIN_NETWORK:-mainnet}"
  LND_ALIAS="${LND_ALIAS:-$(hostname)}"
  BITCOIND_RPC_HOST="${BITCOIND_RPC_HOST:-127.0.0.1}"
  BITCOIND_RPC_PORT="${BITCOIND_RPC_PORT:-8332}"
  BITCOIND_ZMQ_RAWBLOCK="${BITCOIND_ZMQ_RAWBLOCK:-tcp://127.0.0.1:28332}"
  BITCOIND_ZMQ_RAWTX="${BITCOIND_ZMQ_RAWTX:-tcp://127.0.0.1:28333}"
  BITCOIND_RPC_USER="${BITCOIND_RPC_USER:-bitcoin}"
  BITCOIND_RPC_PASS="${BITCOIND_RPC_PASS:-}"
  ENABLE_TOR="${ENABLE_TOR:-no}"
  ENABLE_RTL="${ENABLE_RTL:-no}"
  ENABLE_SCB_BACKUP="${ENABLE_SCB_BACKUP:-no}"
  SCB_BACKUP_MODE="${SCB_BACKUP_MODE:-local}"
  AUTO_UNLOCK_WALLET="${AUTO_UNLOCK_WALLET:-no}"
  TOR_FOR_RTL="${TOR_FOR_RTL:-no}"
  RTL_PASSWORD="${RTL_PASSWORD:-}"
  SCB_BACKUP_DIR="${SCB_BACKUP_DIR:-/mnt/lnd-scb-backup}"
  SCB_GIT_REMOTE_URL="${SCB_GIT_REMOTE_URL:-https://github.com/YOUR_USER/lnd-scb-backup.git}"
  SCB_GIT_BRANCH="${SCB_GIT_BRANCH:-main}"
  SCB_GIT_AUTH_METHOD="${SCB_GIT_AUTH_METHOD:-https}"
  SCB_GIT_USERNAME="${SCB_GIT_USERNAME:-x-access-token}"
  SCB_GIT_TOKEN="${SCB_GIT_TOKEN:-}"
  SCB_GIT_COMMIT_NAME="${SCB_GIT_COMMIT_NAME:-LND SCB Backup}"
  SCB_GIT_COMMIT_EMAIL="${SCB_GIT_COMMIT_EMAIL:-lnd@$(hostname)}"
  SCB_GIT_SSH_KEY_PATH="${SCB_GIT_SSH_KEY_PATH:-/home/lnd/.ssh/id_ed25519}"
  SCB_GIT_KNOWN_HOSTS_FILE="${SCB_GIT_KNOWN_HOSTS_FILE:-/home/lnd/.ssh/known_hosts}"
  SCB_GIT_SSH_HOST="${SCB_GIT_SSH_HOST:-}"
  SCB_GIT_SSH_GENERATED="${SCB_GIT_SSH_GENERATED:-no}"
}

collect_install_settings() {
  configure_defaults

  stop_spinner
  echo
  echo -e "${INFO}${YW} Collecting LND configuration${CL}"
  prompt_input "LND alias" "$LND_ALIAS"
  LND_ALIAS=$(trim_value "$PROMPT_RESULT")
  prompt_input "Bitcoin network (mainnet/testnet/signet/regtest)" "$BITCOIN_NETWORK"
  BITCOIN_NETWORK=$(trim_value "$PROMPT_RESULT")
  prompt_input "bitcoind RPC host" "$BITCOIND_RPC_HOST"
  BITCOIND_RPC_HOST=$(trim_value "$PROMPT_RESULT")
  prompt_input "bitcoind RPC port" "$BITCOIND_RPC_PORT"
  BITCOIND_RPC_PORT=$(trim_value "$PROMPT_RESULT")
  prompt_input "bitcoind ZMQ rawblock endpoint" "$BITCOIND_ZMQ_RAWBLOCK"
  BITCOIND_ZMQ_RAWBLOCK=$(trim_value "$PROMPT_RESULT")
  prompt_input "bitcoind ZMQ rawtx endpoint" "$BITCOIND_ZMQ_RAWTX"
  BITCOIND_ZMQ_RAWTX=$(trim_value "$PROMPT_RESULT")
  prompt_input "bitcoind RPC user" "$BITCOIND_RPC_USER"
  BITCOIND_RPC_USER=$(trim_value "$PROMPT_RESULT")
  prompt_secret "bitcoind RPC password"
  BITCOIND_RPC_PASS=$(trim_value "$PROMPT_RESULT")
  [[ -n "$BITCOIND_RPC_PASS" ]] || {
    msg_error "bitcoind RPC password cannot be empty"
    exit 1
  }

  if prompt_yes_no "Store wallet password locally for LND auto-unlock?"; then
    AUTO_UNLOCK_WALLET="yes"
    while true; do
      prompt_secret "LND wallet password"
      LND_WALLET_PASSWORD=$(trim_value "$PROMPT_RESULT")
      prompt_secret "Confirm LND wallet password"
      LND_WALLET_PASSWORD_CONFIRM=$(trim_value "$PROMPT_RESULT")
      if [[ -n "$LND_WALLET_PASSWORD" && "$LND_WALLET_PASSWORD" == "$LND_WALLET_PASSWORD_CONFIRM" ]]; then
        break
      fi
      msg_warn "Passwords did not match, please try again"
    done
  else
    AUTO_UNLOCK_WALLET="no"
  fi

  if prompt_yes_no "Install Static Channel Backup watcher?"; then
    ENABLE_SCB_BACKUP="yes"
    prompt_input "Backup method [1=Git remote, 2=Local directory]" "1"
    case "$(trim_value "$PROMPT_RESULT")" in
      2 | local | Local)
        SCB_BACKUP_MODE="local"
        prompt_input "Backup directory" "$SCB_BACKUP_DIR"
        SCB_BACKUP_DIR=$(trim_value "$PROMPT_RESULT")
        ;;
      *)
        SCB_BACKUP_MODE="git"
        prompt_input "Local working directory for git backups" "/var/lib/lnd-scb-backup"
        SCB_BACKUP_DIR=$(trim_value "$PROMPT_RESULT")
        prompt_input "Git remote URL" "$SCB_GIT_REMOTE_URL"
        SCB_GIT_REMOTE_URL=$(trim_value "$PROMPT_RESULT")
        prompt_input "Git branch" "$SCB_GIT_BRANCH"
        SCB_GIT_BRANCH=$(trim_value "$PROMPT_RESULT")
        prompt_input "Git commit name" "$SCB_GIT_COMMIT_NAME"
        SCB_GIT_COMMIT_NAME=$(trim_value "$PROMPT_RESULT")
        prompt_input "Git commit email" "$SCB_GIT_COMMIT_EMAIL"
        SCB_GIT_COMMIT_EMAIL=$(trim_value "$PROMPT_RESULT")
        prompt_input "Git auth method [1=HTTPS token, 2=SSH]" "1"
        case "$(trim_value "$PROMPT_RESULT")" in
          2 | ssh | SSH)
            SCB_GIT_AUTH_METHOD="ssh"
            prompt_input "SSH private key path" "$SCB_GIT_SSH_KEY_PATH"
            SCB_GIT_SSH_KEY_PATH=$(trim_value "$PROMPT_RESULT")
            prompt_input "SSH host for known_hosts scan" "$(parse_git_host "$SCB_GIT_REMOTE_URL")"
            SCB_GIT_SSH_HOST=$(trim_value "$PROMPT_RESULT")
            if [[ ! -f "$SCB_GIT_SSH_KEY_PATH" ]] && prompt_yes_no "Generate a dedicated SSH key for SCB backup now?"; then
              SCB_GIT_SSH_GENERATED="yes"
            fi
            ;;
          *)
            SCB_GIT_AUTH_METHOD="https"
            prompt_input "Git HTTPS username" "$SCB_GIT_USERNAME"
            SCB_GIT_USERNAME=$(trim_value "$PROMPT_RESULT")
            prompt_secret "Git HTTPS token / PAT"
            SCB_GIT_TOKEN=$(trim_value "$PROMPT_RESULT")
            [[ -n "$SCB_GIT_TOKEN" ]] || {
              msg_error "Git HTTPS token cannot be empty"
              exit 1
            }
            ;;
        esac
        ;;
    esac
  fi

  if prompt_yes_no "Install RTL web UI?"; then
    ENABLE_RTL="yes"
    while true; do
      prompt_secret "RTL web password"
      RTL_PASSWORD=$(trim_value "$PROMPT_RESULT")
      prompt_secret "Confirm RTL web password"
      RTL_PASSWORD_CONFIRM=$(trim_value "$PROMPT_RESULT")
      if [[ -n "$RTL_PASSWORD" && "$RTL_PASSWORD" == "$RTL_PASSWORD_CONFIRM" ]]; then
        break
      fi
      msg_warn "Passwords did not match, please try again"
    done
  fi

  if prompt_yes_no "Install Tor support?"; then
    ENABLE_TOR="yes"
    if [[ "$ENABLE_RTL" == "yes" ]] && prompt_yes_no "Expose RTL through a Tor hidden service?"; then
      TOR_FOR_RTL="yes"
    fi
  fi
}

install_dependencies() {
  msg_info "Installing Dependencies"
  $STD apt install -y \
    curl \
    wget \
    jq \
    git \
    gnupg \
    inotify-tools \
    xz-utils \
    unzip \
    ca-certificates
  if apt-cache show opentimestamps-client >/dev/null 2>&1; then
    $STD apt install -y opentimestamps-client || true
  fi
  if [[ "$ENABLE_TOR" == "yes" ]]; then
    $STD apt install -y tor
  fi
  if [[ "$ENABLE_SCB_BACKUP" == "yes" && "$SCB_BACKUP_MODE" == "git" && "$SCB_GIT_AUTH_METHOD" == "ssh" ]]; then
    $STD apt install -y openssh-client
  fi
  if [[ "$ENABLE_RTL" == "yes" ]]; then
    NODE_VERSION="22" setup_nodejs
  fi
  msg_ok "Installed Dependencies"
}

ensure_lnd_user() {
  if ! id -u lnd >/dev/null 2>&1; then
    msg_info "Creating lnd user"
    $STD adduser --disabled-password --gecos "" lnd
    msg_ok "Created lnd user"
  fi
  if [[ "$ENABLE_TOR" == "yes" ]] && getent group debian-tor >/dev/null 2>&1; then
    $STD usermod -a -G debian-tor lnd
  fi
}

install_lnd_release() {
  local release_json lnd_url manifest_url sig_url ots_url lnd_asset version

  msg_info "Downloading LND release metadata"
  release_json=$(curl -fsSL https://api.github.com/repos/lightningnetwork/lnd/releases/latest)
  version=$(echo "$release_json" | jq -r '.tag_name')
  lnd_url=$(echo "$release_json" | jq -r '.assets[] | select(.name | test("^lnd-linux-amd64-.*\\.tar\\.gz$")) | .browser_download_url' | head -n1)
  manifest_url=$(echo "$release_json" | jq -r '.assets[] | select(.name | test("^manifest-v.*\\.txt$")) | .browser_download_url' | head -n1)
  sig_url=$(echo "$release_json" | jq -r '.assets[] | select(.name | test("^manifest-roasbeef-v.*\\.sig$")) | .browser_download_url' | head -n1)
  ots_url=$(echo "$release_json" | jq -r '.assets[] | select(.name | test("^manifest-roasbeef-v.*\\.sig\\.ots$")) | .browser_download_url' | head -n1)
  lnd_asset=$(basename "$lnd_url")
  [[ -n "$version" && -n "$lnd_url" && -n "$manifest_url" && -n "$sig_url" ]] || {
    msg_error "Unable to resolve the latest LND release assets"
    exit 1
  }
  msg_ok "Resolved ${version}"

  msg_info "Verifying LND release"
  cd /tmp
  $STD wget -qO "$lnd_asset" "$lnd_url"
  $STD wget -qO manifest.txt "$manifest_url"
  $STD wget -qO manifest.sig "$sig_url"
  [[ -n "$ots_url" ]] && $STD wget -qO manifest.sig.ots "$ots_url" || true
  sha256sum --check manifest.txt --ignore-missing
  curl -fsSL https://raw.githubusercontent.com/lightningnetwork/lnd/master/scripts/keys/roasbeef.asc | gpg --import >/dev/null 2>&1
  gpg --verify manifest.sig manifest.txt >/dev/null 2>&1
  if command -v ots >/dev/null 2>&1 && [[ -f manifest.sig.ots ]]; then
    ots --no-cache verify manifest.sig.ots -f manifest.sig >/dev/null 2>&1 || true
  fi
  msg_ok "Verified LND release"

  msg_info "Installing LND"
  rm -rf /tmp/lnd-release
  mkdir -p /tmp/lnd-release
  tar -xzf "$lnd_asset" -C /tmp/lnd-release
  install -m 0755 -o root -g root -t /usr/local/bin /tmp/lnd-release/*/lnd /tmp/lnd-release/*/lncli
  msg_ok "Installed LND"
}

configure_lnd_directories() {
  msg_info "Configuring LND directories"
  mkdir -p "$LND_DATA_DIR"
  chown -R lnd:lnd "$LND_DATA_DIR"
  if [[ -L "${LND_HOME}/.lnd" || -e "${LND_HOME}/.lnd" ]]; then
    rm -rf "${LND_HOME}/.lnd"
  fi
  ln -s "$LND_DATA_DIR" "${LND_HOME}/.lnd"
  chown -h lnd:lnd "${LND_HOME}/.lnd"
  msg_ok "Configured LND directories"
}

write_lnd_password_file() {
  [[ "$AUTO_UNLOCK_WALLET" == "yes" ]] || return 0
  msg_info "Writing wallet password file"
  printf "%s\n" "$LND_WALLET_PASSWORD" >"$LND_PASSWORD_FILE"
  chown lnd:lnd "$LND_PASSWORD_FILE"
  chmod 600 "$LND_PASSWORD_FILE"
  msg_ok "Created wallet password file"
}

write_lnd_config() {
  local tor_block=""
  local unlock_block=""
  local network_lines=""

  case "$BITCOIN_NETWORK" in
    mainnet | testnet | signet | regtest) ;;
    *)
      msg_error "Unsupported Bitcoin network: $BITCOIN_NETWORK"
      exit 1
      ;;
  esac

  network_lines="bitcoin.active=true
bitcoin.${BITCOIN_NETWORK}=true"

  if [[ "$AUTO_UNLOCK_WALLET" == "yes" ]]; then
    unlock_block="wallet-unlock-password-file=${LND_PASSWORD_FILE}
wallet-unlock-allow-create=true"
  fi

  if [[ "$ENABLE_TOR" == "yes" ]]; then
    tor_block='
[tor]
tor.active=true
tor.v3=true
tor.streamisolation=true
tor.socks=127.0.0.1:9050
tor.control=127.0.0.1:9051'
  fi

  msg_info "Writing LND configuration"
  cat <<EOF >"$LND_CONF"
# community-scripts: lnd configuration

[Application Options]
alias=${LND_ALIAS}
debuglevel=info
maxpendingchannels=5
listen=0.0.0.0:9735
rpclisten=127.0.0.1:10009
restlisten=127.0.0.1:8080
tlsautorefresh=true
tlsdisableautofill=true
bitcoin.basefee=1000
bitcoin.feerate=1
minchansize=100000
accept-keysend=true
accept-amp=true
coop-close-target-confs=24
protocol.simple-taproot-chans=true
protocol.wumbo-channels=true
protocol.rbf-coop-close=true
wtclient.active=true
gc-canceled-invoices-on-startup=true
gc-canceled-invoices-on-the-fly=true
ignore-historical-gossip-filters=1
stagger-initial-reconnect=true
${unlock_block}

[bolt]
db.bolt.auto-compact=true
db.bolt.auto-compact-min-age=168h

[Bitcoin]
${network_lines}
bitcoin.node=bitcoind

[Bitcoind]
bitcoind.rpchost=${BITCOIND_RPC_HOST}:${BITCOIND_RPC_PORT}
bitcoind.rpcuser=${BITCOIND_RPC_USER}
bitcoind.rpcpass=${BITCOIND_RPC_PASS}
bitcoind.zmqpubrawblock=${BITCOIND_ZMQ_RAWBLOCK}
bitcoind.zmqpubrawtx=${BITCOIND_ZMQ_RAWTX}
${tor_block}
EOF
  chown lnd:lnd "$LND_CONF"
  chmod 640 "$LND_CONF"
  msg_ok "Wrote LND configuration"
}

create_lnd_service() {
  msg_info "Creating LND service"
  cat <<EOF >/etc/systemd/system/lnd.service
[Unit]
Description=LND Lightning Network Daemon
After=network-online.target
Wants=network-online.target

[Service]
User=lnd
Group=lnd
Type=simple
WorkingDirectory=${LND_DATA_DIR}
ExecStart=/usr/local/bin/lnd --configfile=${LND_CONF}
Restart=on-failure
RestartSec=5
TimeoutStopSec=60
LimitNOFILE=128000

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable -q --now lnd
  msg_ok "Created LND service"
}

install_scb_backup() {
  [[ "$ENABLE_SCB_BACKUP" == "yes" ]] || return 0

  write_scb_env() {
    local key="$1"
    local value="$2"
    printf '%s=%q\n' "$key" "$value" >>"$SCB_ENV_FILE"
  }

  msg_info "Configuring SCB backup"
  mkdir -p "$SCB_BACKUP_DIR"
  chown -R lnd:lnd "$SCB_BACKUP_DIR"
  runuser -u lnd -- git config --global --add safe.directory "$SCB_BACKUP_DIR" >/dev/null 2>&1 || true
  cat <<'EOF' >"$SCB_GIT_ASKPASS"
#!/usr/bin/env bash
case "$1" in
  *sername*) printf '%s\n' "${GIT_USERNAME:-x-access-token}" ;;
  *assword*) printf '%s\n' "${GIT_PASSWORD:-}" ;;
  *) printf '\n' ;;
esac
EOF
  chmod 755 "$SCB_GIT_ASKPASS"

  : >"$SCB_ENV_FILE"
  write_scb_env "SCB_BACKUP_MODE" "$SCB_BACKUP_MODE"
  write_scb_env "SCB_BACKUP_DIR" "$SCB_BACKUP_DIR"
  write_scb_env "SCB_GIT_REMOTE_URL" "$SCB_GIT_REMOTE_URL"
  write_scb_env "SCB_GIT_BRANCH" "$SCB_GIT_BRANCH"
  write_scb_env "SCB_GIT_AUTH_METHOD" "$SCB_GIT_AUTH_METHOD"
  write_scb_env "SCB_GIT_USERNAME" "$SCB_GIT_USERNAME"
  write_scb_env "SCB_GIT_TOKEN" "$SCB_GIT_TOKEN"
  write_scb_env "SCB_GIT_COMMIT_NAME" "$SCB_GIT_COMMIT_NAME"
  write_scb_env "SCB_GIT_COMMIT_EMAIL" "$SCB_GIT_COMMIT_EMAIL"
  write_scb_env "SCB_GIT_SSH_KEY_PATH" "$SCB_GIT_SSH_KEY_PATH"
  write_scb_env "SCB_GIT_KNOWN_HOSTS_FILE" "$SCB_GIT_KNOWN_HOSTS_FILE"
  write_scb_env "SCB_GIT_SSH_HOST" "$SCB_GIT_SSH_HOST"
  write_scb_env "SCB_GIT_ASKPASS" "$SCB_GIT_ASKPASS"
  chown root:lnd "$SCB_ENV_FILE"
  chmod 640 "$SCB_ENV_FILE"

  if [[ "$SCB_BACKUP_MODE" == "git" && "$SCB_GIT_AUTH_METHOD" == "ssh" ]]; then
    local scb_ssh_dir
    scb_ssh_dir="$(dirname "$SCB_GIT_SSH_KEY_PATH")"
    msg_info "Preparing SCB backup SSH access"
    mkdir -p "$scb_ssh_dir"
    chown lnd:lnd "$scb_ssh_dir"
    chmod 700 "$scb_ssh_dir"
    touch "$SCB_GIT_KNOWN_HOSTS_FILE"
    chown lnd:lnd "$SCB_GIT_KNOWN_HOSTS_FILE"
    chmod 644 "$SCB_GIT_KNOWN_HOSTS_FILE"
    if [[ "$SCB_GIT_SSH_GENERATED" == "yes" && ! -f "$SCB_GIT_SSH_KEY_PATH" ]]; then
      runuser -u lnd -- ssh-keygen -q -t ed25519 -N "" -f "$SCB_GIT_SSH_KEY_PATH"
    fi
    if [[ -n "$SCB_GIT_SSH_HOST" ]]; then
      ssh-keyscan -H "$SCB_GIT_SSH_HOST" >>"$SCB_GIT_KNOWN_HOSTS_FILE" 2>/dev/null || true
    fi
    chown -R lnd:lnd "$scb_ssh_dir"
    chmod 700 "$scb_ssh_dir"
    [[ -f "$SCB_GIT_SSH_KEY_PATH" ]] && chmod 600 "$SCB_GIT_SSH_KEY_PATH"
    chmod 644 "$SCB_GIT_KNOWN_HOSTS_FILE"
    msg_ok "Prepared SCB backup SSH access"
  fi

  cat <<EOF >"$SCB_SCRIPT"
#!/usr/bin/env bash
set -euo pipefail

SCB_SOURCE_FILE="${LND_DATA_DIR}/data/chain/bitcoin/${BITCOIN_NETWORK}/channel.backup"
SCB_SOURCE_DIR="\$(dirname "\$SCB_SOURCE_FILE")"
LOCAL_BACKUP_DIR="${SCB_BACKUP_DIR}"
STATE_FILE="\${LOCAL_BACKUP_DIR}/.channel.backup.sha256"
ENV_FILE="${SCB_ENV_FILE}"
SCB_EXPORT_FILE="${LND_DATA_DIR}/data/chain/bitcoin/${BITCOIN_NETWORK}/channel-all.bak"

[[ -f "\$ENV_FILE" ]] && source "\$ENV_FILE"

mkdir -p "\$LOCAL_BACKUP_DIR"

init_git_repo() {
  [[ "\${SCB_BACKUP_MODE:-local}" == "git" ]] || return 0

  if ! git -C "\$LOCAL_BACKUP_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "\$LOCAL_BACKUP_DIR" init -b "\${SCB_GIT_BRANCH}" >/dev/null 2>&1
  fi

  if git -C "\$LOCAL_BACKUP_DIR" remote get-url origin >/dev/null 2>&1; then
    git -C "\$LOCAL_BACKUP_DIR" remote set-url origin "\${SCB_GIT_REMOTE_URL}"
  else
    git -C "\$LOCAL_BACKUP_DIR" remote add origin "\${SCB_GIT_REMOTE_URL}"
  fi

  git -C "\$LOCAL_BACKUP_DIR" config user.name "\${SCB_GIT_COMMIT_NAME}"
  git -C "\$LOCAL_BACKUP_DIR" config user.email "\${SCB_GIT_COMMIT_EMAIL}"
  printf '.channel.backup.sha256\n' >"\$LOCAL_BACKUP_DIR/.gitignore"

  if [[ "\${SCB_GIT_AUTH_METHOD:-https}" == "ssh" ]]; then
    GIT_SSH_COMMAND="ssh -i \${SCB_GIT_SSH_KEY_PATH} -o IdentitiesOnly=yes -o UserKnownHostsFile=\${SCB_GIT_KNOWN_HOSTS_FILE} -o StrictHostKeyChecking=yes" \
      git -C "\$LOCAL_BACKUP_DIR" fetch --quiet origin "\${SCB_GIT_BRANCH}" >/dev/null 2>&1 || true
  else
    GIT_TERMINAL_PROMPT=0 \
      GIT_USERNAME="\${SCB_GIT_USERNAME:-x-access-token}" \
      GIT_PASSWORD="\${SCB_GIT_TOKEN:-}" \
      git -C "\$LOCAL_BACKUP_DIR" -c credential.helper= -c core.askPass="\${SCB_GIT_ASKPASS}" fetch --quiet origin "\${SCB_GIT_BRANCH}" >/dev/null 2>&1 || true
  fi

  if git -C "\$LOCAL_BACKUP_DIR" show-ref --verify --quiet "refs/remotes/origin/\${SCB_GIT_BRANCH}"; then
    git -C "\$LOCAL_BACKUP_DIR" checkout -B "\${SCB_GIT_BRANCH}" "origin/\${SCB_GIT_BRANCH}" >/dev/null 2>&1
  else
    git -C "\$LOCAL_BACKUP_DIR" checkout -B "\${SCB_GIT_BRANCH}" >/dev/null 2>&1
  fi
}

push_git_backup() {
  [[ "\${SCB_BACKUP_MODE:-local}" == "git" ]] || return 0

  init_git_repo
  git -C "\$LOCAL_BACKUP_DIR" add .gitignore channel.backup channel-*.backup channel-all.bak >/dev/null 2>&1 || true
  if git -C "\$LOCAL_BACKUP_DIR" diff --cached --quiet >/dev/null 2>&1; then
    return 0
  fi

  git -C "\$LOCAL_BACKUP_DIR" commit -m "SCB backup \$(date -u +%Y-%m-%dT%H:%M:%SZ)" >/dev/null

  if [[ "\${SCB_GIT_AUTH_METHOD:-https}" == "ssh" ]]; then
    GIT_SSH_COMMAND="ssh -i \${SCB_GIT_SSH_KEY_PATH} -o IdentitiesOnly=yes -o UserKnownHostsFile=\${SCB_GIT_KNOWN_HOSTS_FILE} -o StrictHostKeyChecking=yes" \
      git -C "\$LOCAL_BACKUP_DIR" push -u origin "\${SCB_GIT_BRANCH}" >/dev/null
  else
    GIT_TERMINAL_PROMPT=0 \
      GIT_USERNAME="\${SCB_GIT_USERNAME:-x-access-token}" \
      GIT_PASSWORD="\${SCB_GIT_TOKEN:-}" \
      git -C "\$LOCAL_BACKUP_DIR" -c credential.helper= -c core.askPass="\${SCB_GIT_ASKPASS}" push -u origin "\${SCB_GIT_BRANCH}" >/dev/null
  fi
}

backup_if_changed() {
  local current_hash previous_hash force_run="${1:-no}"

  [[ -f "\$SCB_SOURCE_FILE" ]] || return 0

  current_hash=\$(sha256sum "\$SCB_SOURCE_FILE" | awk '{print \$1}')
  previous_hash=\$(cat "\$STATE_FILE" 2>/dev/null || true)

  if [[ "\$force_run" == "yes" || "\$current_hash" != "\$previous_hash" ]]; then
    cp "\$SCB_SOURCE_FILE" "\$LOCAL_BACKUP_DIR/channel.backup"
    cp "\$SCB_SOURCE_FILE" "\$LOCAL_BACKUP_DIR/channel-\$(date +%Y%m%d-%H%M%S).backup"
    [[ -f "\$SCB_EXPORT_FILE" ]] && cp "\$SCB_EXPORT_FILE" "\$LOCAL_BACKUP_DIR/channel-all.bak"
    printf '%s\n' "\$current_hash" >"\$STATE_FILE"
    push_git_backup
  fi
}

run_self_test() {
  [[ -f "\$SCB_SOURCE_FILE" ]] || {
    echo "SCB self-test failed: source backup file not found at \$SCB_SOURCE_FILE" >&2
    exit 1
  }

  init_git_repo
  backup_if_changed yes
  echo "SCB self-test completed: forced backup snapshot created from \$SCB_SOURCE_FILE"
}

if [[ "\${1:-}" == "--self-test" ]]; then
  run_self_test
  exit 0
fi

init_git_repo
backup_if_changed

while true; do
  mkdir -p "\$SCB_SOURCE_DIR"
  inotifywait -q -e close_write,create,move,delete "\$SCB_SOURCE_DIR" >/dev/null 2>&1 || {
    sleep 2
    continue
  }
  backup_if_changed
done
EOF
  chmod 755 "$SCB_SCRIPT"

  cat <<EOF >"$SCB_SERVICE"
[Unit]
Description=SCB Backup daemon
After=lnd.service
Requires=lnd.service

[Service]
ExecStart=${SCB_SCRIPT}
Restart=always
RestartSec=2
User=lnd
Group=lnd

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable -q --now scb-backup.service
  msg_ok "Configured SCB backup"
}

install_rtl_release() {
  local release_json rtl_version rtl_base_tag rtl_tar_url rtl_sig_url rtl_tar_file extracted_dir

  msg_info "Downloading RTL release metadata"
  release_json=$(curl -fsSL https://api.github.com/repos/Ride-The-Lightning/RTL/releases/latest)
  rtl_version=$(echo "$release_json" | jq -r '.tag_name')
  rtl_base_tag=$(echo "$rtl_version" | sed 's/-beta.*$//')
  rtl_tar_url="https://github.com/Ride-The-Lightning/RTL/archive/refs/tags/${rtl_base_tag}.tar.gz"
  rtl_sig_url="https://github.com/Ride-The-Lightning/RTL/releases/download/${rtl_base_tag}/${rtl_base_tag}.tar.gz.asc"
  [[ -n "$rtl_version" && -n "$rtl_base_tag" ]] || {
    msg_error "Unable to resolve the latest RTL release version"
    exit 1
  }
  msg_ok "Resolved ${rtl_version} (${rtl_base_tag})"

  msg_info "Verifying RTL release"
  cd /tmp
  rtl_tar_file=$(basename "$rtl_tar_url")
  $STD wget -qO "$rtl_tar_file" "$rtl_tar_url"
  $STD wget -qO "${rtl_tar_file}.asc" "$rtl_sig_url"
  curl -fsSL https://keybase.io/suheb/pgp_keys.asc | gpg --import >/dev/null 2>&1
  gpg --verify "${rtl_tar_file}.asc" "$rtl_tar_file" >/dev/null 2>&1
  msg_ok "Verified RTL release"

  msg_info "Installing RTL"
  rm -rf /tmp/rtl-release "$RTL_DIR"
  mkdir -p /tmp/rtl-release
  tar -xzf "$rtl_tar_file" -C /tmp/rtl-release
  extracted_dir=$(find /tmp/rtl-release -mindepth 1 -maxdepth 1 -type d | head -n1)
  [[ -n "$extracted_dir" ]] || {
    msg_error "Failed to unpack RTL release"
    exit 1
  }
  mv "$extracted_dir" "$RTL_DIR"
  cd "$RTL_DIR"
  $STD npm ci --omit=dev --legacy-peer-deps
  mkdir -p "$RTL_DB_DIR"
  chown -R lnd:lnd "$RTL_DIR" "$RTL_DB_DIR"
  msg_ok "Installed RTL"
}

install_rtl() {
  local macaroon_file="${LND_DATA_DIR}/data/chain/bitcoin/${BITCOIN_NETWORK}/admin.macaroon"

  [[ "$ENABLE_RTL" == "yes" ]] || return 0

  install_rtl_release

  msg_info "Configuring RTL"
  jq -n \
    --arg multiPass "$RTL_PASSWORD" \
    --arg dbDirectoryPath "$RTL_DB_DIR" \
    --arg lnNode "$LND_ALIAS" \
    --arg macaroonPath "${LND_DATA_DIR}/data/chain/bitcoin/${BITCOIN_NETWORK}" \
    --arg configPath "$LND_CONF" \
    --arg channelBackupPath "$SCB_BACKUP_DIR" \
    '{
      multiPass: $multiPass,
      port: "3000",
      defaultNodeIndex: 1,
      dbDirectoryPath: $dbDirectoryPath,
      SSO: {
        rtlSSO: 0,
        rtlCookiePath: "",
        logoutRedirectLink: ""
      },
      nodes: [
        {
          index: 1,
          lnNode: $lnNode,
          lnImplementation: "LND",
          authentication: {
            macaroonPath: $macaroonPath,
            configPath: $configPath
          },
          settings: {
            userPersona: "OPERATOR",
            themeMode: "NIGHT",
            themeColor: "PURPLE",
            channelBackupPath: $channelBackupPath,
            logLevel: "ERROR",
            lnServerUrl: "https://127.0.0.1:8080",
            swapServerUrl: "https://127.0.0.1:8081",
            boltzServerUrl: "https://127.0.0.1:9003",
            fiatConversion: false,
            unannouncedChannels: false,
            blockExplorerUrl: "https://mempool.space"
          }
        }
      ]
    }' >"$RTL_CONFIG"
  chown lnd:lnd "$RTL_CONFIG"
  chmod 640 "$RTL_CONFIG"
  msg_ok "Configured RTL"

  msg_info "Creating RTL service"
  cat <<EOF >/etc/systemd/system/rtl.service
[Unit]
Description=Ride The Lightning
After=lnd.service network-online.target
Wants=network-online.target

[Service]
Type=simple
User=lnd
Group=lnd
WorkingDirectory=${RTL_DIR}
Environment=RTL_CONFIG_PATH=${RTL_CONFIG_DIR}
ExecStart=/usr/bin/node rtl
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable -q rtl
  if [[ -f "$macaroon_file" ]]; then
    systemctl start rtl
    msg_ok "Created RTL service"
  else
    msg_warn "RTL service enabled but not started yet"
    echo -e "${INFO}${YW} Create the LND wallet first, then run: ${GN}systemctl start rtl${CL}"
  fi
}

configure_tor() {
  [[ "$ENABLE_TOR" == "yes" ]] || return 0

  msg_info "Configuring Tor"
  grep -q '^ControlPort 9051$' /etc/tor/torrc 2>/dev/null || cat <<EOF >>/etc/tor/torrc

# community-scripts: lnd tor control
ControlPort 9051
CookieAuthentication 1
CookieAuthFileGroupReadable 1
EOF
  systemctl enable -q --now tor
  if [[ "$TOR_FOR_RTL" == "yes" ]]; then
    grep -q "hidden_service_rtl" /etc/tor/torrc 2>/dev/null || cat <<EOF >>/etc/tor/torrc

# community-scripts: RTL hidden service
HiddenServiceDir ${TOR_RTL_SERVICE_DIR}
HiddenServiceVersion 3
HiddenServicePort 80 127.0.0.1:3000
EOF
    systemctl restart tor
  fi
  msg_ok "Configured Tor"
}

update_lnd_install() {
  local rtl_config_backup="/tmp/RTL-Config.json"

  configure_defaults
  [[ -f "$SCB_ENV_FILE" ]] && source "$SCB_ENV_FILE"
  [[ -f /etc/systemd/system/scb-backup.service ]] && ENABLE_SCB_BACKUP="yes"
  [[ -d "$RTL_DIR" && -f "$RTL_CONFIG" ]] && ENABLE_RTL="yes"
  grep -q '^ControlPort 9051$' /etc/tor/torrc 2>/dev/null && ENABLE_TOR="yes"
  grep -q "hidden_service_rtl" /etc/tor/torrc 2>/dev/null && TOR_FOR_RTL="yes"

  msg_info "Updating LND"
  systemctl stop rtl 2>/dev/null || true
  systemctl stop lnd
  install_lnd_release
  systemctl start lnd
  msg_ok "Updated LND"

  if [[ "$ENABLE_SCB_BACKUP" == "yes" ]]; then
    install_scb_backup
  fi

  if [[ -d "$RTL_DIR" && -f "$RTL_CONFIG" ]]; then
    msg_info "Updating RTL"
    systemctl stop rtl 2>/dev/null || true
    cp "$RTL_CONFIG" "$rtl_config_backup"
    install_rtl_release
    cp "$rtl_config_backup" "$RTL_CONFIG"
    chown lnd:lnd "$RTL_CONFIG"
    chmod 640 "$RTL_CONFIG"
    systemctl start rtl 2>/dev/null || true
    msg_ok "Updated RTL"
  fi

  if [[ "$ENABLE_TOR" == "yes" ]]; then
    configure_tor
  fi
}

show_post_install_notes() {
  echo
  echo -e "${INFO}${YW} Next steps:${CL}"
  echo -e "${TAB}1. Run ${BGN}sudo -u lnd lncli create${CL} to create the wallet."
  if [[ "$AUTO_UNLOCK_WALLET" == "yes" ]]; then
    echo -e "${TAB}2. Use the same password stored in ${BGN}${LND_PASSWORD_FILE}${CL}."
  fi
  if [[ "$ENABLE_RTL" == "yes" ]]; then
    echo -e "${TAB}3. RTL will become usable after ${BGN}admin.macaroon${CL} exists."
    echo -e "${TAB}${GATEWAY}${BGN}http://$(hostname -I | awk '{print $1}'):3000${CL}"
  fi
  if [[ "$TOR_FOR_RTL" == "yes" && -f "${TOR_RTL_SERVICE_DIR}/hostname" ]]; then
    echo -e "${TAB}${GATEWAY}${BGN}http://$(cat "${TOR_RTL_SERVICE_DIR}/hostname")${CL}"
  fi
  if [[ "$ENABLE_SCB_BACKUP" == "yes" ]]; then
    if [[ "$SCB_BACKUP_MODE" == "git" ]]; then
      echo -e "${TAB}4. Static channel backups are versioned in ${BGN}${SCB_BACKUP_DIR}${CL} and pushed to ${BGN}${SCB_GIT_REMOTE_URL}${CL}."
      if [[ "$SCB_GIT_AUTH_METHOD" == "ssh" && "$SCB_GIT_SSH_GENERATED" == "yes" ]]; then
        echo -e "${TAB}5. Register the generated public key before the first SSH push: ${BGN}${SCB_GIT_SSH_KEY_PATH}.pub${CL}"
      fi
    else
      echo -e "${TAB}4. Static channel backups are copied to ${BGN}${SCB_BACKUP_DIR}${CL}."
    fi
  fi
}

if [[ "${type:-}" == "update" ]]; then
  update_lnd_install
  exit 0
fi

collect_install_settings
install_dependencies
ensure_lnd_user
install_lnd_release
configure_lnd_directories
write_lnd_password_file
write_lnd_config
create_lnd_service
install_scb_backup
install_rtl
configure_tor

show_post_install_notes
motd_ssh
customize
cleanup_lxc
