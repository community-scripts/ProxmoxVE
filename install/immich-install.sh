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

msg_info "Configuring apt and installing dependencies"
echo "deb http://deb.debian.org/debian testing main contrib" >/etc/apt/sources.list.d/immich.list
cat <<EOF >/etc/apt/preferences.d/immich
Package: *
Pin: release a=testing
Pin-Priority: -10
EOF

$STD apt-get update
$STD apt-get install --no-install-recommends -y \
  git \
  redis \
  autoconf \
  build-essential \
  python3-dev \
  cmake \
  jq \
  libbrotli-dev \
  libde265-dev \
  libexif-dev \
  libexpat1-dev \
  libglib2.0-dev \
  libgsf-1-dev \
  libjpeg62-turbo-dev \
  librsvg2-dev \
  libspng-dev \
  meson \
  ninja-build \
  pkg-config \
  cpanminus \
  libde265-0 \
  libexif12 \
  libexpat1 \
  libgcc-s1 \
  libglib2.0-0 \
  libgomp1 \
  libgsf-1-114 \
  liblcms2-dev \
  liblqr-1-0 \
  libltdl7 \
  libmimalloc2.0 \
  libopenexr-dev \
  libgif-dev \
  libopenjp2-7 \
  librsvg2-2 \
  libspng0 \
  mesa-utils \
  mesa-va-drivers \
  mesa-vulkan-drivers \
  ocl-icd-libopencl1 \
  tini \
  libaom-dev \
  zlib1g
$STD apt-get install -y \
  libgdk-pixbuf-2.0-dev librsvg2-dev libtool
curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg
DPKG_ARCHITECTURE="$(dpkg --print-architecture)"
export DPKG_ARCHITECTURE
cat <<EOF >/etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/debian
Suites: bookworm
Components: main
Architectures: ${DPKG_ARCHITECTURE}
Signed-By: /etc/apt/keyrings/jellyfin.gpg
EOF
$STD apt-get update
$STD apt-get install -y jellyfin-ffmpeg7
ln -s /usr/lib/jellyfin-ffmpeg/ffmpeg /usr/bin/ffmpeg
ln -s /usr/lib/jellyfin-ffmpeg/ffprobe /usr/bin/ffprobe
if [[ "$CTTYPE" == "0" ]]; then
  chgrp video /dev/dri
  chmod 755 /dev/dri
  chmod 660 /dev/dri/*
  $STD adduser "$(id -u -n)" video
  $STD adduser "$(id -u -n)" render
fi
msg_ok "Dependencies Installed"

read -r -p "${TAB3}Install OpenVINO dependencies for Intel HW-accelerated machine-learning? y/N " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Installing OpenVINO dependencies"
  touch ~/.openvino
  tmp_dir=$(mktemp -d)
  $STD pushd "$tmp_dir"
  curl -fsSLO https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.17384.11/intel-igc-core_1.0.17384.11_amd64.deb
  curl -fsSLO https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.17384.11/intel-igc-opencl_1.0.17384.11_amd64.deb
  curl -fsSLO https://github.com/intel/compute-runtime/releases/download/24.31.30508.7/intel-opencl-icd_24.31.30508.7_amd64.deb
  curl -fsSLO https://github.com/intel/compute-runtime/releases/download/24.31.30508.7/libigdgmm12_22.4.1_amd64.deb
  $STD apt install -y ./*.deb
  $STD popd
  rm -rf "$tmp_dir"
  dpkg -l | grep "intel-opencl-icd" | awk '{print $3}' >~/.intel_version
  msg_ok "Installed OpenVINO dependencies"
fi

msg_info "Installing Packages from Testing Repo"
export APT_LISTCHANGES_FRONTEND=none
export DEBIAN_FRONTEND=noninteractive
$STD apt-get install -t testing --no-install-recommends -y \
  libio-compress-brotli-perl \
  libwebp7 \
  libwebpdemux2 \
  libwebpmux3 \
  libhwy1t64 \
  libdav1d-dev \
  libhwy-dev \
  libwebp-dev
if [[ -f ~/.openvino ]]; then
  $STD apt-get install -t testing -y patchelf
fi
msg_ok "Packages from Testing Repo Installed"

NODE_VERSION="22" setup_nodejs
PG_VERSION="16" PG_MODULES="pgvector" setup_postgresql

msg_info "Setting up Postgresql Database"
VCHORD_RELEASE="$(curl -fsSL https://api.github.com/repos/tensorchord/vectorchord/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')"
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

SOURCE=$SOURCE_DIR/imagemagick
: "${IMAGEMAGICK_REVISION:=$(jq -cr '.revision' $BASE_DIR/server/sources/imagemagick.json)}"
$STD git clone https://github.com/ImageMagick/ImageMagick.git "$SOURCE"
cd "$SOURCE"
$STD git reset --hard "$IMAGEMAGICK_REVISION"
$STD ./configure --with-modules
$STD make -j"$(nproc)"
$STD make install
ldconfig /usr/local/lib
$STD make clean
cd "$STAGING_DIR"

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
{
  echo "imagemagick: $IMAGEMAGICK_REVISION"
  echo "libheif: $LIBHEIF_REVISION"
  echo "libjxl: $LIBJXL_REVISION"
  echo "libraw: $LIBRAW_REVISION"
  echo "libvips: $LIBVIPS_REVISION"
} >~/.immich_library_revisions
msg_ok "Custom Photo-processing Library Compiled"

INSTALL_DIR="/opt/${APPLICATION}"
UPLOAD_DIR="${INSTALL_DIR}/upload"
SRC_DIR="${INSTALL_DIR}/source"
APP_DIR="${INSTALL_DIR}/app"
ML_DIR="${APP_DIR}/machine-learning"
GEO_DIR="${INSTALL_DIR}/geodata"
mkdir -p "$INSTALL_DIR"
mkdir -p {"${APP_DIR}","${UPLOAD_DIR}","${GEO_DIR}","${ML_DIR}","${INSTALL_DIR}"/cache}

fetch_and_deploy_gh_release "immich" "immich-app/immich" "tarball" "latest" "$SRC_DIR"

msg_info "Installing ${APPLICATION} (more patience please)"

cd "$SRC_DIR"/server
$STD npm install -g node-gyp node-pre-gyp
$STD npm ci
$STD npm run build
$STD npm prune --omit=dev --omit=optional
cd "$SRC_DIR"/open-api/typescript-sdk
$STD npm ci
$STD npm run build
cd "$SRC_DIR"/web
$STD npm ci
$STD npm run build
cd "$SRC_DIR"
cp -a server/{node_modules,dist,bin,resources,package.json,package-lock.json,start*.sh} "$APP_DIR"/
cp -a web/build "$APP_DIR"/www
cp LICENSE "$APP_DIR"
msg_ok "Installed Immich Web Components"

cd "$SRC_DIR"/machine-learning
export VIRTUAL_ENV="${ML_DIR}/ml-venv"
$STD uv venv "$VIRTUAL_ENV"
if [[ -f ~/.openvino ]]; then
  msg_info "Installing HW-accelerated machine-learning"
  uv -q sync --extra openvino --no-cache --active
  patchelf --clear-execstack "${VIRTUAL_ENV}/lib/python3.11/site-packages/onnxruntime/capi/onnxruntime_pybind11_state.cpython-311-x86_64-linux-gnu.so"
  msg_ok "Installed HW-accelerated machine-learning"
else
  msg_info "Installing machine-learning"
  uv -q sync --extra cpu --no-cache --active
  msg_ok "Installed machine-learning"
fi
cd "$SRC_DIR"
cp -a machine-learning/{ann,immich_ml} "$ML_DIR"
if [[ -f ~/.openvino ]]; then
  sed -i "/intra_op/s/int = 0/int = os.cpu_count() or 0/" "$ML_DIR"/immich_ml/config.py
fi
ln -sf "$APP_DIR"/resources "$INSTALL_DIR"

cd "$APP_DIR"
grep -Rl /usr/src | xargs -n1 sed -i "s|\/usr/src|$INSTALL_DIR|g"
grep -RlE "'/build'" | xargs -n1 sed -i "s|'/build'|'$APP_DIR'|g"
sed -i "s@\"/cache\"@\"$INSTALL_DIR/cache\"@g" "$ML_DIR"/immich_ml/config.py
ln -s "$UPLOAD_DIR" "$APP_DIR"/upload
ln -s "$UPLOAD_DIR" "$ML_DIR"/upload

msg_info "Installing Immich CLI"
$STD npm install --build-from-source sharp
rm -rf "$APP_DIR"/node_modules/@img/sharp-{libvips*,linuxmusl-x64}
$STD npm i -g @immich/cli
msg_ok "Installed Immich CLI"

msg_info "Installing GeoNames data"
cd "$GEO_DIR"
URL_LIST=(
  https://download.geonames.org/export/dump/admin1CodesASCII.txt
  https://download.geonames.org/export/dump/admin2Codes.txt
  https://download.geonames.org/export/dump/cities500.zip
  https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_10m_admin_0_countries.geojson
)
for geo in "${URL_LIST[@]}"; do
  curl -fsSLO "$geo"
done
unzip -q cities500.zip
date --iso-8601=seconds | tr -d "\n" >geodata-date.txt
rm cities500.zip
cd "$INSTALL_DIR"
ln -s "$GEO_DIR" "$APP_DIR"
msg_ok "Installed GeoNames data"

mkdir -p /var/log/immich
touch /var/log/immich/{web.log,ml.log}
msg_ok "Installed ${APPLICATION}"

msg_info "Creating user, env file, scripts & services"
$STD useradd -U -s /usr/sbin/nologin -r -M -d "$INSTALL_DIR" immich
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
chmod +x "$ML_DIR"/ml_start.sh
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
msg_ok "Created user, env file, scripts and services"

sed -i "$ a VERSION_ID=12" /etc/os-release # otherwise the motd_ssh function will fail
motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
