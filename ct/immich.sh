#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://immich.app

APP="immich"
var_tags="${var_tags:-photos}"
var_disk="${var_disk:-20}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/immich ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if [[ -f /etc/apt/sources.list.d/immich.list ]]; then
    msg_error "Wrong Debian version detected!"
    msg_error "You must upgrade your LXC to Debian Trixie before updating."
    msg_error "Please visit https://github.com/community-scripts/ProxmoxVE/discussions/7726 for details."
    echo "${TAB3}  If you have upgraded your LXC to Trixie and you still see this message, please open an Issue in the Community-Scripts repo."
    exit
  fi

  setup_uv
  PNPM_VERSION="$(curl -fsSL "https://raw.githubusercontent.com/immich-app/immich/refs/heads/main/package.json" | jq -r '.packageManager | split("@")[1]')"
  NODE_VERSION="24" NODE_MODULE="pnpm@${PNPM_VERSION}" setup_nodejs

  if [[ ! -f /etc/apt/preferences.d/preferences ]]; then
    msg_info "Adding Debian Testing repo"
    sed -i 's/ trixie-updates/ trixie-updates testing/g' /etc/apt/sources.list.d/debian.sources
    cat <<EOF >/etc/apt/preferences.d/preferences
Package: *
Pin: release a=unstable
Pin-Priority: 450

Package: *
Pin:release a=testing
Pin-Priority: 450
EOF
    if [[ -f /etc/apt/preferences.d/immich ]]; then
      rm /etc/apt/preferences.d/immich
    fi
    $STD apt update
    msg_ok "Added Debian Testing repo"
    msg_info "Installing libmimalloc3"
    $STD apt install -t testing --no-install-recommends libmimalloc3
    msg_ok "Installed libmimalloc3"
  fi

  STAGING_DIR=/opt/staging
  BASE_DIR=${STAGING_DIR}/base-images
  SOURCE_DIR=${STAGING_DIR}/image-source
  cd /root
  if [[ -f ~/.intel_version ]]; then
    curl -fsSLO https://raw.githubusercontent.com/immich-app/immich/refs/heads/main/machine-learning/Dockerfile
    readarray -t INTEL_URLS < <(sed -n "/intel/p" ./Dockerfile | awk '{print $3}')
    INTEL_RELEASE="$(grep "intel-opencl-icd" ./Dockerfile | awk -F '_' '{print $2}')"
    if [[ "$INTEL_RELEASE" != "$(cat ~/.intel_version)" ]]; then
      msg_info "Updating Intel iGPU dependencies"
      for url in "${INTEL_URLS[@]}"; do
        curl -fsSLO "$url"
      done
      $STD apt-mark unhold libigdgmm12
      $STD apt install -y ./*.deb
      rm ./*.deb
      $STD apt-mark hold libigdgmm12
      msg_ok "Intel iGPU dependencies updated"
    fi
    rm ~/Dockerfile
  fi
  if [[ -f ~/.immich_library_revisions ]]; then
    libraries=("libjxl" "libheif" "libraw" "imagemagick" "libvips")
    cd "$BASE_DIR"
    msg_info "Checking for updates to custom image-processing libraries"
    $STD git pull
    for library in "${libraries[@]}"; do
      compile_"$library"
    done
    msg_ok "Image-processing libraries up to date"
  fi

  RELEASE="2.2.3"
  if check_for_gh_release "immich" "immich-app/immich" "${RELEASE}"; then
    msg_info "Stopping Services"
    systemctl stop immich-web
    systemctl stop immich-ml
    msg_ok "Stopped Services"
    VCHORD_RELEASE="0.5.3"
    if [[ ! -f ~/.vchord_version ]] || [[ "$VCHORD_RELEASE" != "$(cat ~/.vchord_version)" ]]; then
      msg_info "Upgrading VectorChord"
      curl -fsSL "https://github.com/tensorchord/vectorchord/releases/download/${VCHORD_RELEASE}/postgresql-16-vchord_${VCHORD_RELEASE}-1_amd64.deb" -o vchord.deb
      $STD apt install -y ./vchord.deb
      systemctl restart postgresql
      $STD sudo -u postgres psql -d immich -c "ALTER EXTENSION vector UPDATE;"
      $STD sudo -u postgres psql -d immich -c "ALTER EXTENSION vchord UPDATE;"
      $STD sudo -u postgres psql -d immich -c "REINDEX INDEX face_index;"
      $STD sudo -u postgres psql -d immich -c "REINDEX INDEX clip_index;"
      echo "$VCHORD_RELEASE" >~/.vchord_version
      rm ./vchord.deb
      msg_ok "Upgraded VectorChord to v${VCHORD_RELEASE}"
    fi
    if ! dpkg -l | grep -q ccache; then
      $STD apt install -yqq ccache
    fi

    INSTALL_DIR="/opt/${APP}"
    UPLOAD_DIR="$(sed -n '/^IMMICH_MEDIA_LOCATION/s/[^=]*=//p' /opt/immich/.env)"
    SRC_DIR="${INSTALL_DIR}/source"
    APP_DIR="${INSTALL_DIR}/app"
    ML_DIR="${APP_DIR}/machine-learning"
    GEO_DIR="${INSTALL_DIR}/geodata"

    cp "$ML_DIR"/ml_start.sh "$INSTALL_DIR"
    if grep -qs "set -a" "$APP_DIR"/bin/start.sh; then
      cp "$APP_DIR"/bin/start.sh "$INSTALL_DIR"
    else
      cat <<EOF >"$INSTALL_DIR"/start.sh
#!/usr/bin/env bash

set -a
. ${INSTALL_DIR}/.env
set +a

/usr/bin/node ${APP_DIR}/dist/main.js "\$@"
EOF
      chmod +x "$INSTALL_DIR"/start.sh
    fi

    (
      shopt -s dotglob
      rm -rf "${APP_DIR:?}"/*
    )

    rm -rf "$SRC_DIR"

    fetch_and_deploy_gh_release "immich" "immich-app/immich" "tarball" "v${RELEASE}" "$SRC_DIR"

    msg_info "Updating ${APP} web and microservices"
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
    cd "$APP_DIR"
    mv "$INSTALL_DIR"/start.sh "$APP_DIR"/bin
    msg_ok "Updated ${APP} web and microservices"

    cd "$SRC_DIR"/machine-learning
    mkdir -p "$ML_DIR" && chown -R immich:immich "$ML_DIR"
    chown immich:immich ./uv.lock
    export VIRTUAL_ENV="${ML_DIR}"/ml-venv
    if [[ -f ~/.openvino ]]; then
      msg_info "Updating HW-accelerated machine-learning"
      $STD sudo --preserve-env=VIRTUAL_ENV -nu immich uv sync --extra openvino --active -n -p python3.11 --managed-python
      patchelf --clear-execstack "${VIRTUAL_ENV}/lib/python3.11/site-packages/onnxruntime/capi/onnxruntime_pybind11_state.cpython-311-x86_64-linux-gnu.so"
      msg_ok "Updated HW-accelerated machine-learning"
    else
      msg_info "Updating machine-learning"
      $STD sudo --preserve-env=VIRTUAL_ENV -nu immich uv sync --extra cpu --active -n -p python3.11 --managed-python
      msg_ok "Updated machine-learning"
    fi
    cd "$SRC_DIR"
    cp -a machine-learning/{ann,immich_ml} "$ML_DIR"
    mv "$INSTALL_DIR"/ml_start.sh "$ML_DIR"
    if [[ -f ~/.openvino ]]; then
      sed -i "/intra_op/s/int = 0/int = os.cpu_count() or 0/" "$ML_DIR"/immich_ml/config.py
    fi
    ln -sf "$APP_DIR"/resources "$INSTALL_DIR"
    cd "$APP_DIR"
    grep -rl /usr/src | xargs -n1 sed -i "s|\/usr/src|$INSTALL_DIR|g"
    grep -rlE "'/build'" | xargs -n1 sed -i "s|'/build'|'$APP_DIR'|g"
    sed -i "s@\"/cache\"@\"$INSTALL_DIR/cache\"@g" "$ML_DIR"/immich_ml/config.py
    ln -s "${UPLOAD_DIR:-/opt/immich/upload}" "$APP_DIR"/upload
    ln -s "${UPLOAD_DIR:-/opt/immich/upload}" "$ML_DIR"/upload
    ln -s "$GEO_DIR" "$APP_DIR"

    chown -R immich:immich "$INSTALL_DIR"
    msg_ok "Updated ${APP} to v${RELEASE}"
    systemctl restart immich-ml immich-web
  fi
  exit
}

function compile_libjxl() {
  SOURCE=${SOURCE_DIR}/libjxl
  JPEGLI_LIBJPEG_LIBRARY_SOVERSION="62"
  JPEGLI_LIBJPEG_LIBRARY_VERSION="62.3.0"
  : "${LIBJXL_REVISION:=$(jq -cr '.revision' "$BASE_DIR"/server/sources/libjxl.json)}"
  if [[ "$LIBJXL_REVISION" != "$(grep 'libjxl' ~/.immich_library_revisions | awk '{print $2}')" ]]; then
    msg_info "Recompiling libjxl"
    if [[ -d "$SOURCE" ]]; then rm -rf "$SOURCE"; fi
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
    sed -i "s/libjxl: .*$/libjxl: $LIBJXL_REVISION/" ~/.immich_library_revisions
    msg_ok "Recompiled libjxl"
  fi
}

function compile_libheif() {
  SOURCE=${SOURCE_DIR}/libheif
  if ! dpkg -l | grep -q libaom; then
    $STD apt install -y libaom-dev
    local update="required"
  fi
  : "${LIBHEIF_REVISION:=$(jq -cr '.revision' "$BASE_DIR"/server/sources/libheif.json)}"
  if [[ "${update:-}" ]] || [[ "$LIBHEIF_REVISION" != "$(grep 'libheif' ~/.immich_library_revisions | awk '{print $2}')" ]]; then
    msg_info "Recompiling libheif"
    if [[ -d "$SOURCE" ]]; then rm -rf "$SOURCE"; fi
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
    sed -i "s/libheif: .*$/libheif: $LIBHEIF_REVISION/" ~/.immich_library_revisions
    msg_ok "Recompiled libheif"
  fi
}

function compile_libraw() {
  SOURCE=${SOURCE_DIR}/libraw
  : "${LIBRAW_REVISION:=$(jq -cr '.revision' "$BASE_DIR"/server/sources/libraw.json)}"
  if [[ "$LIBRAW_REVISION" != "$(grep 'libraw' ~/.immich_library_revisions | awk '{print $2}')" ]]; then
    msg_info "Recompiling libraw"
    if [[ -d "$SOURCE" ]]; then rm -rf "$SOURCE"; fi
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
    sed -i "s/libraw: .*$/libraw: $LIBRAW_REVISION/" ~/.immich_library_revisions
    msg_ok "Recompiled libraw"
  fi
}

function compile_imagemagick() {
  SOURCE=$SOURCE_DIR/imagemagick
  : "${IMAGEMAGICK_REVISION:=$(jq -cr '.revision' "$BASE_DIR"/server/sources/imagemagick.json)}"
  if [[ "$IMAGEMAGICK_REVISION" != "$(grep 'imagemagick' ~/.immich_library_revisions | awk '{print $2}')" ]] ||
    ! grep -q 'DMAGICK_LIBRAW' /usr/local/lib/ImageMagick-7*/config-Q16HDRI/configure.xml; then
    msg_info "Recompiling ImageMagick"
    if [[ -d "$SOURCE" ]]; then rm -rf "$SOURCE"; fi
    $STD git clone https://github.com/ImageMagick/ImageMagick.git "$SOURCE"
    cd "$SOURCE"
    $STD git reset --hard "$IMAGEMAGICK_REVISION"
    $STD ./configure --with-modules CPPFLAGS="-DMAGICK_LIBRAW_VERSION_TAIL=202502"
    $STD make -j"$(nproc)"
    $STD make install
    ldconfig /usr/local/lib
    $STD make clean
    cd "$STAGING_DIR"
    sed -i "s/imagemagick: .*$/imagemagick: $IMAGEMAGICK_REVISION/" ~/.immich_library_revisions
    msg_ok "Recompiled ImageMagick"
  fi
}

function compile_libvips() {
  SOURCE=$SOURCE_DIR/libvips
  : "${LIBVIPS_REVISION:=$(jq -cr '.revision' "$BASE_DIR"/server/sources/libvips.json)}"
  if [[ "$LIBVIPS_REVISION" != "$(grep 'libvips' ~/.immich_library_revisions | awk '{print $2}')" ]]; then
    msg_info "Recompiling libvips"
    if [[ -d "$SOURCE" ]]; then rm -rf "$SOURCE"; fi
    $STD git clone https://github.com/libvips/libvips.git "$SOURCE"
    cd "$SOURCE"
    $STD git reset --hard "$LIBVIPS_REVISION"
    $STD meson setup build --buildtype=release --libdir=lib -Dintrospection=disabled -Dtiff=disabled
    cd build
    $STD ninja install
    ldconfig /usr/local/lib
    cd "$STAGING_DIR"
    rm -rf "$SOURCE"/build
    sed -i "s/libvips: .*$/libvips: $LIBVIPS_REVISION/" ~/.immich_library_revisions
    msg_ok "Recompiled libvips"
  fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:2283${CL}"
