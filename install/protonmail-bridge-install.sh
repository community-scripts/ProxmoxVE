#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Stephen Chin (steveonjava)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ProtonMail/proton-bridge

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y pass
msg_ok "Installed Dependencies"

msg_info "Creating Service User"
useradd -r -m -d /home/protonbridge -s /usr/sbin/nologin protonbridge
install -d -m 0750 -o protonbridge -g protonbridge /home/protonbridge
msg_ok "Created Service User"

fetch_and_deploy_gh_release "protonmail-bridge" "ProtonMail/proton-bridge" "binary"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/protonmail-bridge.service
[Unit]
Description=Proton Mail Bridge (noninteractive)
After=network-online.target
Wants=network-online.target
ConditionPathExists=/home/protonbridge/.protonmailbridge-initialized

[Service]
Type=simple
User=protonbridge
Group=protonbridge
WorkingDirectory=/home/protonbridge
Environment=HOME=/home/protonbridge
ExecStart=/usr/bin/protonmail-bridge --noninteractive
Restart=always
RestartSec=3
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=full
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes

[Install]
WantedBy=multi-user.target
EOF
cat <<'EOF' >/etc/systemd/system/protonmail-bridge-imap.socket
[Unit]
Description=Proton Mail Bridge IMAP Socket (143)
ConditionPathExists=/home/protonbridge/.protonmailbridge-initialized

[Socket]
ListenStream=143
Accept=no
Service=protonmail-bridge-imap-proxy.service

[Install]
WantedBy=sockets.target
EOF
cat <<'EOF' >/etc/systemd/system/protonmail-bridge-imap-proxy.service
[Unit]
Description=Proton Mail Bridge IMAP Proxy (143 -> 127.0.0.1:1143)
After=protonmail-bridge.service
Requires=protonmail-bridge.service
ConditionPathExists=/home/protonbridge/.protonmailbridge-initialized

[Service]
Type=simple
Sockets=protonmail-bridge-imap.socket
ExecStart=/usr/lib/systemd/systemd-socket-proxyd 127.0.0.1:1143
NoNewPrivileges=yes
PrivateTmp=yes
EOF
cat <<'EOF' >/etc/systemd/system/protonmail-bridge-smtp.socket
[Unit]
Description=Proton Mail Bridge SMTP Socket (587)
ConditionPathExists=/home/protonbridge/.protonmailbridge-initialized

[Socket]
ListenStream=587
Accept=no
Service=protonmail-bridge-smtp-proxy.service

[Install]
WantedBy=sockets.target
EOF
cat <<'EOF' >/etc/systemd/system/protonmail-bridge-smtp-proxy.service
[Unit]
Description=Proton Mail Bridge SMTP Proxy (587 -> 127.0.0.1:1025)
After=protonmail-bridge.service
Requires=protonmail-bridge.service
ConditionPathExists=/home/protonbridge/.protonmailbridge-initialized

[Service]
Type=simple
Sockets=protonmail-bridge-smtp.socket
ExecStart=/usr/lib/systemd/systemd-socket-proxyd 127.0.0.1:1025
NoNewPrivileges=yes
PrivateTmp=yes
EOF
msg_ok "Created Services"

msg_info "Creating Helper Commands"

cat <<'EOF' >/usr/local/bin/protonmailbridge-configure
#!/usr/bin/env bash
set -euo pipefail

BRIDGE_USER="protonbridge"
BRIDGE_HOME="/home/${BRIDGE_USER}"
GNUPG_HOME="${BRIDGE_HOME}/.gnupg"
MARKER="${BRIDGE_HOME}/.protonmailbridge-initialized"

FIRST_TIME=0
if [[ ! -f "${MARKER}" ]]; then
  FIRST_TIME=1
fi

# Stop sockets/proxies/bridge daemon before configuration
systemctl stop protonmail-bridge-imap.socket protonmail-bridge-smtp.socket
systemctl stop protonmail-bridge-imap-proxy protonmail-bridge-smtp-proxy protonmail-bridge

if [[ "${FIRST_TIME}" == "1" ]]; then
  echo "First-time setup: initializing pass keychain for ${BRIDGE_USER} (required by Proton Mail Bridge on Linux)."

  install -d -m 0700 -o "${BRIDGE_USER}" -g "${BRIDGE_USER}" "${GNUPG_HOME}"

  FPR="$(runuser -u "${BRIDGE_USER}" -- env HOME="${BRIDGE_HOME}" GNUPGHOME="${GNUPG_HOME}" \
    gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '$1=="fpr"{print $10; exit}')"

  if [[ -z "${FPR}" ]]; then
    runuser -u "${BRIDGE_USER}" -- env HOME="${BRIDGE_HOME}" GNUPGHOME="${GNUPG_HOME}" \
      gpg --batch --pinentry-mode loopback --passphrase '' \
      --quick-gen-key 'ProtonMail Bridge' default default never

    FPR="$(runuser -u "${BRIDGE_USER}" -- env HOME="${BRIDGE_HOME}" GNUPGHOME="${GNUPG_HOME}" \
      gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '$1=="fpr"{print $10; exit}')"
  fi

  if [[ -z "${FPR}" ]]; then
    echo "Failed to detect a GPG key fingerprint for ${BRIDGE_USER}." >&2
    exit 1
  fi

  runuser -u "${BRIDGE_USER}" -- env HOME="${BRIDGE_HOME}" GNUPGHOME="${GNUPG_HOME}" \
    pass init "${FPR}"

  echo
  echo "To do initial configuration of the Proton Mail Bridge:"
  echo "Run: login"
  echo "Run: info"
  echo "Run: exit"
  echo
else
  echo
  echo "Launching Proton Mail Bridge CLI for configuration."
  echo "External access is disabled until you exit."
  echo "Run: exit"
  echo
fi

runuser -u "${BRIDGE_USER}" -- env HOME="${BRIDGE_HOME}" \
  protonmail-bridge -c

if [[ "${FIRST_TIME}" == "1" ]]; then
  touch "${MARKER}"
  chown "${BRIDGE_USER}:${BRIDGE_USER}" "${MARKER}"
  chmod 0644 "${MARKER}"
fi

systemctl enable -q --now protonmail-bridge.service protonmail-bridge-imap.socket protonmail-bridge-smtp.socket

if [[ "${FIRST_TIME}" == "1" ]]; then
  echo "Initialization complete. Services enabled and started."
else
  echo "Configuration complete. Services enabled and started."
fi
EOF
chmod +x /usr/local/bin/protonmailbridge-configure
ln -sf /usr/local/bin/protonmailbridge-configure /usr/bin/protonmailbridge-configure
msg_ok "Created Helper Commands"

motd_ssh
customize
cleanup_lxc
