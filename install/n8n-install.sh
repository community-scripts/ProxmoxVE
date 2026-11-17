#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster) | Co-Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://n8n.io/ | Github: https://github.com/n8n-io/n8n

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# n8n 3.x is no longer published to npm, only as a Docker image. Its Debian
# variant (n8nio/n8n:<version>-debian) is Node.js plus a prebuilt app folder, so
# pull it with skopeo (no container runtime) and run that folder natively. n8n
# 2.x has no Debian image for every release and still comes from npm. The
# version follows the image's "latest" tag, so new installs switch to 3.x when
# n8n promotes it.
# var_n8n_image_tag set to a version (e.g. 3.3.0) pins that release instead.
N8N_IMAGE_TAG="${var_n8n_image_tag:-latest}"

msg_info "Installing Dependencies"
$STD apt install -y \
  graphicsmagick \
  git \
  openssh-client \
  tzdata \
  ca-certificates \
  jq
$STD apt install -y --no-install-recommends skopeo
msg_ok "Installed Dependencies"

msg_info "Checking the latest n8n release"
N8N_VERSION="$(skopeo inspect --override-os linux --override-arch "$(arch_resolve amd64 arm64)" "docker://docker.io/n8nio/n8n:${N8N_IMAGE_TAG}" 2>/dev/null |
  jq -r '.Labels["org.opencontainers.image.version"] // empty')" || true
if [[ ! "$N8N_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  msg_error "Could not read the n8n version of n8nio/n8n:${N8N_IMAGE_TAG}."
  exit 115
fi
msg_ok "Latest n8n release is ${N8N_VERSION}"

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

if ((${N8N_VERSION%%.*} >= 3)); then
  fetch_n8n_image "$N8N_VERSION"

  NODE_VERSION="$N8N_NODE_MAJOR" setup_nodejs

  msg_info "Installing n8n ${N8N_VERSION}"
  # The runtime libraries the n8n base image adds on top of Node.js.
  $STD apt install -y --no-install-recommends libaio1t64 libsasl2-2 libssl3t64 liblz4-1 libzstd1 libxxhash0 zlib1g
  mv "${N8N_BUNDLE}/usr/local/lib/node_modules/n8n" /opt/n8n
  if [[ -d "${N8N_BUNDLE}/usr/share/fonts/truetype/msttcorefonts" ]]; then
    mkdir -p /usr/share/fonts/truetype
    cp -a "${N8N_BUNDLE}/usr/share/fonts/truetype/msttcorefonts" /usr/share/fonts/truetype/
  fi
  rm -rf "$N8N_BUNDLE"
  mkdir -p /usr/local/bin
  ln -sf /opt/n8n/bin/n8n /usr/local/bin/n8n
  if ! /usr/local/bin/n8n --version 2>/dev/null | grep -qxF "$N8N_VERSION"; then
    msg_error "n8n ${N8N_VERSION} does not start in this container."
    exit 1
  fi
  echo "$N8N_VERSION" >~/.n8n-version
  msg_ok "Installed n8n ${N8N_VERSION}"
else
  $STD apt install -y build-essential python3-setuptools
  NODE_VERSION="24" setup_nodejs

  msg_info "Installing n8n (Patience)"
  # n8n-nodes-base 2.46.0 pins both @napi-rs/canvas musl binaries as hard
  # dependencies, which no os/cpu/libc combination can satisfy. Drop --force
  # once upstream makes them optional again.
  $STD npm install -g n8n@latest --force
  msg_ok "Installed n8n"
fi

msg_info "Creating Service"
cat <<EOF >/opt/n8n.env
N8N_SECURE_COOKIE=false
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_HOST=${LOCAL_IP}
EOF

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
systemctl enable -q --now n8n
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
