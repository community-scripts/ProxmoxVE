#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: chverma
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rhasspy/wyoming-faster-whisper

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  ffmpeg \
  curl \
  build-essential \
  python3 \
  python3-pip \
  python3-venv
msg_ok "Installed Dependencies"

msg_info "Cloning Wyoming Faster Whisper Repository"
cd /opt
$STD git clone https://github.com/rhasspy/wyoming-faster-whisper.git wyoming-faster-whisper
cd /opt/wyoming-faster-whisper
msg_ok "Cloned Repository"

msg_info "Setting up Python Environment"
$STD /opt/wyoming-faster-whisper/script/setup
msg_ok "Python Environment Setup Complete"

msg_info "Creating data directories"
mkdir -p /opt/wyoming-faster-whisper/data
msg_ok "Created data directories"

msg_info "Creating helper script"
cat <<'HELPER' >/usr/local/bin/whisper-service
#!/bin/bash
case "$1" in
  start)
    systemctl start wyoming-whisper
    ;;
  stop)
    systemctl stop wyoming-whisper
    ;;
  restart)
    systemctl restart wyoming-whisper
    ;;
  status)
    systemctl status wyoming-whisper
    ;;
  logs)
    journalctl -u wyoming-whisper -f
    ;;
  test)
    /opt/wyoming-faster-whisper/script/run --model tiny-int8 --language en --uri tcp://0.0.0.0:10300 --data-dir /opt/wyoming-faster-whisper/data --download-dir /opt/wyoming-faster-whisper/data
    ;;
  *)
    echo "Usage: whisper-service {start|stop|restart|status|logs|test}"
    exit 1
    ;;
esac
HELPER
chmod +x /usr/local/bin/whisper-service
msg_ok "Created helper script"

msg_info "Creating Service"
cat <<'EOF' >/etc/systemd/system/wyoming-whisper.service
[Unit]
Description=Wyoming Faster Whisper
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/wyoming-faster-whisper
ExecStart=/opt/wyoming-faster-whisper/script/run \
  --model tiny-int8 \
  --language en \
  --uri tcp://0.0.0.0:10300 \
  --data-dir /opt/wyoming-faster-whisper/data \
  --download-dir /opt/wyoming-faster-whisper/data
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable -q --now wyoming-whisper
msg_ok "Created Service"

msg_info "Verifying Service Status"
sleep 3
if systemctl is-active --quiet wyoming-whisper; then
  msg_ok "Wyoming Whisper Service is running"
else
  msg_error "Wyoming Whisper Service failed to start"
  systemctl status wyoming-whisper --no-pager
fi

echo -e "\n${GN}To change the model or language:${CL}"
echo -e "${YW}Edit:${CL} /etc/systemd/system/wyoming-whisper.service"
echo -e "${YW}Available models:${CL} tiny-int8, base-int8, small-int8, medium-int8, large-v3"
echo -e "${YW}After editing, run:${CL} systemctl daemon-reload && systemctl restart wyoming-whisper\n"

motd_ssh
customize
cleanup_lxc
