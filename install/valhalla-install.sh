#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/valhalla/valhalla

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  autoconf \
  automake \
  ccache \
  clang \
  clang-tidy \
  coreutils \
  cmake \
  g++ \
  gcc \
  git \
  jq \
  lcov \
  libboost-all-dev \
  libcurl4-openssl-dev \
  libczmq-dev \
  libgdal-dev \
  libgeos++-dev \
  libgeos-dev \
  libluajit-5.1-dev \
  liblz4-dev \
  libprotobuf-dev \
  libspatialite-dev \
  libsqlite3-dev \
  libsqlite3-mod-spatialite \
  libtool \
  libzmq3-dev \
  lld \
  locales \
  luajit \
  make \
  osmium-tool \
  parallel \
  pkgconf \
  protobuf-compiler \
  python3-all-dev \
  python3-shapely \
  python3-requests \
  python3-pip \
  spatialite-bin \
  unzip \
  zlib1g-dev
msg_ok "Installed Dependencies"

PRIME_SERVER_RELEASE=$(get_latest_github_release "kevinkreiser/prime_server" "false")
msg_info "Building prime_server ${PRIME_SERVER_RELEASE} (Patience)"
git clone --recurse-submodules --depth 1 --branch "$PRIME_SERVER_RELEASE" https://github.com/kevinkreiser/prime_server /tmp/prime_server
cd /tmp/prime_server
$STD ./autogen.sh
$STD ./configure
$STD make -j"$(nproc)"
$STD make install
cd /
rm -rf /tmp/prime_server
echo "${PRIME_SERVER_RELEASE#v}" >"$HOME/.prime_server"
msg_ok "Built prime_server"

RELEASE=$(get_latest_github_release "valhalla/valhalla" "false")
msg_info "Cloning Valhalla ${RELEASE} (Patience)"
mkdir -p /opt/valhalla
git clone --recurse-submodules --depth 1 --branch "$RELEASE" https://github.com/valhalla/valhalla.git /opt/valhalla
msg_ok "Cloned Valhalla ${RELEASE}"

msg_info "Compiling Valhalla ${RELEASE} (this takes 20-45+ minutes, be patient)"
MEM_MB=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
BUILD_JOBS=$((MEM_MB / 2000))
[[ $BUILD_JOBS -lt 1 ]] && BUILD_JOBS=1
[[ $BUILD_JOBS -gt $(nproc) ]] && BUILD_JOBS=$(nproc)
cd /opt/valhalla
$STD cmake -B build -DCMAKE_BUILD_TYPE=Release -DENABLE_PYTHON_BINDINGS=OFF -DENABLE_TESTS=OFF -DENABLE_SINGLE_FILES_WERROR=OFF
$STD cmake --build build -- -j"$BUILD_JOBS"
$STD cmake --install build
ldconfig
echo "${RELEASE#v}" >"$HOME/.valhalla"
msg_ok "Compiled Valhalla ${RELEASE}"

msg_info "Configuring Valhalla"
useradd --system --no-create-home --shell /usr/sbin/nologin valhalla 2>/dev/null || true
mkdir -p /opt/valhalla_data/{valhalla_tiles,pbf}
THREADS=$(nproc)
valhalla_build_config \
  --mjolnir-tile-dir /opt/valhalla_data/valhalla_tiles \
  --mjolnir-tile-extract /opt/valhalla_data/valhalla_tiles.tar \
  --mjolnir-admin /opt/valhalla_data/admins.sqlite \
  --mjolnir-timezone /opt/valhalla_data/timezones.sqlite \
  --mjolnir-concurrency "$THREADS" \
  >/opt/valhalla_data/valhalla.json

cat <<'EOF' >/opt/valhalla_data/build-tiles.sh
#!/usr/bin/env bash
# (Re)builds Valhalla routing tiles from one or more OSM extracts.
# Usage: build-tiles.sh <pbf-url-or-path> [<pbf-url-or-path> ...]
# Example: build-tiles.sh https://download.geofabrik.de/europe/germany-latest.osm.pbf
set -euo pipefail
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <pbf-url-or-path> [<pbf-url-or-path> ...]" >&2
  exit 1
fi

DATA_DIR=/opt/valhalla_data
CONFIG="$DATA_DIR/valhalla.json"
mkdir -p "$DATA_DIR/pbf"

FILES=()
for src in "$@"; do
  if [[ "$src" == http://* || "$src" == https://* ]]; then
    fname="$DATA_DIR/pbf/$(basename "$src")"
    echo "Downloading $src"
    curl -fL --progress-bar -o "$fname" "$src"
  else
    fname="$src"
  fi
  FILES+=("$fname")
done

systemctl stop valhalla

echo "Building admin database"
valhalla_build_admins --config "$CONFIG" "${FILES[@]}"

echo "Building timezone database"
valhalla_build_timezones >"$DATA_DIR/timezones.sqlite"

echo "Building initial tile graph"
valhalla_build_tiles -c "$CONFIG" -e build "${FILES[@]}"

echo "Enhancing tile graph"
valhalla_build_tiles -c "$CONFIG" -s enhance "${FILES[@]}"

echo "Packing tiles into a single extract"
valhalla_build_extract -c "$CONFIG" -v

chown -R valhalla:valhalla "$DATA_DIR"
systemctl start valhalla
echo "Done. Tiles are in $DATA_DIR/valhalla_tiles (and packed at $DATA_DIR/valhalla_tiles.tar)."
EOF
chmod +x /opt/valhalla_data/build-tiles.sh
chown -R valhalla:valhalla /opt/valhalla_data
msg_ok "Configured Valhalla"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/valhalla.service
[Unit]
Description=Valhalla Routing Engine
After=network.target

[Service]
Type=simple
User=valhalla
Group=valhalla
WorkingDirectory=/opt/valhalla_data
ExecStart=/usr/local/bin/valhalla_service /opt/valhalla_data/valhalla.json ${THREADS}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now valhalla
msg_ok "Created Service"

if [[ -n "${VALHALLA_PBF_URLS:-}" ]]; then
  msg_info "Building Initial Tiles from VALHALLA_PBF_URLS (this can take a long time)"
  $STD /opt/valhalla_data/build-tiles.sh $VALHALLA_PBF_URLS
  msg_ok "Built Initial Tiles"
fi

motd_ssh
customize
cleanup_lxc
