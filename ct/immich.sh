#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
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
var_arm64="${var_arm64:-yes}"
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

  if ! grep -qsE '^[[:space:]]*Suites:.*(^|[[:space:]])testing([[:space:]]|$)' /etc/apt/sources.list.d/*.sources; then
    msg_info "Adding Debian Testing repo"
    if grep -q "trixie-updates" /etc/apt/sources.list.d/debian.sources 2>/dev/null; then
      sed -i 's/ trixie-updates/ trixie-updates testing/g' /etc/apt/sources.list.d/debian.sources
    elif grep -qsE '^[[:space:]]*Suites:.*trixie' /etc/apt/sources.list.d/debian.sources; then
      sed -i '/^[[:space:]]*Suites:.*trixie/ s/$/ testing/' /etc/apt/sources.list.d/debian.sources
    else
      cat <<EOF >/etc/apt/sources.list.d/testing.sources
Types: deb
URIs: http://deb.debian.org/debian
Suites: testing
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
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
    apt_update_safe
    msg_ok "Added Debian Testing repo"
  fi

  if ! dpkg -l "libmimalloc3" | grep -q '3.1' || ! dpkg -l "libde265-dev" | grep -q '1.0.16'; then
    msg_info "Installing/upgrading Testing repo packages"
    $STD apt install -t testing libmimalloc3 libde265-dev -y
    msg_ok "Installed/upgraded Testing repo packages"
  fi

  if ! command -v mise >/dev/null 2>&1; then
    MISE_ARCH="x64"
    [[ "$(arch_resolve)" == "arm64" ]] && MISE_ARCH="arm64"
    fetch_and_deploy_gh_release "mise" "jdx/mise" "singlefile" "latest" "/usr/local/bin" "mise-v*-linux-${MISE_ARCH}"
  fi

  cd /tmp
  RELEASE="v3.4.1"
  if [[ -f ~/.intel_version ]]; then
    INTEL_SRC="https://raw.githubusercontent.com/immich-app/immich/${RELEASE}/machine-learning"
    curl -fsSL "${INTEL_SRC}/scripts/install-intel-runtime.sh" -o ./intel-runtime 2>/dev/null ||
      curl_with_retry "${INTEL_SRC}/Dockerfile" "./intel-runtime"
    readarray -t INTEL_URLS < <(grep -oE 'https://github\.com/intel/[^[:space:]]+\.deb' ./intel-runtime)
    INTEL_RELEASE="$(grep -oE 'intel-opencl-icd_[^_]+' ./intel-runtime | cut -d_ -f2)" || true
    rm -f ./intel-runtime
    if [[ -z "$INTEL_RELEASE" ]]; then
      msg_warn "No Intel runtime found for Immich ${RELEASE}, keeping the installed one"
    elif [[ "$INTEL_RELEASE" != "$(cat ~/.intel_version)" ]]; then
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
      msg_ok "Updated Intel OpenVINO dependencies"
    fi
  fi
  # Libraries the prebuilt image-processing libraries link against; pigz compresses database backups.
  ensure_dependencies liblcms2-dev libjpeg62-turbo-dev libspng-dev libexif-dev libopenjp2-7-dev libaom-dev pigz

  # 3.3.0 reads geodata/countryInfo.txt; the update before #17823 saved it into app/ instead.
  if [[ -d /opt/immich/geodata && ! -s /opt/immich/geodata/countryInfo.txt ]]; then
    msg_info "Restoring geodata/countryInfo.txt"
    if [[ -s /opt/immich/app/countryInfo.txt ]]; then
      mv /opt/immich/app/countryInfo.txt /opt/immich/geodata/countryInfo.txt
    else
      curl_with_retry "https://download.geonames.org/export/dump/countryInfo.txt" /opt/immich/geodata/countryInfo.txt
    fi
    chown immich:immich /opt/immich/geodata/countryInfo.txt
    systemctl restart immich-web
    msg_ok "Restored geodata/countryInfo.txt"
  fi

  if check_for_gh_release "Immich" "immich-app/immich" "${RELEASE}" "each release is tested individually before the version is updated. Please do not open issues for this"; then
    msg_warn "The update takes 5-15 minutes, do not interrupt it"
    fetch_prebuilt_libs
    PREV_IMMICH="${CS_PREVIOUS_VERSION:-$(cat ~/.immich)}"
    INSTALL_DIR="/opt/${APP}"
    UPLOAD_DIR="$(sed -n '/^IMMICH_MEDIA_LOCATION/s/[^=]*=//p' /opt/immich/.env)"
    SRC_DIR="${INSTALL_DIR}/source"
    APP_DIR="${INSTALL_DIR}/app"
    PLUGIN_DIR="${APP_DIR}/plugins/immich-plugin-core"
    ML_DIR="${APP_DIR}/machine-learning"
    GEO_DIR="${INSTALL_DIR}/geodata"

    setup_uv
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Immich" "immich-app/immich" "tarball" "${RELEASE}" "$SRC_DIR"

    # An interrupted update leaves app/ empty, so there may be no immich-admin to call.
    if [[ "$PREV_IMMICH" > "2.5.1" && -x /opt/immich/app/bin/immich-admin ]]; then
      msg_info "Enabling Maintenance Mode"
      cd /opt/immich/app/bin
      $STD ./immich-admin enable-maintenance-mode || true
      export MAINT_MODE=1
      $STD cd -
      msg_ok "Enabled Maintenance Mode"
    fi
    [[ -x /opt/immich/app/bin/immich-admin ]] || export MAINT_MODE=1
    msg_info "Stopping Services"
    systemctl stop immich-web
    systemctl stop immich-ml
    msg_ok "Stopped Services"
    install_prebuilt_libs
    VCHORD_RELEASE="1.1.1"
    PG_VERSION=$(ls /etc/postgresql/ 2>/dev/null | sort -V | tail -1)
    PG_VERSION=${PG_VERSION:-16}
    [[ -f ~/.vchord_version ]] && mv ~/.vchord_version ~/.vectorchord
    if check_for_gh_release "VectorChord" "supervc-stack/VectorChord" "${VCHORD_RELEASE}" "updated together with Immich after testing"; then
      # dead tuples in smart_search/face_search make the REINDEX below fail with
      # "missing chunk ... for toast value" on VectorChord 1.0.0 (#15588); must vacuum
      # while still on the old extension version, a post-upgrade vacuum errors instead
      $STD sudo -u postgres psql -d immich -c "VACUUM (ANALYZE) smart_search;"
      $STD sudo -u postgres psql -d immich -c "VACUUM (ANALYZE) face_search;"
      fetch_and_deploy_gh_release "VectorChord" "supervc-stack/VectorChord" "binary" "${VCHORD_RELEASE}" "/tmp" "postgresql-${PG_VERSION}-vchord_*_$(arch_resolve).deb"
      systemctl restart postgresql
      $STD sudo -u postgres psql -d immich -c "ALTER EXTENSION vector UPDATE;"
      $STD sudo -u postgres psql -d immich -c "ALTER EXTENSION vchord UPDATE;"
      $STD sudo -u postgres psql -d immich -c "REINDEX INDEX face_index;"
      $STD sudo -u postgres psql -d immich -c "REINDEX INDEX clip_index;"
    fi

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

    PNPM_VERSION="$(jq -r '.packageManager | split("@")[1] | split("+")[0]' ${SRC_DIR}/package.json)"
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    export CI=1
    NODE_VERSION="24" NODE_MODULE="corepack" setup_nodejs
    $STD corepack prepare "pnpm@${PNPM_VERSION}" --activate
    export PATH="/root/.local/share/pnpm/bin:$PATH"
    $STD pnpm config set --global dangerouslyAllowAllBuilds true

    msg_info "Updating Immich web and microservices"
    cd "$SRC_DIR"/server
    # server build
    $STD pnpm --filter @immich/sdk --filter @immich/plugin-sdk --filter immich build
    $STD pnpm --filter immich --prod --no-optional deploy "$APP_DIR"
    export SHARP_FORCE_GLOBAL_LIBVIPS=true
    $STD pnpm --dir "$APP_DIR/node_modules/sharp" exec npm run build

    # Patch helmet.json: disable upgrade-insecure-requests for HTTP access
    if [[ -f "$APP_DIR/helmet.json" ]]; then
      jq '.contentSecurityPolicy.directives["upgrade-insecure-requests"] = null' "$APP_DIR/helmet.json" >"$APP_DIR/helmet.json.tmp" && mv "$APP_DIR/helmet.json.tmp" "$APP_DIR/helmet.json"
    fi

    cp "$APP_DIR"/package.json "$APP_DIR"/bin
    sed -i "s|^start|${APP_DIR}/bin/start|" "$APP_DIR"/bin/immich-admin

    # sdk, cli & web build
    cd "$SRC_DIR"
    echo "packageImportMethod: hardlink" >>./pnpm-workspace.yaml
    unset SHARP_FORCE_GLOBAL_LIBVIPS
    $STD pnpm --filter @immich/sdk --filter immich-web --filter @immich/cli build
    $STD pnpm --filter @immich/cli --prod --no-optional deploy "$APP_DIR"/cli
    cp -a web/build "$APP_DIR"/www
    cp LICENSE "$APP_DIR"
    [[ -f "$INSTALL_DIR"/start.sh ]] && mv "$INSTALL_DIR"/start.sh "$APP_DIR"/bin

    # plugins
    cd "$SRC_DIR"
    export MISE_TRUSTED_CONFIG_PATHS="$SRC_DIR"/mise.toml
    export MISE_DISABLE_TOOLS=github:jellyfin/jellyfin-ffmpeg,java,terragrunt,opentofu,restic,npm:@openapitools/openapi-generator-cli
    export MISE_LOCKFILE_MODE=merge MISE_LOCKFILE_PLATFORMS="linux-$(arch_resolve x64 arm64)"
    mise_ok=0
    for i in 1 2 3; do
      $STD mise install && {
        mise_ok=1
        break
      }
      msg_warn "mise install failed (attempt $i/3) - retrying"
      sleep 5
    done
    [[ "$mise_ok" -eq 1 ]] || exit 1
    export PATH="$(mise bin-paths 2>/dev/null | tr '\n' ':')$PATH"
    if ! command -v extism-js >/dev/null 2>&1; then
      # extism-js ships as a bare gzip-compressed single binary (.gz) that
      # fetch_and_deploy_gh_release cannot deploy; fetch + gunzip it directly.
      EXTISM_ARCH="$(arch_resolve x86_64 aarch64)"
      EXTISM_VERSION="$(grep -oP '"github:extism/js-pdk"\s*=\s*"\K[^"]+' "$SRC_DIR"/mise.toml)"
      curl_download /tmp/extism-js.gz "https://github.com/extism/js-pdk/releases/download/${EXTISM_VERSION}/extism-js-${EXTISM_ARCH}-linux-${EXTISM_VERSION}.gz"
      gunzip -f /tmp/extism-js.gz
      install -m 0755 /tmp/extism-js /usr/local/bin/extism-js
      rm -f /tmp/extism-js
    fi
    if ! command -v wasm-merge >/dev/null 2>&1; then
      # extism-js needs binaryen's `wasm-merge` to build the plugin wasm. mise
      # 2026.7.0's github backend no longer exposes `wasm-merge` on PATH (ubi only
      # extracts a single binary), so install the pinned binaryen release from
      # mise.toml directly. The extracted bin/ keeps libbinaryen.so alongside it.
      BINARYEN_VERSION="$(grep -oiP 'binaryen"\s*=\s*"\Kversion_[0-9]+' "$SRC_DIR"/mise.toml | head -n1)"
      [[ -z "$BINARYEN_VERSION" ]] && BINARYEN_VERSION="version_124"
      BINARYEN_ARCH="$(arch_resolve x86_64 aarch64)"
      curl_download /tmp/binaryen.tar.gz "https://github.com/WebAssembly/binaryen/releases/download/${BINARYEN_VERSION}/binaryen-${BINARYEN_VERSION}-${BINARYEN_ARCH}-linux.tar.gz"
      tar -xzf /tmp/binaryen.tar.gz -C /opt
      rm -f /tmp/binaryen.tar.gz
      export PATH="/opt/binaryen-${BINARYEN_VERSION}/bin:$PATH"
    fi
    $STD mise exec -- pnpm --filter @immich/sdk --filter @immich/plugin-sdk --filter @immich/plugin-core install --frozen-lockfile
    $STD mise exec -- pnpm --filter @immich/sdk --filter @immich/plugin-sdk --filter @immich/plugin-core build
    mkdir -p "$PLUGIN_DIR"
    cp -r ./packages/plugin-core/dist "$PLUGIN_DIR"/dist
    cp ./packages/plugin-core/manifest.json "$PLUGIN_DIR"
    msg_ok "Updated Immich server, web, cli and plugins"

    RESTIC_REF="$(grep -oP 'futo-org/restic:sha-\K[0-9a-f]+' "$SRC_DIR"/server/Dockerfile)"
    RESTIC_PROXY_REF="$(grep -oP 'futo-org/backups/restic-proxy:\K[^@]+' "$SRC_DIR"/server/Dockerfile)"
    if [[ "$(cat ~/.immich_restic 2>/dev/null)" != "${RESTIC_REF} ${RESTIC_PROXY_REF}" || ! -x /usr/local/bin/restic ]]; then
      FUTO_DIR=/opt/staging/futo
      rm -rf "$FUTO_DIR"
      $STD git clone --filter=blob:none --no-checkout https://github.com/futo-org/restic "$FUTO_DIR"/restic
      $STD git -C "$FUTO_DIR"/restic checkout "$RESTIC_REF"
      $STD git clone --depth 1 --filter=blob:none --sparse -b "$RESTIC_PROXY_REF" https://github.com/futo-org/backups "$FUTO_DIR"/backups
      $STD git -C "$FUTO_DIR"/backups sparse-checkout set packages/restic-proxy
      GO_VERSION="$(awk '/^go /{print $2}' "$FUTO_DIR"/backups/packages/restic-proxy/go.mod)" setup_go
      msg_info "Building restic for FUTO Backups"
      cd "$FUTO_DIR"/restic
      $STD env CGO_ENABLED=0 go build -o /usr/local/bin/restic ./cmd/restic
      cd "$FUTO_DIR"/backups/packages/restic-proxy
      $STD env CGO_ENABLED=0 go build -o /usr/local/bin/restic-proxy .
      cd "$SRC_DIR"
      rm -rf "$FUTO_DIR"
      echo "${RESTIC_REF} ${RESTIC_PROXY_REF}" >~/.immich_restic
      msg_ok "Built restic for FUTO Backups"
    fi

    cd "$SRC_DIR"/machine-learning
    mkdir -p "$ML_DIR"
    # chown excluding upload dir contents (may be a mount with restricted permissions)
    chown immich:immich "$INSTALL_DIR"
    find "$INSTALL_DIR" -maxdepth 1 -mindepth 1 ! -name upload -exec chown -R immich:immich {} +
    chown immich:immich "${UPLOAD_DIR:-$INSTALL_DIR/upload}" 2>/dev/null || true
    chown immich:immich ./uv.lock
    export VIRTUAL_ENV="${ML_DIR}"/ml-venv
    if [[ -f ~/.openvino ]]; then
      ML_PYTHON="python3.13"
      msg_info "Pre-installing Python ${ML_PYTHON} for machine-learning"
      for attempt in $(seq 1 3); do
        $STD sudo --preserve-env=VIRTUAL_ENV -Pnu immich uv python install "${ML_PYTHON}" && break
        [[ $attempt -lt 3 ]] && msg_warn "Python download attempt $attempt failed, retrying..." && sleep 5
      done
      msg_ok "Pre-installed Python ${ML_PYTHON}"
      msg_info "Updating Intel OpenVINO machine-learning"
      for attempt in $(seq 1 3); do
        $STD sudo --preserve-env=VIRTUAL_ENV,UV_HTTP_TIMEOUT,UV_CONCURRENT_DOWNLOADS,UV_CONCURRENT_BUILDS,UV_CONCURRENT_INSTALLS -Pnu immich uv sync --extra openvino --no-dev --upgrade-package watchfiles --active --link-mode copy -n -p "${ML_PYTHON}" --managed-python && break
        [[ $attempt -eq 3 ]] && { ML_FAILED=1; break; }
        # Parallel fetches can trip DNS rate limits (AdGuard, Pi-hole); retry one at a time.
        export UV_CONCURRENT_DOWNLOADS=1 UV_CONCURRENT_BUILDS=1 UV_CONCURRENT_INSTALLS=1
        msg_warn "uv sync attempt $attempt failed, retrying one download at a time..." && sleep 10
      done
      [[ "${ML_FAILED:-0}" == 1 ]] || patchelf --clear-execstack "${VIRTUAL_ENV}/lib/python3.13/site-packages/onnxruntime/capi/onnxruntime_pybind11_state.cpython-313-$(arch_resolve "x86_64" "aarch64")-linux-gnu.so"
      [[ "${ML_FAILED:-0}" == 1 ]] || msg_ok "Updated Intel OpenVINO machine-learning"
    else
      ML_PYTHON="python3.13"
      msg_info "Pre-installing Python ${ML_PYTHON} for machine-learning"
      for attempt in $(seq 1 3); do
        $STD sudo --preserve-env=VIRTUAL_ENV -Pnu immich uv python install "${ML_PYTHON}" && break
        [[ $attempt -lt 3 ]] && msg_warn "Python download attempt $attempt failed, retrying..." && sleep 5
      done
      msg_ok "Pre-installed Python ${ML_PYTHON}"
      msg_info "Updating machine-learning"
      for attempt in $(seq 1 3); do
        $STD sudo --preserve-env=VIRTUAL_ENV,UV_HTTP_TIMEOUT,UV_CONCURRENT_DOWNLOADS,UV_CONCURRENT_BUILDS,UV_CONCURRENT_INSTALLS -Pnu immich uv sync --extra cpu --no-dev --upgrade-package watchfiles --active --link-mode copy -n -p "${ML_PYTHON}" --managed-python && break
        [[ $attempt -eq 3 ]] && { ML_FAILED=1; break; }
        # Parallel fetches can trip DNS rate limits (AdGuard, Pi-hole); retry one at a time.
        export UV_CONCURRENT_DOWNLOADS=1 UV_CONCURRENT_BUILDS=1 UV_CONCURRENT_INSTALLS=1
        msg_warn "uv sync attempt $attempt failed, retrying one download at a time..." && sleep 10
      done
      [[ "${ML_FAILED:-0}" == 1 ]] || msg_ok "Updated machine-learning"
    fi
    [[ "${ML_FAILED:-0}" == 1 ]] && msg_warn "uv sync failed three times, machine learning was not updated"
    cd "$SRC_DIR"
    cp -a machine-learning/{ann,immich_ml} "$ML_DIR"
    [[ -f "$INSTALL_DIR"/ml_start.sh ]] && mv "$INSTALL_DIR"/ml_start.sh "$ML_DIR"
    # Regenerate ml_start.sh if it is missing (e.g. lost by a previously interrupted update),
    # otherwise immich-ml.service fails to start with status=203/EXEC
    if [[ ! -f "$ML_DIR"/ml_start.sh ]]; then
      cat <<EOF >"$ML_DIR"/ml_start.sh
#!/usr/bin/env bash

cd ${ML_DIR}
. ${VIRTUAL_ENV}/bin/activate

set -a
. ${INSTALL_DIR}/.env
set +a

python3 -m immich_ml
EOF
      chmod +x "$ML_DIR"/ml_start.sh
    fi
    [[ -f ~/.openvino ]] && sed -i "/intra_op/s/int = 0/int = os.cpu_count() or 0/" "$ML_DIR"/immich_ml/config.py
    ln -sf "$APP_DIR"/resources "$INSTALL_DIR"
    cd "$APP_DIR"
    grep -rl /usr/src | xargs -n1 sed -i "s|\/usr/src|$INSTALL_DIR|g"
    grep -rlE "'/build'" | xargs -n1 sed -i "s|'/build'|'$APP_DIR'|g"
    sed -i "s@\"/cache\"@\"$INSTALL_DIR/cache\"@g" "$ML_DIR"/immich_ml/config.py
    [[ ! -f "$GEO_DIR/countryInfo.txt" ]] && curl_with_retry "https://download.geonames.org/export/dump/countryInfo.txt" "$GEO_DIR/countryInfo.txt"
    ln -s "${UPLOAD_DIR:-/opt/immich/upload}" "$APP_DIR"/upload
    ln -s "${UPLOAD_DIR:-/opt/immich/upload}" "$ML_DIR"/upload
    ln -sfn "$GEO_DIR" "$APP_DIR/geodata"
    [[ ! -f /usr/bin/immich ]] && ln -sf "$APP_DIR"/cli/bin/immich /usr/bin/immich
    [[ ! -f /usr/bin/immich-admin ]] && ln -sf "$APP_DIR"/bin/immich-admin /usr/bin/immich-admin

    if ! grep -q '^DB_HOSTNAME=' "$INSTALL_DIR"/.env; then
      sed -i '/^DB_DATABASE_NAME/a DB_HOSTNAME=127.0.0.1' "$INSTALL_DIR"/.env
    fi
    if ! grep -q 'HELMET_FILE' "$INSTALL_DIR"/.env; then
      sed -i -e '$a\' "$INSTALL_DIR"/.env
      echo "IMMICH_HELMET_FILE=true" >>"$INSTALL_DIR"/.env
    fi
    if ! grep -q 'MODEL_REVISION' "$INSTALL_DIR"/.env; then
      sed -i -e '$a\' "$INSTALL_DIR"/.env
      echo "MACHINE_LEARNING_MODEL_REVISION=v2" >>"$INSTALL_DIR"/.env
    fi

    if grep -q 'ExecStart=/usr/bin/node' /etc/systemd/system/immich-web.service; then
      sed -i '/^EnvironmentFile=/d' /etc/systemd/system/immich-web.service
      sed -i "s|^ExecStart=.*|ExecStart=${APP_DIR}/bin/start.sh|" /etc/systemd/system/immich-web.service
      systemctl daemon-reload
    fi
    if grep -q "^ExecStart=${INSTALL_DIR}/ml_start.sh" /etc/systemd/system/immich-ml.service; then
      sed -i "s|^ExecStart=.*|ExecStart=${ML_DIR}/ml_start.sh|" /etc/systemd/system/immich-ml.service
      systemctl daemon-reload
    fi

    # MickLesk temporary patch for HEIC thumbnail gen
    MEDIA_REPO_JS="/opt/immich/app/dist/repositories/media.repository.js"
    if grep -qF "(0, sharp_1.default)(input).metadata()" "$MEDIA_REPO_JS" 2>/dev/null; then
      msg_info "Patching media.repository.js"
      sed -i '0,/(0, sharp_1\.default)(input)\.metadata()/s//(0, sharp_1.default)(input, { unlimited: true, limitInputPixels: false }).metadata()/' "$MEDIA_REPO_JS"
      msg_ok "Patched media.repository.js"
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
    # A crash loop before the update leaves the units rate-limited, and restart would refuse.
    systemctl reset-failed immich-ml immich-web 2>/dev/null || true
    if [[ "${ML_FAILED:-0}" == 1 ]]; then
      systemctl restart immich-web || true
      [[ -f /etc/systemd/system/immich-proxy.service ]] && systemctl restart immich-proxy
      echo "$PREV_IMMICH" >~/.immich
      msg_error "Immich runs, but without machine learning (see the uv output above). Run update again to retry."
      exit 1
    fi
    systemctl restart immich-ml immich-web
    [[ -f /etc/systemd/system/immich-proxy.service ]] && systemctl restart immich-proxy
    msg_ok "Updated successfully!"
  fi
  exit
}

# Immich ships the custom photo-processing libraries (libjxl, jpegli, libheif,
# libraw, ImageMagick, libvips) prebuilt in its own OCI base image; the release's
# Dockerfile pins it. fetch_prebuilt_libs downloads and unpacks it while Immich
# still runs, so a failure leaves the install as it was. install_prebuilt_libs
# copies it into /usr/local once the services are stopped.
function fetch_prebuilt_libs() {
  PREBUILT_BUNDLE=""
  BASE_REF="$(curl -fsSL "https://raw.githubusercontent.com/immich-app/immich/${RELEASE}/server/Dockerfile" | awk '/^FROM ghcr.io\/immich-app\/base-server-dev/ {print $2; exit}')" || true
  if [[ -z "$BASE_REF" ]]; then
    msg_error "Could not read the base image from Immich ${RELEASE}'s Dockerfile. Immich was not updated."
    exit 115
  fi
  [[ "$(cat ~/.immich_base_image 2>/dev/null)" == "$BASE_REF" ]] && return 0
  msg_info "Fetching prebuilt image-processing libraries"
  # skopeo refuses a reference with both a tag and a digest; the digest is the pin.
  local image="$BASE_REF"
  [[ "$BASE_REF" == *@sha256:* ]] && image="ghcr.io/immich-app/base-server-dev@${BASE_REF#*@}"
  if ! { command -v skopeo && command -v umoci; } >/dev/null 2>&1 &&
    ! $STD apt install -y --no-install-recommends skopeo umoci; then
    msg_error "Could not install skopeo and umoci, which Immich needs for its image-processing libraries. Immich was not updated."
    exit 105
  fi
  local oci_dir
  oci_dir="$(mktemp -d)"
  PREBUILT_BUNDLE="$(mktemp -d)"
  if ! $STD skopeo copy --override-os linux --override-arch "$(arch_resolve amd64 arm64)" "docker://${image}" "oci:${oci_dir}:img"; then
    rm -rf "$oci_dir" "$PREBUILT_BUNDLE"
    msg_error "Could not download Immich's base image (${image}). Immich was not updated."
    exit 115
  fi
  if ! $STD umoci unpack --image "${oci_dir}:img" "$PREBUILT_BUNDLE"; then
    rm -rf "$oci_dir" "$PREBUILT_BUNDLE"
    msg_error "Could not unpack Immich's base image. Immich needs Proxmox VE 9.1 or newer; it was not updated."
    exit 105
  fi
  rm -rf "$oci_dir"
  msg_ok "Fetched prebuilt image-processing libraries"
}

function install_prebuilt_libs() {
  [[ -n "${PREBUILT_BUNDLE:-}" ]] || return 0
  msg_info "Installing prebuilt image-processing libraries"
  # The libraries, headers and ImageMagick data, without the node runtime, global
  # node modules and ffmpeg of the node base image: this script provides those.
  tar -C "${PREBUILT_BUNDLE}/rootfs/usr/local" \
    --exclude=./bin/node --exclude=./bin/npm --exclude=./bin/npx --exclude=./bin/corepack \
    --exclude=./bin/ffmpeg --exclude=./bin/ffprobe \
    --exclude=./lib/node_modules --exclude=./include/node \
    -cf - . | tar -C /usr/local -xf -
  rm -rf "$PREBUILT_BUNDLE"
  ldconfig /usr/local/lib
  if ! vips --version >/dev/null 2>&1 || ! pkg-config --exists vips; then
    msg_error "The prebuilt libvips from ${BASE_REF} does not work in this container."
    exit 1
  fi
  echo "$BASE_REF" >~/.immich_base_image
  # Leftovers of the libraries this script used to compile.
  rm -rf /opt/staging/base-images /opt/staging/image-source ~/.immich_library_revisions
  msg_ok "Installed prebuilt image-processing libraries"
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:2283${CL}"
