#!/usr/bin/env bash
export PVE_SCRIPT_REPO="${PVE_SCRIPT_REPO:-epiHATR/ProxmoxVE}"
source <(curl -fsSL "https://raw.githubusercontent.com/${PVE_SCRIPT_REPO}/main/misc/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://onetimesecret.com | Github: https://github.com/onetimesecret/onetimesecret

APP="OneTimeSecret"
var_tags="${var_tags:-security;secrets;privacy}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  local APP_ROOT="/var/lib/onetimesecret"
  local APP_DIR="${APP_ROOT}/app"
  local APP_USER="onetime"
  local APP_GROUP="onetime"
  local OTS_HOST_VALUE="${OTS_HOST:-}"
  local OTS_SSL_VALUE="${OTS_SSL:-}"

  run_app_as_user() {
    local cmd="$1"
    runuser -u "$APP_USER" -- env \
      HOME="$APP_ROOT" \
      LANG="$LANG" \
      LC_ALL="$LC_ALL" \
      AUTHENTICATION_MODE="simple" \
      REDIS_URL="redis://127.0.0.1:6379/0" \
      RACK_ENV="production" \
      NODE_ENV="production" \
      PATH="$APP_ROOT/.rbenv/shims:$APP_ROOT/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
      bash -lc "cd \"$APP_DIR\" && eval \"\$($APP_ROOT/.rbenv/bin/rbenv init - bash)\" && ${cmd}"
  }

  ensure_foreman() {
    run_app_as_user 'if ! gem list -i foreman >/dev/null 2>&1; then gem install foreman --no-document && rbenv rehash; fi'
  }

  if [[ -n "$OTS_SSL_VALUE" ]]; then
    case "${OTS_SSL_VALUE,,}" in
    1 | true | yes | on) OTS_SSL_VALUE="true" ;;
    0 | false | no | off) OTS_SSL_VALUE="false" ;;
    *)
      msg_error "Invalid OTS_SSL value '${OTS_SSL_VALUE}' (use true/false)"
      exit 1
      ;;
    esac
  fi

  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d "$APP_DIR" ]] || [[ ! -f "$APP_DIR/.env" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  ensure_dependencies \
    build-essential \
    curl \
    git \
    jq \
    libffi-dev \
    libgmp-dev \
    libreadline-dev \
    libssl-dev \
    libxml2-dev \
    libxslt-dev \
    libyaml-dev \
    locales \
    redis-server \
    zlib1g-dev

  if ! getent group "$APP_GROUP" >/dev/null 2>&1; then
    groupadd --system "$APP_GROUP"
  fi
  if ! id -u "$APP_USER" >/dev/null 2>&1; then
    useradd --system --gid "$APP_GROUP" --home-dir "$APP_ROOT" --create-home --shell /usr/sbin/nologin "$APP_USER"
  fi

  if check_for_gh_release "onetimesecret" "onetimesecret/onetimesecret"; then
    msg_info "Stopping Service"
    systemctl stop onetimesecret-web
    msg_ok "Stopped Service"

    msg_info "Backing up Configuration"
    cp -f "$APP_DIR/.env" /tmp/onetimesecret.env.bak
    [[ -f "$APP_DIR/etc/puma.rb" ]] && cp -f "$APP_DIR/etc/puma.rb" /tmp/onetimesecret.puma.rb.bak
    for f in config.yaml auth.yaml logging.yaml; do
      [[ -f "$APP_DIR/etc/${f}" ]] && cp -f "$APP_DIR/etc/${f}" "/tmp/onetimesecret.${f}.bak"
    done
    msg_ok "Backed up Configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "onetimesecret" "onetimesecret/onetimesecret" "tarball" "${CHECK_UPDATE_RELEASE}" "$APP_DIR"

    msg_info "Restoring Configuration"
    cp -f /tmp/onetimesecret.env.bak "$APP_DIR/.env"
    chmod 600 "$APP_DIR/.env"
    [[ -f /tmp/onetimesecret.puma.rb.bak ]] && cp -f /tmp/onetimesecret.puma.rb.bak "$APP_DIR/etc/puma.rb"
    for f in config.yaml auth.yaml logging.yaml; do
      [[ -f /tmp/onetimesecret.${f}.bak ]] && cp -f "/tmp/onetimesecret.${f}.bak" "$APP_DIR/etc/${f}"
    done
    if [[ -n "$OTS_HOST_VALUE" ]]; then
      sed -i "s|^HOST=.*|HOST=${OTS_HOST_VALUE}|" "$APP_DIR/.env"
    fi
    if [[ -n "$OTS_SSL_VALUE" ]]; then
      sed -i "s|^SSL=.*|SSL=${OTS_SSL_VALUE}|" "$APP_DIR/.env"
    fi
    sed -i 's|bind "tcp://0.0.0.0:#{port}"|bind "tcp://127.0.0.1:#{port}"|' "$APP_DIR/etc/puma.rb"
    chown -R "$APP_USER:$APP_GROUP" "$APP_ROOT"
    rm -f /tmp/onetimesecret.env.bak /tmp/onetimesecret.puma.rb.bak /tmp/onetimesecret.*.bak
    msg_ok "Restored Configuration"

    RUBY_VERSION="$(grep -E "^ruby " "$APP_DIR/Gemfile" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    RUBY_VERSION="${RUBY_VERSION:-3.4.7}"
    RUBY_VERSION="${RUBY_VERSION}" RUBY_INSTALL_RAILS="false" HOME="$APP_ROOT" setup_ruby
    chown -R "$APP_USER:$APP_GROUP" "$APP_ROOT"
    PNPM_VERSION="$(jq -r '.packageManager | split("@")[1]' "$APP_DIR/package.json")"
    NODE_VERSION="25" NODE_MODULE="pnpm@${PNPM_VERSION}" setup_nodejs

    msg_info "Reconciling Application"
    systemctl start redis-server
    if locale -a 2>/dev/null | grep -qi '^en_US\.utf8$'; then
      export LANG="en_US.UTF-8"
    else
      export LANG="C.UTF-8"
    fi
    export LC_ALL="${LANG}"
    install -d -m 0750 -o "$APP_USER" -g "$APP_GROUP" "$APP_DIR/tmp" "$APP_DIR/log"
    $STD ensure_foreman
    $STD run_app_as_user "./install.sh reconcile"
    $STD run_app_as_user "pnpm run build"
    msg_ok "Reconciled Application"

    msg_info "Starting Service"
    systemctl daemon-reload
    systemctl start onetimesecret-web
    systemctl reload nginx 2>/dev/null || systemctl restart nginx
    msg_ok "Started Service"
    msg_ok "Updated ${APP} to ${CHECK_UPDATE_RELEASE} successfully!"
  fi
  exit 0
}

start
build_container
description

DISPLAY_HOST="${OTS_HOST:-$IP}"
case "${OTS_SSL:-false,,}" in
1 | true | yes | on)
  DISPLAY_SSL="true"
  DISPLAY_SCHEME="https"
  ;;
*)
  DISPLAY_SSL="false"
  DISPLAY_SCHEME="http"
  ;;
esac

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${DISPLAY_SCHEME}://${DISPLAY_HOST}${CL}"
if [[ "${DISPLAY_HOST}" != "${IP}" ]]; then
  echo -e "${TAB}${INFO}${YW} Container IP:${CL} ${BGN}http://${IP}${CL}"
fi
echo -e "${INFO}${YW} Configure SMTP in ${CL}${TAB}/var/lib/onetimesecret/app/.env${CL}${YW} for email verification.${CL}"
echo -e "${INFO}${YW} Back up ${CL}${TAB}/var/lib/onetimesecret/app/.env${CL}${YW} and ${CL}${TAB}/var/lib/onetimesecret${CL}${YW} before internet exposure.${CL}"
echo -e "${INFO}${YW} Put this behind TLS/reverse proxy before exposing it publicly.${CL}"
echo -e "${INFO}${YW} Effective app settings:${CL} ${TAB}${BGN}HOST=${DISPLAY_HOST} SSL=${DISPLAY_SSL}${CL}"
echo -e "${INFO}${YW} Reuse these install/update flags if needed:${CL} ${TAB}${BGN}OTS_HOST=${DISPLAY_HOST} OTS_SSL=${DISPLAY_SSL}${CL}"
