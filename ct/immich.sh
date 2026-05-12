#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://immich.app | Github: https://github.com/immich-app/immich

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

  if ! grep -qE '(^|[[:space:]])testing([[:space:]]|$)' /etc/apt/sources.list.d/debian.sources 2>/dev/null; then
    msg_info "Adding Debian Testing repo"
    if grep -q "trixie-updates" /etc/apt/sources.list.d/debian.sources 2>/dev/null; then
      sed -i 's/ trixie-updates/ trixie-updates testing/g' /etc/apt/sources.list.d/debian.sources
    else
      sed -i '/^[[:space:]]*Suites:.*trixie/ s/$/ testing/' /etc/apt/sources.list.d/debian.sources
    fi
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
    curl_with_retry "https://raw.githubusercontent.com/immich-app/immich/refs/heads/main/machine-learning/Dockerfile" "Dockerfile"
    readarray -t INTEL_URLS < <(
      sed -n "/intel-[igc|opencl]/p" ./Dockerfile | awk '{print $3}'
      sed -n "/libigdgmm12/p" ./Dockerfile | awk '{print $3}'
    )
    INTEL_RELEASE="$(grep "intel-opencl-icd_" ./Dockerfile | awk -F '_' '{print $2}')"
    if [[ "$INTEL_RELEASE" != "$(cat ~/.intel_version)" ]]; then
      msg_info "Updating Intel OpenVINO dependencies"
      for url in "${INTEL_URLS[@]}"; do
        curl_with_retry "$url" "$(basename "$url")"
      done
      $STD apt-mark unhold libigdgmm12
      $STD apt install -y --allow-downgrades ./libigdgmm12*.deb
      rm ./libigdgmm12*.deb
      $STD apt install -y ./*.deb
      rm ./*.deb
      $STD apt-mark hold libigdgmm12
      dpkg-query -W -f='${Version}\n' intel-opencl-icd >~/.intel_version
      rm -f ./Dockerfile
      msg_ok "Updated Intel OpenVINO dependencies"
    fi
  fi
  if [[ -f ~/.immich_library_revisions ]]; then
    libraries=("libjxl" "libheif" "libraw" "imagemagick" "libvips")
    cd "$BASE_DIR"
    msg_warn "Checking for updates to custom image-processing libraries (recompile time: 2-15min per library)"
    $STD git pull
    for library in "${libraries[@]}"; do
      compile_"$library"
    done
    msg_ok "Image-processing libraries up to date"
  fi

  RELEASE="v2.7.5"
  if check_for_gh_release "Immich" "immich-app/immich" "${RELEASE}" "each release is tested individually before the version is updated. Please do not open issues for this"; then
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
    if check_for_gh_release "VectorChord" "tensorchord/VectorChord" "${VCHORD_RELEASE}" "updated together with Immich after testing"; then
      fetch_and_deploy_gh_release "VectorChord" "tensorchord/VectorChord" "binary" "${VCHORD_RELEASE}" "/tmp" "postgresql-16-vchord_*_amd64.deb"
      systemctl restart postgresql
      $STD sudo -u postgres psql -d immich -c "ALTER EXTENSION vector UPDATE;"
      $STD sudo -u postgres psql -d immich -c "ALTER EXTENSION vchord UPDATE;"
      $STD sudo -u postgres psql -d immich -c "REINDEX INDEX face_index;"
      $STD sudo -u postgres psql -d immich -c "REINDEX INDEX clip_index;"
    fi
    ensure_dependencies ccache gcc-13 g++-13

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
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Immich" "immich-app/immich" "tarball" "${RELEASE}" "$SRC_DIR"
    PNPM_VERSION="$(jq -r '.packageManager | split("@")[1] | split("+")[0]' ${SRC_DIR}/package.json)"
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

    # Patch helmet.json: disable upgrade-insecure-requests for HTTP access
    if [[ -f "$APP_DIR/helmet.json" ]]; then
      jq '.contentSecurityPolicy.directives["upgrade-insecure-requests"] = null' "$APP_DIR/helmet.json" >"$APP_DIR/helmet.json.tmp" && mv "$APP_DIR/helmet.json.tmp" "$APP_DIR/helmet.json"
    fi

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
    mkdir -p "$ML_DIR"
    # chown excluding upload dir contents (may be a mount with restricted permissions)
    chown immich:immich "$INSTALL_DIR"
    find "$INSTALL_DIR" -maxdepth 1 -mindepth 1 ! -name upload -exec chown -R immich:immich {} +
    chown immich:immich "${UPLOAD_DIR:-$INSTALL_DIR/upload}" 2>/dev/null || true
    chown immich:immich ./uv.lock
    export VIRTUAL_ENV="${ML_DIR}"/ml-venv
    export UV_HTTP_TIMEOUT=300
    if [[ -f ~/.openvino ]]; then
      ML_PYTHON="python3.13"
      msg_info "Pre-installing Python ${ML_PYTHON} for machine-learning"
      for attempt in $(seq 1 3); do
        $STD sudo --preserve-env=VIRTUAL_ENV -nu immich uv python install "${ML_PYTHON}" && break
        [[ $attempt -lt 3 ]] && msg_warn "Python download attempt $attempt failed, retrying..." && sleep 5
      done
      msg_ok "Pre-installed Python ${ML_PYTHON}"
      msg_info "Updating Intel OpenVINO machine-learning"
      for attempt in $(seq 1 3); do
        $STD sudo --preserve-env=VIRTUAL_ENV,UV_HTTP_TIMEOUT -nu immich uv sync --extra openvino --no-dev --active --link-mode copy -n -p "${ML_PYTHON}" --managed-python && break
        [[ $attempt -lt 3 ]] && msg_warn "uv sync attempt $attempt failed, retrying..." && sleep 10
      done
      patchelf --clear-execstack "${VIRTUAL_ENV}/lib/python3.13/site-packages/onnxruntime/capi/onnxruntime_pybind11_state.cpython-313-x86_64-linux-gnu.so"
      msg_ok "Updated Intel OpenVINO machine-learning"
    else
      ML_PYTHON="python3.11"
      msg_info "Pre-installing Python ${ML_PYTHON} for machine-learning"
      for attempt in $(seq 1 3); do
        $STD sudo --preserve-env=VIRTUAL_ENV -nu immich uv python install "${ML_PYTHON}" && break
        [[ $attempt -lt 3 ]] && msg_warn "Python download attempt $attempt failed, retrying..." && sleep 5
      done
      msg_ok "Pre-installed Python ${ML_PYTHON}"
      msg_info "Updating machine-learning"
      for attempt in $(seq 1 3); do
        $STD sudo --preserve-env=VIRTUAL_ENV,UV_HTTP_TIMEOUT -nu immich uv sync --extra cpu --no-dev --active --link-mode copy -n -p "${ML_PYTHON}" --managed-python && break
        [[ $attempt -lt 3 ]] && msg_warn "uv sync attempt $attempt failed, retrying..." && sleep 10
      done
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

    if ! grep -q '^DB_HOSTNAME=' "$INSTALL_DIR"/.env; then
      sed -i '/^DB_DATABASE_NAME/a DB_HOSTNAME=127.0.0.1' "$INSTALL_DIR"/.env
    fi
    if ! grep -q 'HELMET_FILE' "$INSTALL_DIR"/.env; then
      sed -i -e '$a\' "$INSTALL_DIR"/.env
      echo "IMMICH_HELMET_FILE=true" >>"$INSTALL_DIR"/.env
    fi

    if grep -q 'ExecStart=/usr/bin/node' /etc/systemd/system/immich-web.service; then
      sed -i '/^EnvironmentFile=/d' /etc/systemd/system/immich-web.service
      sed -i "s|^ExecStart=.*|ExecStart=${APP_DIR}/bin/start.sh|" /etc/systemd/system/immich-web.service
      systemctl daemon-reload
    fi

    # chown excluding upload dir contents (may be a mount with restricted permissions)
    chown immich:immich "$INSTALL_DIR"
    find "$INSTALL_DIR" -maxdepth 1 -mindepth 1 ! -name upload -exec chown -R immich:immich {} +
    chown immich:immich "${UPLOAD_DIR:-$INSTALL_DIR/upload}" 2>/dev/null || true
    if [[ "${MAINT_MODE:-0}" == 1 ]]; then
      msg_info "Disabling Maintenance Mode"
      cd /opt/immich/app/bin
      $STD ./immich-admin disable-maintenance-mode || true
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
  LIBJXL_REVISION="794a5dcf0d54f9f0b20d288a12e87afb91d20dfc"
  # : "${LIBJXL_REVISION:=$(jq -cr '.revision' "$BASE_DIR"/server/sources/libjxl.json)}"
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
  LIBHEIF_REVISION="35dad50a9145332a7bfdf1ff6aef6801fb613d68"
  # : "${LIBHEIF_REVISION:=$(jq -cr '.revision' "$BASE_DIR"/server/sources/libheif.json)}"
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
  LIBRAW_REVISION="0b56545a4f828743f28a4345cdfdd4c49f9f9a2a"
  # : "${LIBRAW_REVISION:=$(jq -cr '.revision' "$BASE_DIR"/server/sources/libraw.json)}"
  if [[ "$LIBRAW_REVISION" != "$(grep 'libraw' ~/.immich_library_revisions | awk '{print $2}')" ]]; then
    msg_info "Recompiling libraw"
    [[ -d "$SOURCE" ]] && rm -rf "$SOURCE"
    $STD git clone https://github.com/LibRaw/LibRaw.git "$SOURCE"
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
  LIBVIPS_REVISION="0c9151a4f416d2f8ae20a755db218f6637050eec"
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
