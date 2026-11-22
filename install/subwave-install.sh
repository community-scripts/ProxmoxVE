#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/perminder-klair/subwave

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

var_admin_user="${var_admin_user:-admin}"
var_admin_pass="${var_admin_pass:-$(random_password)}"

msg_info "Installing Dependencies"
$STD apt install -y \
  caddy \
  espeak-ng \
  libsndfile1
msg_ok "Installed Dependencies"

setup_ffmpeg
NODE_VERSION="24" setup_nodejs
PYTHON_VERSION="3.12" setup_uv

# Upstream's broadcast image runs Icecast-KH from deb-multimedia (trusted-proxy list, listener auth); the pin keeps every other package on Debian's build
cat <<EOF >/etc/apt/preferences.d/deb-multimedia
Package: *
Pin: origin www.deb-multimedia.org
Pin-Priority: 100

Package: icecast2
Pin: origin www.deb-multimedia.org
Pin-Priority: 990
EOF
setup_deb822_repo "deb-multimedia" "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xA401FF99368FA1F98152DE755C808C2B65558117" "https://www.deb-multimedia.org" "trixie" "main"

msg_info "Installing Icecast-KH"
$STD apt install -y icecast2
systemctl disable -q --now icecast2
msg_ok "Installed Icecast-KH"

fetch_and_deploy_gh_release "subwave" "perminder-klair/subwave" "tarball"
fetch_and_deploy_gh_release "liquidsoap" "savonet/liquidsoap" "binary" "$(grep -oP 'savonet/liquidsoap:\Kv[0-9.]+' /opt/subwave/docker/Dockerfile.broadcast)" "" "liquidsoap_*-debian-trixie-ocaml4.14.2-*_$(arch_resolve).deb"
fetch_and_deploy_gh_release "piper" "rhasspy/piper" "prebuild" "latest" "/opt/piper" "piper_linux_$(arch_resolve "x86_64" "aarch64").tar.gz"

msg_info "Downloading Voice Models"
mkdir -p /opt/piper/voices /opt/kokoro/models
curl_with_retry "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/alan/medium/en_GB-alan-medium.onnx" "/opt/piper/voices/en_GB-alan-medium.onnx"
curl_with_retry "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/alan/medium/en_GB-alan-medium.onnx.json" "/opt/piper/voices/en_GB-alan-medium.onnx.json"
# model-files-v1.0, not v1.1: same weights, but v1.1 renders ~3.7 dB quieter (upstream Dockerfile.aio)
curl_with_retry "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.onnx" "/opt/kokoro/models/kokoro-v1.0.onnx"
curl_with_retry "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin" "/opt/kokoro/models/voices-v1.0.bin"
msg_ok "Downloaded Voice Models"

msg_info "Setting up Analyzer and Kokoro"
$STD uv venv --python 3.12 /opt/analyzer/venv
$STD uv pip install --python /opt/analyzer/venv/bin/python librosa==0.11.0 soundfile==0.14.0 pyloudnorm==0.2.0
$STD uv venv --python 3.12 /opt/kokoro/venv
$STD uv pip install --python /opt/kokoro/venv/bin/python kokoro-onnx==0.5.0 soundfile==0.12.1 misaki==0.9.4 pyopenjtalk-plus==0.4.1.post10 cn2an==0.5.24 jieba==0.42.1 ordered-set==4.1.0 pypinyin==0.55.0 pypinyin-dict==0.9.0
msg_ok "Set up Analyzer and Kokoro"

msg_info "Building Subwave"
cd /opt/subwave/controller
$STD npm ci --omit=dev
cd /opt/subwave/web
$STD npm ci
NEXT_TELEMETRY_DISABLED=1 $STD npm run build
cp -r public content .next/standalone/
cp -r .next/static .next/standalone/.next/
rm -rf node_modules .next/cache ~/.npm
msg_ok "Built Subwave"

msg_info "Configuring Subwave"
mkdir -p /opt/subwave_data/state /etc/liquidsoap
# Upstream hardcodes its container paths: /app (controller, cwd of the tagger/analyzer), /sounds and /var/sub-wave (state)
ln -sfn /opt/subwave/controller /app
ln -sfn /opt/subwave/sounds /sounds
ln -sfn /opt/subwave_data/state /var/sub-wave
mkdir -p /var/sub-wave/logs
rm -rf /var/log/liquidsoap
ln -sfn /var/sub-wave/logs /var/log/liquidsoap
cp /opt/subwave/docker/icecast.xml.template /etc/icecast2/icecast.xml.template
cp /opt/subwave/liquidsoap/radio.liq /etc/liquidsoap/radio.liq
# Liquidsoap's telnet control has no auth; the containers never publish it, here it would face the LAN
sed -i 's/^settings.server.telnet.bind_addr := .*/settings.server.telnet.bind_addr := "127.0.0.1"/' /etc/liquidsoap/radio.liq
cp /opt/subwave/docker/aio/Caddyfile /etc/caddy/Caddyfile
cat <<EOF >/opt/subwave_data/.env
NODE_ENV=production
ADMIN_USER=${var_admin_user}
ADMIN_PASS=${var_admin_pass}
SITE_URL=http://${LOCAL_IP}
STATE_DIR=/var/sub-wave
SOUNDS_DIR=/sounds
HF_HOME=/var/sub-wave/hf-cache
LIQUIDSOAP_HOST=127.0.0.1
ICECAST_STATUS_URL=http://127.0.0.1:7702/status-json.xsl
ICECAST_ADMIN_URL=http://127.0.0.1:7702/admin/listclients
ICECAST_TRUSTED_PROXY_IPS=127.0.0.1
LISTENER_AUTH_URL=http://127.0.0.1:7701/listener-auth
CONTROLLER_INTERNAL_URL=http://127.0.0.1:7701
PIPER_BIN=/opt/piper/piper
ANALYZE_PYTHON=/opt/analyzer/venv/bin/python
EOF
chmod 600 /opt/subwave_data/.env
cat <<EOF >~/subwave.creds
Subwave Admin
Username: ${var_admin_user}
Password: ${var_admin_pass}
EOF
chmod 600 ~/subwave.creds
systemctl restart caddy
msg_ok "Configured Subwave"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/subwave-broadcast.service
[Unit]
Description=Subwave Broadcast (Icecast + Liquidsoap)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
EnvironmentFile=/opt/subwave_data/.env
ExecStart=/usr/bin/bash /opt/subwave/docker/broadcast-entrypoint.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/subwave-controller.service
[Unit]
Description=Subwave Controller
After=network-online.target subwave-broadcast.service
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/subwave/controller
EnvironmentFile=/opt/subwave_data/.env
ExecStart=/opt/subwave/controller/node_modules/.bin/tsx src/server.ts
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/subwave-web.service
[Unit]
Description=Subwave Web
After=network-online.target subwave-controller.service

[Service]
Type=simple
WorkingDirectory=/opt/subwave/web/.next/standalone
EnvironmentFile=/opt/subwave_data/.env
Environment=PORT=7700
Environment=HOSTNAME=127.0.0.1
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now subwave-broadcast subwave-controller subwave-web
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
