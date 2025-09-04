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
var_version="${var_version:-12}"
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

  setup_uv
  PNPM_VERSION="$(curl -fsSL "https://raw.githubusercontent.com/immich-app/immich/refs/heads/main/package.json" | jq -r '.packageManager | split("@")[1]')"
  NODE_VERSION="22" NODE_MODULE="pnpm@${PNPM_VERSION}" setup_nodejs

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
      $STD apt install -y ./*.deb
      rm ./*.deb
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
  RELEASE="1.140.1"
  if check_for_gh_release "immich" "immich-app/immich" "${RELEASE}"; then
    msg_info "Stopping Services"
    systemctl stop immich-web
    systemctl stop immich-ml
    msg_ok "Stopped ${APP}"
    INSTALL_DIR="/opt/${APP}"
    UPLOAD_DIR="$(sed -n '/^IMMICH_MEDIA_LOCATION/s/[^=]*=//p' /opt/immich/.env)"
    SRC_DIR="${INSTALL_DIR}/source"
    APP_DIR="${INSTALL_DIR}/app"
    ML_DIR="${APP_DIR}/machine-learning"
    GEO_DIR="${INSTALL_DIR}/geodata"
    VCHORD_RELEASE="0.4.3"
    # VCHORD_RELEASE="$(curl -fsSL https://api.github.com/repos/tensorchord/vectorchord/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')"

    if [[ ! -f ~/.vchord_version ]] || [[ "$VCHORD_RELEASE" != "$(cat ~/.vchord_version)" ]]; then
      msg_info "Updating VectorChord"
      if [[ ! -f ~/.vchord_version ]] || [[ ! "$(cat ~/.vchord_version)" > "0.3.0" ]]; then
        $STD sudo -u postgres pg_dumpall --clean --if-exists --username=postgres | gzip >/etc/postgresql/immich-db-vchord0.3.0.sql.gz
        chown postgres /etc/postgresql/immich-db-vchord0.3.0.sql.gz
        $STD sudo -u postgres gunzip --stdout /etc/postgresql/immich-db-vchord0.3.0.sql.gz |
          sed -e "s/SELECT pg_catalog.set_config('search_path', '', false);/SELECT pg_catalog.set_config('search_path', 'public, pg_catalog', true);/g" \
            -e "/vchordrq.prewarm_dim/d" |
          sudo -u postgres psql
      fi
      curl -fsSL "https://github.com/tensorchord/vectorchord/releases/download/${VCHORD_RELEASE}/postgresql-16-vchord_${VCHORD_RELEASE}-1_amd64.deb" -o vchord.deb
      $STD apt install -y ./vchord.deb
      $STD sudo -u postgres psql -d immich -c "ALTER EXTENSION vchord UPDATE;"
      systemctl restart postgresql
      if [[ ! -f ~/.vchord_version ]] || [[ ! "$(cat ~/.vchord_version)" > "0.3.0" ]]; then
        $STD sudo -u postgres psql -d immich -c "REINDEX INDEX face_index;"
        $STD sudo -u postgres psql -d immich -c "REINDEX INDEX clip_index;"
      fi
      echo "$VCHORD_RELEASE" >~/.vchord_version
      rm ./vchord.deb
      msg_ok "Updated VectorChord to v${VCHORD_RELEASE}"
    fi

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
    if [[ "$RELEASE" == "1.135.1" ]]; then
      rm ./src/schema/migrations/1750323941566-UnsetPrewarmDimParameter.ts
    fi
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
    $STD pnpm --filter @immich/sdk --filter immich-web --frozen-lockfile --force install
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
    mkdir -p "$ML_DIR"
    export VIRTUAL_ENV="${ML_DIR}"/ml-venv
    $STD /usr/local/bin/uv venv "$VIRTUAL_ENV"
    if [[ -f ~/.openvino ]]; then
      msg_info "Updating HW-accelerated machine-learning"
      /usr/local/bin/uv -q sync --extra openvino --no-cache --active
      patchelf --clear-execstack "${VIRTUAL_ENV}/lib/python3.11/site-packages/onnxruntime/capi/onnxruntime_pybind11_state.cpython-311-x86_64-linux-gnu.so"
      msg_ok "Updated HW-accelerated machine-learning"
    else
      msg_info "Updating machine-learning"
      /usr/local/bin/uv -q sync --extra cpu --no-cache --active
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
    if [[ ! -f ~/.debian_version.bak ]]; then
      cp /etc/debian_version ~/.debian_version.bak
      sed -i 's/.*/13.0/' /etc/debian_version
    fi
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Cleaning up"
    $STD apt-get -y autoremove
    $STD apt-get -y autoclean
    msg_ok "Cleaned"
    systemctl restart immich-ml immich-web
  fi
  exit
}

function compile_libjxl() {
  SOURCE=${SOURCE_DIR}/libjxl
  JPEGLI_LIBJPEG_LIBRARY_SOVERSION="62"
  JPEGLI_LIBJPEG_LIBRARY_VERSION="62.3.0"
  # : "${LIBJXL_REVISION:=$(jq -cr '.revision' "$BASE_DIR"/server/sources/libjxl.json)}"
  : "${LIBJXL_REVISION:=794a5dcf0d54f9f0b20d288a12e87afb91d20dfc}"
  if [[ "${update:-}" ]] || [[ "$LIBJXL_REVISION" != "$(grep 'libjxl' ~/.immich_library_revisions | awk '{print $2}')" ]]; then
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
    $STD apt-get install -y libaom-dev
    local update="required"
  fi
  # : "${LIBHEIF_REVISION:=$(jq -cr '.revision' "$BASE_DIR"/server/sources/libheif.json)}"
  : "${LIBHEIF_REVISION:=35dad50a9145332a7bfdf1ff6aef6801fb613d68}"
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
  local update
  # : "${LIBRAW_REVISION:=$(jq -cr '.revision' "$BASE_DIR"/server/sources/libraw.json)}"
  : "${LIBRAW_REVISION:=09bea31181b43e97959ee5452d91e5bc66365f1f}"
  if [[ "${update:-}" ]] || [[ "$LIBRAW_REVISION" != "$(grep 'libraw' ~/.immich_library_revisions | awk '{print $2}')" ]]; then
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
  # : "${IMAGEMAGICK_REVISION:=$(jq -cr '.revision' "$BASE_DIR"/server/sources/imagemagick.json)}"
  : "${IMAGEMAGICK_REVISION:=8289a3388a085ad5ae81aa6812f21554bdfd54f2}"
  if [[ "${update:-}" ]] || [[ "$IMAGEMAGICK_REVISION" != "$(grep 'imagemagick' ~/.immich_library_revisions | awk '{print $2}')" ]]; then
    msg_info "Recompiling ImageMagick"
    if [[ -d "$SOURCE" ]]; then rm -rf "$SOURCE"; fi
    $STD git clone https://github.com/ImageMagick/ImageMagick.git "$SOURCE"
    cd "$SOURCE"
    $STD git reset --hard "$IMAGEMAGICK_REVISION"
    $STD ./configure --with-modules
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
  # : "${LIBVIPS_REVISION:=$(jq -cr '.revision' "$BASE_DIR"/server/sources/libvips.json)}"
  : "${LIBVIPS_REVISION:=8fa37a64547e392d3808eed8d72adab7e02b3d00}"
  if [[ "${update:-}" ]] || [[ "$LIBVIPS_REVISION" != "$(grep 'libvips' ~/.immich_library_revisions | awk '{print $2}')" ]]; then
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
