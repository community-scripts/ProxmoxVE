#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://immich.app

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_uv

msg_info "Installing dependencies"
$STD apt install --no-install-recommends -y \
  git \
  redis \
  autoconf \
  build-essential \
  python3-dev \
  automake \
  cmake \
  jq \
  libtool \
  libltdl-dev \
  libgdk-pixbuf-2.0-dev \
  libbrotli-dev \
  libde265-dev \
  libexif-dev \
  libexpat1-dev \
  libglib2.0-dev \
  libgsf-1-dev \
  libjpeg62-turbo-dev \
  libspng-dev \
  liblcms2-dev \
  libopenexr-dev \
  libgif-dev \
  librsvg2-dev \
  libexpat1 \
  libgcc-s1 \
  libgomp1 \
  liblqr-1-0 \
  libltdl7 \
  libopenjp2-7 \
  meson \
  ninja-build \
  pkg-config \
  mesa-utils \
  mesa-va-drivers \
  mesa-vulkan-drivers \
  ocl-icd-libopencl1 \
  tini \
  zlib1g \
  libio-compress-brotli-perl \
  libwebp7 \
  libwebpdemux2 \
  libwebpmux3 \
  libhwy1t64 \
  libdav1d-dev \
  libhwy-dev \
  libwebp-dev \
  libaom-dev \
  ccache

setup_deb822_repo \
  "jellyfin" \
  "https://repo.jellyfin.org/jellyfin_team.gpg.key" \
  "https://repo.jellyfin.org/debian" \
  "$(get_os_info codename)"
$STD apt install -y jellyfin-ffmpeg7
ln -sf /usr/lib/jellyfin-ffmpeg/ffmpeg /usr/bin/ffmpeg
ln -sf /usr/lib/jellyfin-ffmpeg/ffprobe /usr/bin/ffprobe

if [[ "$CTTYPE" == "0" && -d /dev/dri ]]; then
  chgrp video /dev/dri
  chmod 755 /dev/dri
  chmod 660 /dev/dri/*
  $STD adduser "$(id -u -n)" video
  $STD adduser "$(id -u -n)" render
fi
msg_ok "Dependencies Installed"

msg_info "Installing Mise"
curl -fSs https://mise.jdx.dev/gpg-key.pub | tee /etc/apt/keyrings/mise-archive-keyring.pub 1>/dev/null
echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.pub arch=amd64] https://mise.jdx.dev/deb stable main" | tee /etc/apt/sources.list.d/mise.list
$STD apt update
$STD apt install -y mise
msg_ok "Installed Mise"

read -r -p "${TAB3}Install OpenVINO dependencies for Intel HW-accelerated machine-learning? y/N " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Installing OpenVINO dependencies"
  touch ~/.openvino
  $STD apt install -y --no-install-recommends patchelf
  tmp_dir=$(mktemp -d)
  $STD pushd "$tmp_dir"
  curl -fsSLO https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.17384.11/intel-igc-core_1.0.17384.11_amd64.deb
  curl -fsSLO https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.17384.11/intel-igc-opencl_1.0.17384.11_amd64.deb
  curl -fsSLO https://github.com/intel/compute-runtime/releases/download/24.31.30508.7/intel-opencl-icd_24.31.30508.7_amd64.deb
  curl -fsSLO https://github.com/intel/compute-runtime/releases/download/24.31.30508.7/libigdgmm12_22.4.1_amd64.deb
  $STD apt install -y ./*.deb
  $STD apt-mark hold libigdgmm12
  $STD popd
  rm -rf "$tmp_dir"
  dpkg -l | grep "intel-opencl-icd" | awk '{print $3}' >~/.intel_version
  msg_ok "Installed OpenVINO dependencies"
fi

msg_info "Configuring Debian Testing Repo"
sed -i 's/ trixie-updates/ trixie-updates testing/g' /etc/apt/sources.list.d/debian.sources
cat <<EOF >/etc/apt/preferences.d/preferences
Package: *
Pin: release a=unstable
Pin-Priority: 450

Package: *
Pin:release a=testing
Pin-Priority: 450
EOF
$STD apt update
msg_ok "Configured Debian Testing repo"
msg_info "Installing libmimalloc3"
$STD apt install -t testing --no-install-recommends -yqq libmimalloc3
msg_ok "Installed libmimalloc3"

PNPM_VERSION="$(curl -fsSL "https://raw.githubusercontent.com/immich-app/immich/refs/heads/main/package.json" | jq -r '.packageManager | split("@")[1]')"
NODE_VERSION="24" NODE_MODULE="pnpm@${PNPM_VERSION}" setup_nodejs
PG_VERSION="16" PG_MODULES="pgvector" setup_postgresql

msg_info "Setting up Postgresql Database"
VCHORD_RELEASE="0.5.3"
curl -fsSL "https://github.com/tensorchord/VectorChord/releases/download/${VCHORD_RELEASE}/postgresql-16-vchord_${VCHORD_RELEASE}-1_amd64.deb" -o vchord.deb
$STD apt install -y ./vchord.deb
rm vchord.deb
echo "$VCHORD_RELEASE" >~/.vchord_version
DB_NAME="immich"
DB_USER="immich"
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c18)
sed -i -e "/^#shared_preload/s/^#//;/^shared_preload/s/''/'vchord.so'/" /etc/postgresql/16/main/postgresql.conf
systemctl restart postgresql.service
$STD sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME to $DB_USER;"
$STD sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"
{
  echo "${APPLICATION} DB Credentials"
  echo "Database User: $DB_USER"
  echo "Database Password: $DB_PASS"
  echo "Database Name: $DB_NAME"
} >>~/"$APPLICATION".creds
msg_ok "Set up Postgresql Database"

msg_info "Compiling Custom Photo-processing Library (extreme patience)"
LD_LIBRARY_PATH=/usr/local/lib
export LD_RUN_PATH=/usr/local/lib
STAGING_DIR=/opt/staging
BASE_REPO="https://github.com/immich-app/base-images"
BASE_DIR=${STAGING_DIR}/base-images
SOURCE_DIR=${STAGING_DIR}/image-source
$STD git clone -b main "$BASE_REPO" "$BASE_DIR"
mkdir -p "$SOURCE_DIR"

msg_info "(1/5) Compiling libjxl"
cd "$STAGING_DIR"
SOURCE=${SOURCE_DIR}/libjxl
JPEGLI_LIBJPEG_LIBRARY_SOVERSION="62"
JPEGLI_LIBJPEG_LIBRARY_VERSION="62.3.0"
: "${LIBJXL_REVISION:=$(jq -cr '.revision' $BASE_DIR/server/sources/libjxl.json)}"
$STD git clone https://github.com/libjxl/libjxl.git "$SOURCE"
cd "$SOURCE"
$STD git reset --hard "$LIBJXL_REVISION"
$STD git submodule update --init --recursive --depth 1 --recommend-shallow
$STD git apply "$BASE_DIR"/server/sources/libjxl-patches/jpegli-empty-dht-marker.patch
$STD git apply "$BASE_DIR"/server/sources/libjxl-patches/jpegli-icc-warning.patch
mkdir build
cd build
$STD cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_TESTING=OFF \
  -DJPEGXL_ENABLE_DOXYGEN=OFF \
  -DJPEGXL_ENABLE_MANPAGES=OFF \
  -DJPEGXL_ENABLE_PLUGIN_GIMP210=OFF \
  -DJPEGXL_ENABLE_BENCHMARK=OFF \
  -DJPEGXL_ENABLE_EXAMPLES=OFF \
  -DJPEGXL_FORCE_SYSTEM_BROTLI=ON \
  -DJPEGXL_FORCE_SYSTEM_HWY=ON \
  -DJPEGXL_ENABLE_JPEGLI=ON \
  -DJPEGXL_ENABLE_JPEGLI_LIBJPEG=ON \
  -DJPEGXL_INSTALL_JPEGLI_LIBJPEG=ON \
  -DJPEGXL_ENABLE_PLUGINS=ON \
  -DJPEGLI_LIBJPEG_LIBRARY_SOVERSION="$JPEGLI_LIBJPEG_LIBRARY_SOVERSION" \
  -DJPEGLI_LIBJPEG_LIBRARY_VERSION="$JPEGLI_LIBJPEG_LIBRARY_VERSION" \
  -DLIBJPEG_TURBO_VERSION_NUMBER=2001005 \
  ..
$STD cmake --build . -- -j"$(nproc)"
$STD cmake --install .
ldconfig /usr/local/lib
$STD make clean
cd "$STAGING_DIR"
rm -rf "$SOURCE"/{build,third_party}
msg_ok "(1/5) Compiled libjxl"

msg_info "(2/5) Compiling libheif"
SOURCE=${SOURCE_DIR}/libheif
: "${LIBHEIF_REVISION:=$(jq -cr '.revision' $BASE_DIR/server/sources/libheif.json)}"
$STD git clone https://github.com/strukturag/libheif.git "$SOURCE"
cd "$SOURCE"
$STD git reset --hard "$LIBHEIF_REVISION"
mkdir build
cd build
$STD cmake --preset=release-noplugins \
  -DWITH_DAV1D=ON \
  -DENABLE_PARALLEL_TILE_DECODING=ON \
  -DWITH_LIBSHARPYUV=ON \
  -DWITH_LIBDE265=ON \
  -DWITH_AOM_DECODER=OFF \
  -DWITH_AOM_ENCODER=ON \
  -DWITH_X265=OFF \
  -DWITH_EXAMPLES=OFF \
  ..
$STD make install -j "$(nproc)"
ldconfig /usr/local/lib
$STD make clean
cd "$STAGING_DIR"
rm -rf "$SOURCE"/build
msg_ok "(2/5) Compiled libheif"

msg_info "(3/5) Compiling libraw"
SOURCE=${SOURCE_DIR}/libraw
: "${LIBRAW_REVISION:=$(jq -cr '.revision' $BASE_DIR/server/sources/libraw.json)}"
$STD git clone https://github.com/libraw/libraw.git "$SOURCE"
cd "$SOURCE"
$STD git reset --hard "$LIBRAW_REVISION"
$STD autoreconf --install
$STD ./configure
$STD make -j"$(nproc)"
$STD make install
ldconfig /usr/local/lib
$STD make clean
cd "$STAGING_DIR"
msg_ok "(3/5) Compiled libraw"

msg_info "(4/5) Compiling imagemagick"
SOURCE=$SOURCE_DIR/imagemagick
: "${IMAGEMAGICK_REVISION:=$(jq -cr '.revision' $BASE_DIR/server/sources/imagemagick.json)}"
$STD git clone https://github.com/ImageMagick/ImageMagick.git "$SOURCE"
cd "$SOURCE"
$STD git reset --hard "$IMAGEMAGICK_REVISION"
$STD ./configure --with-modules CPPFLAGS="-DMAGICK_LIBRAW_VERSION_TAIL=202502"
$STD make -j"$(nproc)"
$STD make install
ldconfig /usr/local/lib
$STD make clean
cd "$STAGING_DIR"
msg_ok "(4/5) Compiled imagemagick"

msg_info "(5/5) Compiling libvips"
SOURCE=$SOURCE_DIR/libvips
: "${LIBVIPS_REVISION:=$(jq -cr '.revision' $BASE_DIR/server/sources/libvips.json)}"
$STD git clone https://github.com/libvips/libvips.git "$SOURCE"
cd "$SOURCE"
$STD git reset --hard "$LIBVIPS_REVISION"
$STD meson setup build --buildtype=release --libdir=lib -Dintrospection=disabled -Dtiff=disabled
cd build
$STD ninja install
ldconfig /usr/local/lib
cd "$STAGING_DIR"
rm -rf "$SOURCE"/build
msg_ok "(5/5) Compiled libvips"
{
  echo "imagemagick: $IMAGEMAGICK_REVISION"
  echo "libheif: $LIBHEIF_REVISION"
  echo "libjxl: $LIBJXL_REVISION"
  echo "libraw: $LIBRAW_REVISION"
  echo "libvips: $LIBVIPS_REVISION"
} >~/.immich_library_revisions
msg_ok "Custom Photo-processing Libraries Compiled Successfully"

INSTALL_DIR="/opt/${APPLICATION}"
UPLOAD_DIR="${INSTALL_DIR}/upload"
SRC_DIR="${INSTALL_DIR}/source"
APP_DIR="${INSTALL_DIR}/app"
PLUGIN_DIR="${APP_DIR}/corePlugin"
ML_DIR="${APP_DIR}/machine-learning"
GEO_DIR="${INSTALL_DIR}/geodata"
mkdir -p "$INSTALL_DIR"
mkdir -p {"${APP_DIR}","${UPLOAD_DIR}","${GEO_DIR}","${INSTALL_DIR}"/cache}

fetch_and_deploy_gh_release "immich" "immich-app/immich" "tarball" "v2.3.1" "$SRC_DIR"

msg_info "Installing ${APPLICATION} (patience)"

cd "$SRC_DIR"/server
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
export CI=1
corepack enable

# server build
export SHARP_IGNORE_GLOBAL_LIBVIPS=true
$STD pnpm --filter immich --frozen-lockfile build
unset SHARP_IGNORE_GLOBAL_LIBVIPS
export SHARP_FORCE_GLOBAL_LIBVIPS=true
$STD pnpm --filter immich --frozen-lockfile --prod --no-optional deploy "$APP_DIR"
cp "$APP_DIR"/package.json "$APP_DIR"/bin
sed -i 's|^start|./start|' "$APP_DIR"/bin/immich-admin

# openapi & web build
cd "$SRC_DIR"
echo "packageImportMethod: hardlink" >>./pnpm-workspace.yaml
$STD pnpm --filter @immich/sdk --filter immich-web --frozen-lockfile --force install
unset SHARP_FORCE_GLOBAL_LIBVIPS
export SHARP_IGNORE_GLOBAL_LIBVIPS=true
$STD pnpm --filter @immich/sdk --filter immich-web build
cp -a web/build "$APP_DIR"/www
cp LICENSE "$APP_DIR"

# cli build
$STD pnpm --filter @immich/sdk --filter @immich/cli --frozen-lockfile install
$STD pnpm --filter @immich/sdk --filter @immich/cli build
$STD pnpm --filter @immich/cli --prod --no-optional deploy "$APP_DIR"/cli

# plugins
cd "$SRC_DIR"
$STD mise trust --ignore ./mise.toml
$STD mise trust ./plugins/mise.toml
cd plugins
$STD mise install
$STD mise run build
mkdir -p "$PLUGIN_DIR"
cp -r ./dist "$PLUGIN_DIR"/dist
cp ./manifest.json "$PLUGIN_DIR"
msg_ok "Installed Immich Server, Web and Plugin Components"

cd "$SRC_DIR"/machine-learning
$STD useradd -U -s /usr/sbin/nologin -r -M -d "$INSTALL_DIR" immich
mkdir -p "$ML_DIR" && chown -R immich:immich "$INSTALL_DIR"
export VIRTUAL_ENV="${ML_DIR}/ml-venv"
if [[ -f ~/.openvino ]]; then
  msg_info "Installing HW-accelerated machine-learning"
  $STD sudo --preserve-env=VIRTUAL_ENV -nu immich uv sync --extra openvino --active -n -p python3.11 --managed-python
  patchelf --clear-execstack "${VIRTUAL_ENV}/lib/python3.11/site-packages/onnxruntime/capi/onnxruntime_pybind11_state.cpython-311-x86_64-linux-gnu.so"
  msg_ok "Installed HW-accelerated machine-learning"
else
  msg_info "Installing machine-learning"
  $STD sudo --preserve-env=VIRTUAL_ENV -nu immich uv sync --extra cpu --active -n -p python3.11 --managed-python
  msg_ok "Installed machine-learning"
fi
cd "$SRC_DIR"
cp -a machine-learning/{ann,immich_ml} "$ML_DIR"
if [[ -f ~/.openvino ]]; then
  sed -i "/intra_op/s/int = 0/int = os.cpu_count() or 0/" "$ML_DIR"/immich_ml/config.py
fi
ln -sf "$APP_DIR"/resources "$INSTALL_DIR"

cd "$APP_DIR"
grep -rl /usr/src | xargs -n1 sed -i "s|\/usr/src|$INSTALL_DIR|g"
grep -rlE "'/build'" | xargs -n1 sed -i "s|'/build'|'$APP_DIR'|g"
sed -i "s@\"/cache\"@\"$INSTALL_DIR/cache\"@g" "$ML_DIR"/immich_ml/config.py
ln -s "$UPLOAD_DIR" "$APP_DIR"/upload
ln -s "$UPLOAD_DIR" "$ML_DIR"/upload

msg_info "Installing GeoNames data"
cd "$GEO_DIR"
curl -fsSLZ -O "https://download.geonames.org/export/dump/admin1CodesASCII.txt" \
  -O "https://download.geonames.org/export/dump/admin2Codes.txt" \
  -O "https://download.geonames.org/export/dump/cities500.zip" \
  -O "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_10m_admin_0_countries.geojson"
unzip -q cities500.zip
date --iso-8601=seconds | tr -d "\n" >geodata-date.txt
rm cities500.zip
cd "$INSTALL_DIR"
ln -s "$GEO_DIR" "$APP_DIR"
msg_ok "Installed GeoNames data"

mkdir -p /var/log/immich
touch /var/log/immich/{web.log,ml.log}
msg_ok "Installed ${APPLICATION}"

msg_info "Modifying user, creating env file, scripts & services"
usermod -aG video,render immich

cat <<EOF >"${INSTALL_DIR}"/.env
TZ=$(cat /etc/timezone)
IMMICH_VERSION=release
NODE_ENV=production

DB_HOSTNAME=127.0.0.1
DB_USERNAME=${DB_USER}
DB_PASSWORD=${DB_PASS}
DB_DATABASE_NAME=${DB_NAME}
DB_VECTOR_EXTENSION=vectorchord

REDIS_HOSTNAME=127.0.0.1
IMMICH_MACHINE_LEARNING_URL=http://127.0.0.1:3003
MACHINE_LEARNING_CACHE_FOLDER=${INSTALL_DIR}/cache
## - For OpenVINO only - uncomment below to increase
## - inference speed while reducing accuracy
## - Default is FP32
# MACHINE_LEARNING_OPENVINO_PRECISION=FP16

IMMICH_MEDIA_LOCATION=${UPLOAD_DIR}
EOF
cat <<EOF >"${ML_DIR}"/ml_start.sh
#!/usr/bin/env bash

cd ${ML_DIR}
. ${VIRTUAL_ENV}/bin/activate

set -a
. ${INSTALL_DIR}/.env
set +a

python3 -m immich_ml
EOF
cat <<EOF >"$APP_DIR"/bin/start.sh
#!/usr/bin/env bash

set -a
. ${INSTALL_DIR}/.env
set +a

/usr/bin/node ${APP_DIR}/dist/main.js "\$@"
EOF
chmod +x "$ML_DIR"/ml_start.sh "$APP_DIR"/bin/start.sh
cat <<EOF >/etc/systemd/system/"${APPLICATION}"-web.service
[Unit]
Description=${APPLICATION} Web Service
After=network.target
Requires=redis-server.service
Requires=postgresql.service
Requires=immich-ml.service

[Service]
Type=simple
User=immich
Group=immich
UMask=0077
WorkingDirectory=${APP_DIR}
EnvironmentFile=${INSTALL_DIR}/.env
ExecStart=/usr/bin/node ${APP_DIR}/dist/main
Restart=on-failure
SyslogIdentifier=immich-web
StandardOutput=append:/var/log/immich/web.log
StandardError=append:/var/log/immich/web.log

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/"${APPLICATION}"-ml.service
[Unit]
Description=${APPLICATION} Machine-Learning
After=network.target

[Service]
Type=simple
UMask=0077
User=immich
Group=immich
WorkingDirectory=${APP_DIR}
EnvironmentFile=${INSTALL_DIR}/.env
ExecStart=${ML_DIR}/ml_start.sh
Restart=on-failure
SyslogIdentifier=immich-machine-learning
StandardOutput=append:/var/log/immich/ml.log
StandardError=append:/var/log/immich/ml.log

[Install]
WantedBy=multi-user.target
EOF
chown -R immich:immich "$INSTALL_DIR" /var/log/immich
systemctl enable -q --now "$APPLICATION"-ml.service "$APPLICATION"-web.service
msg_ok "Modified user, created env file, scripts and services"

motd_ssh
customize
cleanup_lxc
