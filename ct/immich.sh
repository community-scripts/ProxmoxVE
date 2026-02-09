#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://immich.app

APP="immich"
var_tags="${var_tags:-photos}"
var_disk="${var_disk:-20}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-6144}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_gpu="${var_gpu:-yes}"

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
    [[ -f /etc/apt/preferences.d/immich ]] && rm /etc/apt/preferences.d/immich
    $STD apt update
    msg_ok "Added Debian Testing repo"
  fi

  if ! dpkg -l "libmimalloc3" | grep -q '3.1' || ! dpkg -l "libde265-dev" | grep -q '1.0.16'; then
    msg_info "Installing/upgrading Testing repo packages"
    $STD apt install -t testing libmimalloc3 libde265-dev -y
    msg_ok "Installed/upgraded Testing repo packages"
  fi

  if [[ ! -f /etc/apt/sources.list.d/mise.list ]]; then
    msg_info "Installing Mise"
    curl -fSs https://mise.jdx.dev/gpg-key.pub | tee /etc/apt/keyrings/mise-archive-keyring.pub 1>/dev/null
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.pub arch=amd64] https://mise.jdx.dev/deb stable main" >/etc/apt/sources.list.d/mise.list
    ensure_dependencies mise
    msg_ok "Installed Mise"
  fi

  STAGING_DIR=/opt/staging
  BASE_DIR=${STAGING_DIR}/base-images
  SOURCE_DIR=${STAGING_DIR}/image-source
  cd /tmp
  if [[ -f ~/.intel_version ]]; then
    curl -fsSLO https://raw.githubusercontent.com/immich-app/base-images/refs/heads/main/server/Dockerfile
    readarray -t INTEL_URLS < <(
      sed -n "/intel-[igc|opencl]/p" ./Dockerfile | awk '{print $2}'
      sed -n "/libigdgmm12/p" ./Dockerfile | awk '{print $3}'
    )
    INTEL_RELEASE="$(grep "intel-opencl-icd_" ./Dockerfile | awk -F '_' '{print $2}')"
    if [[ "$INTEL_RELEASE" != "$(cat ~/.intel_version)" ]]; then
      msg_info "Updating Intel iGPU dependencies"
      for url in "${INTEL_URLS[@]}"; do
        curl -fsSLO "$url"
      done
      $STD apt-mark unhold libigdgmm12
      $STD apt install -y --allow-downgrades ./libigdgmm12*.deb
      rm ./libigdgmm12*.deb
      $STD apt install -y ./*.deb
      rm ./*.deb
      $STD apt-mark hold libigdgmm12
      dpkg-query -W -f='${Version}\n' intel-opencl-icd >~/.intel_version
      msg_ok "Intel iGPU dependencies updated"
    fi
    rm ./Dockerfile
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

  RELEASE="2.5.5"
  if check_for_gh_release "Immich" "immich-app/immich" "${RELEASE}"; then
    if [[ $(cat ~/.immich) > "2.5.1" ]]; then
      msg_info "Enabling Maintenance Mode"
      cd /opt/immich/app/bin
      $STD ./immich-admin enable-maintenance-mode
      export MAINT_MODE=1
      $STD cd -
      msg_ok "Enabled Maintenance Mode"
    fi
    msg_info "Stopping Services"
    systemctl stop immich-web
    systemctl stop immich-ml
    msg_ok "Stopped Services"
    VCHORD_RELEASE="0.5.3"
    [[ -f ~/.vchord_version ]] && mv ~/.vchord_version ~/.vectorchord
    if check_for_gh_release "VectorChord" "tensorchord/VectorChord" "${VCHORD_RELEASE}"; then
      fetch_and_deploy_gh_release "VectorChord" "tensorchord/VectorChord" "binary" "${VCHORD_RELEASE}" "/tmp" "postgresql-16-vchord_*_amd64.deb"
      systemctl restart postgresql
      $STD sudo -u postgres psql -d immich -c "ALTER EXTENSION vector UPDATE;"
      $STD sudo -u postgres psql -d immich -c "ALTER EXTENSION vchord UPDATE;"
      $STD sudo -u postgres psql -d immich -c "REINDEX INDEX face_index;"
      $STD sudo -u postgres psql -d immich -c "REINDEX INDEX clip_index;"
    fi
    ensure_dependencies ccache

    INSTALL_DIR="/opt/${APP}"
    UPLOAD_DIR="$(sed -n '/^IMMICH_MEDIA_LOCATION/s/[^=]*=//p' /opt/immich/.env)"
    SRC_DIR="${INSTALL_DIR}/source"
    APP_DIR="${INSTALL_DIR}/app"
    PLUGIN_DIR="${APP_DIR}/corePlugin"
    ML_DIR="${APP_DIR}/machine-learning"
    GEO_DIR="${INSTALL_DIR}/geodata"

    [[ -f "$ML_DIR"/ml_start.sh ]] && cp "$ML_DIR"/ml_start.sh "$INSTALL_DIR"
    if grep -qs "set -a" "$APP_DIR"/bin/start.sh && grep -qs "warnings" "$APP_DIR"/bin/start.sh; then
      cp "$APP_DIR"/bin/start.sh "$INSTALL_DIR"
    else
      cat <<EOF >"$INSTALL_DIR"/start.sh
#!/usr/bin/env bash

set -a
. ${INSTALL_DIR}/.env
set +a

/usr/bin/node --no-warnings ${APP_DIR}/dist/main.js "\$@"
EOF
      chmod +x "$INSTALL_DIR"/start.sh
    fi

    (
      shopt -s dotglob
      rm -rf "${APP_DIR:?}"/*
    )

    setup_uv
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Immich" "immich-app/immich" "tarball" "v${RELEASE}" "$SRC_DIR"
    PNPM_VERSION="$(jq -r '.packageManager | split("@")[1]' ${SRC_DIR}/package.json)"
    NODE_VERSION="24" NODE_MODULE="pnpm@${PNPM_VERSION}" setup_nodejs

    msg_info "Updating Immich web and microservices"
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
    sed -i "s|^start|${APP_DIR}/bin/start|" "$APP_DIR"/bin/immich-admin

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
    [[ -f "$INSTALL_DIR"/start.sh ]] && mv "$INSTALL_DIR"/start.sh "$APP_DIR"/bin

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
    msg_ok "Updated Immich server, web, cli and plugins"

    cd "$SRC_DIR"/machine-learning
    mkdir -p "$ML_DIR" && chown -R immich:immich "$ML_DIR"
    chown immich:immich ./uv.lock
    export VIRTUAL_ENV="${ML_DIR}"/ml-venv
    if [[ -f ~/.openvino ]]; then
      msg_info "Updating HW-accelerated machine-learning"
      $STD uv add --no-sync --optional openvino onnxruntime-openvino==1.20.0 --active -n -p python3.12 --managed-python
      $STD sudo --preserve-env=VIRTUAL_ENV -nu immich uv sync --extra openvino --no-dev --active --link-mode copy -n -p python3.12 --managed-python
      patchelf --clear-execstack "${VIRTUAL_ENV}/lib/python3.12/site-packages/onnxruntime/capi/onnxruntime_pybind11_state.cpython-312-x86_64-linux-gnu.so"
      msg_ok "Updated HW-accelerated machine-learning"
    else
      msg_info "Updating machine-learning"
      $STD sudo --preserve-env=VIRTUAL_ENV -nu immich uv sync --extra cpu --no-dev --active --link-mode copy -n -p python3.11 --managed-python
      msg_ok "Updated machine-learning"
    fi
    cd "$SRC_DIR"
    cp -a machine-learning/{ann,immich_ml} "$ML_DIR"
    [[ -f "$INSTALL_DIR"/ml_start.sh ]] && mv "$INSTALL_DIR"/ml_start.sh "$ML_DIR"
    [[ -f ~/.openvino ]] && sed -i "/intra_op/s/int = 0/int = os.cpu_count() or 0/" "$ML_DIR"/immich_ml/config.py
    ln -sf "$APP_DIR"/resources "$INSTALL_DIR"
    cd "$APP_DIR"
    grep -rl /usr/src | xargs -n1 sed -i "s|\/usr/src|$INSTALL_DIR|g"
    grep -rlE "'/build'" | xargs -n1 sed -i "s|'/build'|'$APP_DIR'|g"
    sed -i "s@\"/cache\"@\"$INSTALL_DIR/cache\"@g" "$ML_DIR"/immich_ml/config.py
    ln -s "${UPLOAD_DIR:-/opt/immich/upload}" "$APP_DIR"/upload
    ln -s "${UPLOAD_DIR:-/opt/immich/upload}" "$ML_DIR"/upload
    ln -s "$GEO_DIR" "$APP_DIR"
    [[ ! -f /usr/bin/immich ]] && ln -sf "$APP_DIR"/cli/bin/immich /usr/bin/immich
    [[ ! -f /usr/bin/immich-admin ]] && ln -sf "$APP_DIR"/bin/immich-admin /usr/bin/immich-admin

    chown -R immich:immich "$INSTALL_DIR"
    if [[ "${MAINT_MODE:-0}" == 1 ]]; then
      msg_info "Disabling Maintenance Mode"
      cd /opt/immich/app/bin
      $STD ./immich-admin disable-maintenance-mode
      unset MAINT_MODE
      $STD cd -
      msg_ok "Disabled Maintenance Mode"
    fi
    systemctl restart immich-ml immich-web
    [[ -f /etc/systemd/system/immich-proxy.service ]] && systemctl restart immich-proxy
    msg_ok "Updated successfully!"
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
    [[ -d "$SOURCE" ]] && rm -rf "$SOURCE"
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
  ensure_dependencies libaom-dev
  : "${LIBHEIF_REVISION:=$(jq -cr '.revision' "$BASE_DIR"/server/sources/libheif.json)}"
  if [[ "${update:-}" ]] || [[ "$LIBHEIF_REVISION" != "$(grep 'libheif' ~/.immich_library_revisions | awk '{print $2}')" ]]; then
    msg_info "Recompiling libheif"
    [[ -d "$SOURCE" ]] && rm -rf "$SOURCE"
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
    $STD make install -j"$(nproc)"
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
    [[ -d "$SOURCE" ]] && rm -rf "$SOURCE"
    $STD git clone https://github.com/libraw/libraw.git "$SOURCE"
    cd "$SOURCE"
    $STD git reset --hard "$LIBRAW_REVISION"
    $STD autoreconf --install
    $STD ./configure --disable-examples
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
    [[ -d "$SOURCE" ]] && rm -rf "$SOURCE"
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
    [[ -d "$SOURCE" ]] && rm -rf "$SOURCE"
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

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:2283${CL}"
