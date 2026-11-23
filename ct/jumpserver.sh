#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Nícolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.jumpserver.org/ | Github: https://github.com/jumpserver/jumpserver

APP="JumpServer"
var_tags="${var_tags:-bastion-host;pam}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-50}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; every component builds from source with arm64-capable toolchains, but the stack has only been run on amd64

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/jumpserver ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_tag "guacd" "apache/guacamole-server"; then
    msg_info "Stopping guacd"
    systemctl stop guacd
    msg_ok "Stopped guacd"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_tag "guacd" "apache/guacamole-server"

    msg_info "Building guacd"
    cd /opt/guacd
    $STD autoreconf -fi
    # FreeRDP 3.6+ deprecates APIs guacd still calls, which -Werror turns into build failures
    $STD ./configure --with-systemd-dir=/etc/systemd/system --disable-guacenc CFLAGS="-O2 -Wno-error=deprecated-declarations"
    $STD make -j"$(nproc)"
    $STD make install
    $STD ldconfig
    systemctl daemon-reload
    systemctl start guacd
    msg_ok "Built guacd"
  fi

  if check_for_gh_release "jumpserver" "jumpserver/jumpserver" "" "" "v5."; then
    msg_info "Stopping Services"
    systemctl stop jumpserver koko
    msg_ok "Stopped Services"

    create_backup /opt/jumpserver/config.yml /opt/jumpserver/data /opt/koko/config.yml /opt/koko/data

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "jumpserver" "jumpserver/jumpserver" "tarball" "latest" "" "" "v5."
    JMS_TAG="v$(<~/.jumpserver)"
    github_api_call "https://api.github.com/repos/jumpserver/jumpserver/contents/apps/accounts/clients?ref=${JMS_TAG}" /tmp/jms-clients.json
    fetch_and_deploy_from_url "https://github.com/jumpserver/pam-clients/archive/$(jq -r .sha /tmp/jms-clients.json).tar.gz" /opt/jumpserver/apps/accounts/clients
    rm -f /tmp/jms-clients.json
    CLEAN_INSTALL=1 fetch_and_deploy_gh_tag "koko" "jumpserver/koko" "$JMS_TAG"

    restore_backup

    msg_info "Updating Python Environment"
    cd /opt/jumpserver
    $STD bash requirements/static_files.sh
    $STD uv venv --python 3.14
    $STD uv pip install -r pyproject.toml
    JMS_GALAXY_RETRIES=3
    until ANSIBLE_COLLECTIONS_PATHS="/opt/jumpserver/.venv/lib/python3.14/site-packages/ansible_collections" $STD .venv/bin/ansible-galaxy collection install -r requirements/collections.yml --force --ignore-certs; do
      JMS_GALAXY_RETRIES=$((JMS_GALAXY_RETRIES - 1))
      if ((JMS_GALAXY_RETRIES <= 0)); then
        msg_error "ansible-galaxy collection install failed after 3 attempts (Ansible Galaxy may be unreachable)"
        exit 1
      fi
      sleep 15
    done
    cd /opt/jumpserver/apps
    $STD ../.venv/bin/python3 manage.py compilemessages
    msg_ok "Updated Python Environment"

    GHOSTTY_COMMIT=$(grep -oP 'libghostty-vt:ghostty-\K[0-9a-f]+' /opt/koko/Dockerfile-base)
    ZIG_VERSION=$(grep -oP 'libghostty-vt:ghostty-[0-9a-f]+-zig-\K[0-9.]+' /opt/koko/Dockerfile-base)
    USQL_VERSION=$(grep -oP 'ARG USQL_VERSION=\K\S+' /opt/koko/Dockerfile-base)
    K8S_BUNDLE_VERSION=$(grep -oP 'ARG K8S_BUNDLE_VERSION=\K\S+' /opt/koko/Dockerfile-base)
    GO_VERSION=$(grep -oP '^go \K\S+' /opt/koko/go.mod) setup_go

    if [[ "$(cat ~/.libghostty-vt 2>/dev/null)" != "$GHOSTTY_COMMIT" ]]; then
      fetch_and_deploy_from_url "https://ziglang.org/download/${ZIG_VERSION}/zig-$(arch_resolve x86_64 aarch64)-linux-${ZIG_VERSION}.tar.xz" "/opt/zig"
      fetch_and_deploy_from_url "https://github.com/ghostty-org/ghostty/archive/${GHOSTTY_COMMIT}.tar.gz" "/opt/ghostty"

      msg_info "Building libghostty-vt"
      rm -rf /opt/libghostty-vt
      cd /opt/ghostty
      $STD /opt/zig/zig build -Demit-lib-vt -Doptimize=ReleaseFast -Dcpu=baseline --prefix /opt/libghostty-vt
      rm -rf /opt/ghostty /opt/zig ~/.cache/zig
      echo "$GHOSTTY_COMMIT" >~/.libghostty-vt
      msg_ok "Built libghostty-vt"
    fi

    msg_info "Building KoKo"
    cd /opt/koko
    export PKG_CONFIG_PATH=/opt/libghostty-vt/share/pkgconfig
    $STD make build VERSION="$JMS_TAG"
    mv build/koko koko
    rm -rf build
    msg_ok "Built KoKo"

    fetch_and_deploy_gh_release "usql" "jumpserver-dev/usql" "prebuild" "$USQL_VERSION" "/opt/usql" "usql-*-linux-$(arch_resolve amd64 arm64).tar.gz"
    fetch_and_deploy_gh_release "k8s-bundle" "jumpserver-dev/k8s-bundle" "binary" "$K8S_BUNDLE_VERSION" "" "k8s-bundle_$(arch_resolve amd64 arm64).deb"

    NODE_VERSION="24" NODE_MODULE="corepack" setup_nodejs

    # Lina and Luna sources are deleted after each build, so their version
    # markers must not let the fetch be skipped
    rm -f ~/.lina ~/.luna

    CLEAN_INSTALL=1 fetch_and_deploy_gh_tag "lina" "jumpserver/lina" "$JMS_TAG" "/opt/lina-src"

    msg_info "Building Lina"
    cd /opt/lina-src
    $STD yarn install --immutable
    $STD yarn build:prod
    rm -rf /opt/lina
    mv lina /opt/lina
    rm -rf /opt/lina-src
    msg_ok "Built Lina"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_tag "luna" "jumpserver/luna" "$JMS_TAG" "/opt/luna-src"

    msg_info "Building Luna"
    cd /opt/luna-src
    # NUXT_TELEMETRY_DISABLED stops nuxt generate from waiting on a consent prompt
    export ELECTRON_SKIP_BINARY_DOWNLOAD=1 PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 HUSKY=0 NUXT_TELEMETRY_DISABLED=1
    $STD pnpm --filter jumpserver-web... install --frozen-lockfile --config.node-linker=isolated
    $STD pnpm --config.node-linker=isolated --filter jumpserver-web web:generate
    rm -rf /opt/luna
    mv .output/public /opt/luna
    rm -rf /opt/luna-src
    msg_ok "Built Luna"

    msg_info "Starting Services"
    systemctl start jumpserver koko
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW}SSH bastion (character protocols): ${CL}${BGN}ssh -p 2222 <user>@${IP}${CL}"
echo -e "${INFO}${YW}Login credentials: ~/jumpserver.creds (inside the container)${CL}"
