#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://n8n.io/ | Github: https://github.com/n8n-io/n8n

APP="n8n"
var_tags="${var_tags:-automation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

# The n8nio/n8n image tag to follow: "latest" is n8n's current stable release.
# var_n8n_image_tag set to a version (e.g. 3.3.0) pins that release,
# prereleases included.
N8N_IMAGE_TAG="${var_n8n_image_tag:-latest}"
# Moving from 2.x to 3.x cannot be undone, so the update asks first. Unattended,
# var_force_breaking_update=yes answers yes; anything else keeps 2.x.
N8N_FORCE_MAJOR="${var_force_breaking_update:-no}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/n8n.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if [ ! -f /opt/n8n.env ]; then
    sed -i 's|^Environment="N8N_SECURE_COOKIE=false"$|EnvironmentFile=/opt/n8n.env|' /etc/systemd/system/n8n.service
    mkdir -p /opt
    cat <<EOF >/opt/n8n.env
N8N_SECURE_COOKIE=false
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_HOST=$LOCAL_IP
EOF
    systemctl daemon-reload
  fi

  ensure_dependencies jq
  if ! command -v skopeo >/dev/null 2>&1 &&
    ! $STD apt install -y --no-install-recommends skopeo; then
    msg_error "Could not install skopeo, which n8n needs for its updates. n8n was not updated."
    exit 105
  fi

  # n8n 3.x is no longer published to npm, only as a Docker image. 2.x still
  # updates through npm; 3.x comes from the image (see fetch_n8n_image).
  msg_info "Checking the latest n8n release"
  local target
  target="$(skopeo inspect --override-os linux --override-arch "$(arch_resolve amd64 arm64)" "docker://docker.io/n8nio/n8n:${N8N_IMAGE_TAG}" 2>/dev/null |
    jq -r '.Labels["org.opencontainers.image.version"] // empty')" || true
  if [[ ! "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    msg_error "Could not read the n8n version of n8nio/n8n:${N8N_IMAGE_TAG}. n8n was not updated."
    exit 115
  fi
  msg_ok "Latest n8n release is ${target}"

  local current=""
  if [[ -f /opt/n8n/package.json ]]; then
    current="$(cat ~/.n8n-version 2>/dev/null)" || true
    [[ -n "$current" ]] || current="$(jq -r '.version // empty' /opt/n8n/package.json)"
    if [[ "$current" == "$target" ]]; then
      msg_ok "n8n is already at ${target}"
      exit
    fi
    if ((${target%%.*} < 3)); then
      msg_warn "n8n ${current} cannot go back to ${target}; nothing was changed."
      exit
    fi
  else
    if ((${target%%.*} < 3)); then
      update_n8n_npm
      exit
    fi
    local npm_root
    npm_root="$(npm root -g 2>/dev/null)" || true
    [[ -n "$npm_root" && -f "${npm_root}/n8n/package.json" ]] && current="$(jq -r '.version // empty' "${npm_root}/n8n/package.json")"
    echo
    msg_warn "n8n ${target} is out. From 3.0 on, n8n is not published to npm any more."
    echo -e "${TAB}This update moves n8n ${current:-2.x} to ${target}, unpacked from the official Docker image."
    echo -e "${TAB}There is no way back to 2.x afterwards. 3.0 removes legacy nodes (Function, Cron,"
    echo -e "${TAB}Interval, Read/Write Binary File, ...). Check Settings > Migration Report in n8n first."
    echo -e "${TAB}The SQLite data in ~/.n8n is backed up first; an external database is not."
    echo -e "${TAB}Declining keeps n8n on 2.x, which gets security fixes for 12 months after 3.x."
    echo
    if [[ ! "${N8N_FORCE_MAJOR,,}" =~ ^(1|yes|true|on)$ ]] && ! prompt_confirm "Upgrade n8n to ${target}?" "n" 300; then
      msg_warn "Staying on n8n 2.x"
      update_n8n_npm
      exit
    fi
  fi

  fetch_n8n_image "$target"

  msg_info "Stopping n8n"
  systemctl stop n8n
  msg_ok "Stopped n8n"

  if [[ ! -f /opt/n8n/package.json ]]; then
    local data_parent backup
    data_parent="$(sed -n 's/^N8N_USER_FOLDER=//p' /opt/n8n.env | tail -n1)"
    data_parent="${data_parent:-/root}"
    if [[ -d "${data_parent}/.n8n" ]]; then
      msg_info "Backing up n8n data"
      backup="/root/n8n-backup-${current:-2.x}-$(date +%Y%m%d-%H%M%S).tar.gz"
      tar -czf "$backup" -C "$data_parent" .n8n
      msg_ok "Backed up n8n data to ${backup}"
    fi
    msg_info "Removing the npm install of n8n"
    $STD npm uninstall -g n8n || true
    cat <<EOF >/etc/systemd/system/n8n.service
[Unit]
Description=n8n
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Environment=NODE_ENV=production
EnvironmentFile=/opt/n8n.env
ExecStart=/usr/bin/env n8n start
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    msg_ok "Removed the npm install of n8n"
  fi

  NODE_VERSION="$N8N_NODE_MAJOR" setup_nodejs
  install_n8n_image "$target"

  msg_info "Starting n8n"
  systemctl start n8n
  msg_ok "Started n8n"
  msg_ok "Updated successfully!"
  exit
}

# n8n 2.x: the npm package, as before.
function update_n8n_npm() {
  ensure_dependencies build-essential python3-setuptools graphicsmagick
  NODE_VERSION="24" setup_nodejs

  local installed latest
  installed="$(jq -r '.version // empty' "$(npm root -g)/n8n/package.json" 2>/dev/null)" || true
  latest="$(npm view n8n@latest version 2>/dev/null)" || true
  if [[ -n "$latest" && "$installed" == "$latest" ]]; then
    msg_ok "n8n is already at ${latest}"
    return 0
  fi

  msg_info "Updating n8n"
  # n8n-nodes-base 2.46.0 pins both @napi-rs/canvas musl binaries as hard
  # dependencies, which no os/cpu/libc combination can satisfy. Drop --force
  # once upstream makes them optional again.
  $STD npm install -g n8n@latest --force
  systemctl restart n8n
  msg_ok "Updated n8n"
  msg_ok "Updated successfully!"
}

# Downloads n8nio/n8n:<version>-debian and extracts only its app folder
# (/usr/local/lib/node_modules/n8n) and fonts into N8N_BUNDLE, a folder under
# /opt laid out like the image; sets N8N_NODE_MAJOR. n8n compresses the layers
# with zstd, which the umoci in Debian cannot read, so skopeo stores them
# uncompressed and tar applies them in order, whiteouts included. Only regular
# files, folders and symlinks are written, so no container runtime is needed.
function fetch_n8n_image() {
  local version="$1" image blob list wh dir name p config
  local -a paths=(usr/local/lib/node_modules/n8n usr/share/fonts/truetype/msttcorefonts) members
  msg_info "Downloading n8n ${version} (Patience)"
  # Under /opt, on the same filesystem as /opt/n8n: the app folder is moved, not copied.
  image="$(mktemp -d -p /opt)"
  N8N_BUNDLE="$(mktemp -d -p /opt)"
  if ! $STD skopeo copy --dest-decompress --override-os linux --override-arch "$(arch_resolve amd64 arm64)" \
    "docker://docker.io/n8nio/n8n:${version}-debian" "dir:${image}/img"; then
    rm -rf "$image" "$N8N_BUNDLE"
    msg_error "Could not download n8nio/n8n:${version}-debian."
    exit 115
  fi
  while read -r blob; do
    blob="${image}/img/${blob#sha256:}"
    list="$(tar -tf "$blob")" || list=""
    while read -r wh; do
      [[ -n "$wh" ]] || continue
      dir="$(dirname "$wh")" name="$(basename "$wh")"
      if [[ "$name" == ".wh..wh..opq" ]]; then
        [[ -d "${N8N_BUNDLE}/${dir}" ]] && find "${N8N_BUNDLE}/${dir}" -mindepth 1 -delete
      else
        rm -rf "${N8N_BUNDLE:?}/${dir}/${name#.wh.}"
      fi
    done < <(grep -E '(^|/)\.wh\.[^/]*$' <<<"$list" | grep -E "^($(
      IFS='|'
      echo "${paths[*]}"
    ))(/|$)" || true)
    members=()
    for p in "${paths[@]}"; do
      grep -qE "^${p}(/|$)" <<<"$list" && members+=("$p")
    done
    ((${#members[@]})) || continue
    if ! tar -xf "$blob" -C "$N8N_BUNDLE" --no-same-owner --exclude='.wh.*' "${members[@]}"; then
      rm -rf "$image" "$N8N_BUNDLE"
      msg_error "Could not unpack the n8n ${version} image."
      exit 1
    fi
  done < <(jq -r '.layers[].digest' "${image}/img/manifest.json")
  # The native modules in the image are built for its Node.js major version.
  config="${image}/img/$(jq -r '.config.digest | ltrimstr("sha256:")' "${image}/img/manifest.json")"
  N8N_NODE_MAJOR="$(jq -r '.config.Env[] | select(startswith("NODE_VERSION=")) | ltrimstr("NODE_VERSION=") | split(".")[0]' "$config" 2>/dev/null)" || true
  rm -rf "$image"
  if [[ ! "$N8N_NODE_MAJOR" =~ ^[0-9]+$ || ! -f "${N8N_BUNDLE}/usr/local/lib/node_modules/n8n/package.json" ]]; then
    rm -rf "$N8N_BUNDLE"
    msg_error "The n8n ${version} image does not have the expected layout."
    exit 1
  fi
  msg_ok "Downloaded n8n ${version}"
}

function install_n8n_image() {
  local version="$1"
  msg_info "Installing n8n ${version}"
  # The runtime libraries the n8n base image adds on top of Node.js.
  ensure_dependencies git openssh-client tzdata ca-certificates graphicsmagick \
    libaio1t64 libsasl2-2 libssl3t64 liblz4-1 libzstd1 libxxhash0 zlib1g
  rm -rf /opt/n8n
  mv "${N8N_BUNDLE}/usr/local/lib/node_modules/n8n" /opt/n8n
  if [[ -d "${N8N_BUNDLE}/usr/share/fonts/truetype/msttcorefonts" ]]; then
    mkdir -p /usr/share/fonts/truetype
    rm -rf /usr/share/fonts/truetype/msttcorefonts
    cp -a "${N8N_BUNDLE}/usr/share/fonts/truetype/msttcorefonts" /usr/share/fonts/truetype/
  fi
  rm -rf "$N8N_BUNDLE"
  mkdir -p /usr/local/bin
  ln -sf /opt/n8n/bin/n8n /usr/local/bin/n8n
  if ! /usr/local/bin/n8n --version 2>/dev/null | grep -qxF "$version"; then
    msg_error "n8n ${version} does not start in this container."
    exit 1
  fi
  echo "$version" >~/.n8n-version
  msg_ok "Installed n8n ${version}"
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:5678${CL}"
