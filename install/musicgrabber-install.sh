#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gitlab.com/g33kphr33k/musicgrabber

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  libchromaprint-tools \
  xauth \
  xvfb
msg_ok "Installed Dependencies"

setup_ffmpeg
PYTHON_VERSION="3.12" setup_uv
fetch_and_deploy_gh_release "yt-dlp" "yt-dlp/yt-dlp" "singlefile" "latest" "/usr/local/bin" "yt-dlp_$(arch_resolve "linux" "linux_aarch64")"
fetch_and_deploy_gh_release "deno" "denoland/deno" "prebuild" "latest" "/usr/local/bin" "deno-$(arch_resolve "x86_64" "aarch64")-unknown-linux-gnu.zip"
fetch_and_deploy_gl_tag "musicgrabber" "g33kphr33k/musicgrabber" "v*"

msg_info "Setting up MusicGrabber"
cd /opt/musicgrabber
$STD uv venv --python 3.12 .venv
$STD uv pip install --python .venv/bin/python \
  "fastapi~=0.162.0" \
  "uvicorn[standard]~=0.54.0" \
  "httpx~=0.28.1" \
  "pydantic~=2.14.1" \
  "mutagen~=1.48.1" \
  "playwright~=1.64.1" \
  "apprise>=1.13.1,<2" \
  "bcrypt~=4.3.0" \
  "pycryptodome~=4.2.0" \
  "certifi>=2026.10.18" \
  "seleniumbase>=4.54,<5"
PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright $STD .venv/bin/playwright install --with-deps chromium
msg_ok "Set up MusicGrabber"

msg_info "Installing Browser for SeleniumBase"
if [[ "$(arch_resolve)" == "amd64" ]]; then
  setup_deb822_repo \
    "google-chrome" \
    "https://dl.google.com/linux/linux_signing_key.pub" \
    "https://dl.google.com/linux/chrome/deb/" \
    "stable"
  $STD apt install -y google-chrome-stable
  rm -f /etc/apt/sources.list.d/google-chrome.list
  $STD .venv/bin/sbase get uc_driver stable
else
  $STD apt install -y chromium chromium-driver
  install -m 755 /usr/bin/chromedriver .venv/lib/python3.12/site-packages/seleniumbase/drivers/uc_driver
fi
$STD .venv/bin/python -c "from pathlib import Path; import seleniumbase; from seleniumbase.undetected.patcher import Patcher; driver = Path(seleniumbase.__file__).parent / 'drivers' / 'uc_driver'; Patcher(executable_path=str(driver)).auto(); driver.chmod(0o755)"
msg_ok "Installed Browser for SeleniumBase"

msg_info "Setting up FLAC Verifier"
$STD uv venv --python 3.12 /opt/flac-verifier
$STD uv pip install --python /opt/flac-verifier/bin/python "numpy==2.2.6" "scipy==1.15.3" "soundfile==0.13.1" "mutagen==1.47.0"
msg_ok "Set up FLAC Verifier"
fetch_and_deploy_from_url "https://codeload.github.com/FraysKosher/flac-verifier/tar.gz/$(grep -oP 'FraysKosher/flac-verifier/tar.gz/\K[0-9a-f]+' /opt/musicgrabber/Dockerfile)" "/opt/flac-verifier/engine"

msg_info "Configuring MusicGrabber"
mkdir -p /opt/musicgrabber_data/music
cat <<EOF >/opt/musicgrabber_data/.env
MUSIC_DIR=/opt/musicgrabber_data/music
DB_PATH=/opt/musicgrabber_data/music_grabber.db
LISTEN_ADDR=0.0.0.0
LISTEN_PORT=8080
PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright
PYTHONUNBUFFERED=1
EOF
msg_ok "Configured MusicGrabber"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/musicgrabber.service
[Unit]
Description=MusicGrabber
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/musicgrabber
EnvironmentFile=/opt/musicgrabber_data/.env
Environment=PATH=/opt/musicgrabber/.venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStartPre=-/usr/bin/timeout 45 /usr/local/bin/yt-dlp -U
ExecStart=/opt/musicgrabber/.venv/bin/uvicorn app:app --host \${LISTEN_ADDR} --port \${LISTEN_PORT}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now musicgrabber
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
