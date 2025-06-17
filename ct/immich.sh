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
      $STD dpkg -i ./*.deb
      rm ./*.deb
      msg_ok "Intel iGPU dependencies updated"
    fi
    rm ~/Dockerfile
  fi
  if [[ -f ~/.immich_library_revisions ]]; then
    libraries=("libjxl" "libheif" "libraw" "imagemagick" "libvips")
    readarray -d '' NEW_REVISIONS < <(for library in "${libraries[@]}"; do
      echo "$library: $(curl -fsSL https://raw.githubusercontent.com/immich-app/base-images/refs/heads/main/server/sources/"$library".json | jq -cr '.revision' -)"
    done)
    UPDATED_REVISIONS="$(comm -13 <(sort ~/.immich_library_revisions) <(echo -n "${NEW_REVISIONS[@]}" | sort))"
    if [[ "$UPDATED_REVISIONS" ]]; then
      readarray -t NAMES < <(echo "$UPDATED_REVISIONS" | awk -F ':' '{print $1}')
      rm -rf "$SOURCE_DIR"
      mkdir -p "$SOURCE_DIR"
      cd "$BASE_DIR"
      $STD git pull
      cd "$STAGING_DIR"
      for name in "${NAMES[@]}"; do
        if [[ "$name" == "libjxl" ]]; then
          msg_info "Recompiling libjxl"
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
          msg_ok "Recompiled libjxl"
        fi
        if [[ "$name" == "libheif" ]]; then
          msg_info "Recompiling libheif"
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
            -DWITH_AOM_ENCODER=OFF \
            -DWITH_X265=OFF \
            -DWITH_EXAMPLES=OFF \
            ..
          $STD make install -j "$(nproc)"
          ldconfig /usr/local/lib
          $STD make clean
          cd "$STAGING_DIR"
          rm -rf "$SOURCE"/build
          msg_ok "Recompiled libheif"
        fi
        if [[ "$name" == "libraw" ]]; then
          msg_info "Recompiling libraw"
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
          msg_ok "Recompiled libraw"
        fi
        if [[ "$name" == "imagemagick" ]]; then
          msg_info "Recompiling ImageMagick"
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
          msg_ok "Recompiled ImageMagick"
        fi
        if [[ "$name" == "libvips" ]]; then
          msg_info "Recompiling libvips"
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
          msg_ok "Recompiled libvips"
        fi
      done
      echo -n "${NEW_REVISIONS[@]}" >~/.immich_library_revisions
      msg_ok "Image-processing libraries compiled"
    fi
  fi
  RELEASE=$(curl -s https://api.github.com/repos/immich-app/immich/releases?per_page=1 | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Stopping ${APP} services"
    systemctl stop immich-web
    systemctl stop immich-ml
    msg_ok "Stopped ${APP}"
    if [[ "$(cat /opt/${APP}_version.txt)" < "1.133.0" ]]; then
      msg_info "Upgrading to the VectorChord PostgreSQL extension"
      NUMBER="$(
        sed -n '2p' <(
          sudo -u postgres psql -A -d immich <<EOF
        SELECT atttypmod as dimsize
          FROM pg_attribute f
          JOIN pg_class c ON c.oid = f.attrelid
          WHERE c.relkind = 'r'::char
          AND f.attnum > 0
          AND c.relname = 'smart_search'::text
          AND f.attname = 'embedding'::text;
EOF
        )
      )"
      $STD sudo -u postgres psql -d immich <<EOF
      DROP INDEX IF EXISTS clip_index;
      DROP INDEX IF EXISTS face_index;
      ALTER TABLE smart_search ALTER COLUMN embedding SET DATA TYPE real[];
      ALTER TABLE face_search ALTER COLUMN embedding SET DATA TYPE real[];
EOF
      $STD apt-get update
      $STD apt-get install postgresql-16-pgvector -y
      curl -fsSL https://github.com/tensorchord/VectorChord/releases/download/0.3.0/postgresql-16-vchord_0.3.0-1_amd64.deb -o vchord.deb
      $STD dpkg -i vchord.deb
      rm vchord.deb
      sed -i "s|vectors.so|vchord.so|" /etc/postgresql/16/main/postgresql.conf
      systemctl restart postgresql.service
      $STD sudo -u postgres psql -d immich <<EOF
      CREATE EXTENSION IF NOT EXISTS vchord CASCADE;
      ALTER TABLE smart_search ALTER COLUMN embedding SET DATA TYPE vector($NUMBER);
      ALTER TABLE face_search ALTER COLUMN embedding SET DATA TYPE vector(512);
EOF
      $STD apt purge vectors-pg16 -y
      msg_ok "Database upgrade complete"
    fi
    INSTALL_DIR="/opt/${APP}"
    UPLOAD_DIR="$(sed -n '/^IMMICH_MEDIA_LOCATION/s/[^=]*=//p' /opt/immich/.env)"
    SRC_DIR="${INSTALL_DIR}/source"
    APP_DIR="${INSTALL_DIR}/app"
    ML_DIR="${APP_DIR}/machine-learning"
    GEO_DIR="${INSTALL_DIR}/geodata"
    cp "$ML_DIR"/ml_start.sh "$INSTALL_DIR"
    rm -rf "${APP_DIR:?}"/*
    rm -rf "$SRC_DIR"
    immich_zip=$(mktemp)
    curl -fsSL "https://github.com/immich-app/immich/archive/refs/tags/v${RELEASE}.zip" -o "$immich_zip"
    msg_info "Updating ${APP} web and microservices"
    unzip -q "$immich_zip"
    mv "$APP-$RELEASE"/ "$SRC_DIR"
    mkdir -p "$ML_DIR"
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
    msg_ok "Updated ${APP} web and microservices"

    cd "$SRC_DIR"/machine-learning
    $STD python3 -m venv "$ML_DIR"/ml-venv
    if [[ -f ~/.openvino ]]; then
      msg_info "Updating HW-accelerated machine-learning"
      (
        source "$ML_DIR"/ml-venv/bin/activate
        $STD pip3 install -U uv
        uv -q sync --extra openvino --no-cache --active
      )
      patchelf --clear-execstack "$ML_DIR"/ml-venv/lib/python3.11/site-packages/onnxruntime/capi/onnxruntime_pybind11_state.cpython-311-x86_64-linux-gnu.so
      msg_ok "Updated HW-accelerated machine-learning"
    else
      msg_info "Updating machine-learning"
      (
        source "$ML_DIR"/ml-venv/bin/activate
        $STD pip3 install -U uv
        uv -q sync --extra cpu --no-cache --active
      )
      msg_ok "Updated machine-learning"
    fi
    cd "$SRC_DIR"
    cp -a machine-learning/{ann,immich_ml} "$ML_DIR"
    cp "$INSTALL_DIR"/ml_start.sh "$ML_DIR"
    if [[ -f ~/.openvino ]]; then
      sed -i "/intra_op/s/int = 0/int = os.cpu_count() or 0/" "$ML_DIR"/immich_ml/config.py
    fi
    ln -sf "$APP_DIR"/resources "$INSTALL_DIR"
    cd "$APP_DIR"
    grep -Rl /usr/src | xargs -n1 sed -i "s|\/usr/src|$INSTALL_DIR|g"
    grep -RlE "'/build'" | xargs -n1 sed -i "s|'/build'|'$APP_DIR'|g"
    sed -i "s@\"/cache\"@\"$INSTALL_DIR/cache\"@g" "$ML_DIR"/immich_ml/config.py
    ln -s "${UPLOAD_DIR:-/opt/immich/upload}" "$APP_DIR"/upload
    ln -s "${UPLOAD_DIR:-/opt/immich/upload}" "$ML_DIR"/upload
    ln -s "$GEO_DIR" "$APP_DIR"

    msg_info "Updating Immich CLI"
    $STD npm install --build-from-source sharp
    rm -rf "$APP_DIR"/node_modules/@img/sharp-{libvips*,linuxmusl-x64}
    $STD npm i -g @immich/cli
    msg_ok "Updated Immich CLI"

    sed -i "s|pgvecto.rs|vectorchord|" /opt/"${APP}"/.env

    chown -R immich:immich "$INSTALL_DIR"
    echo "$RELEASE" >/opt/"${APP}"_version.txt
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Cleaning up"
    rm -f "$immich_zip"
    $STD apt-get -y autoremove
    $STD apt-get -y autoclean
    msg_ok "Cleaned"
  else
    msg_ok "${APP} is already at v${RELEASE}"
  fi
  systemctl restart immich-ml immich-web
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:2283${CL}"
