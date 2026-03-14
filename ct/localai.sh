#!/usr/bin/env bash
# Source: https://github.com/mudler/LocalAI

APP="localai"
var_tags="${var_tags:-ai;llm;inference;openai-compatible}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_gpu="${var_gpu:-yes}"

get_app_version() {
  # Get the latest release version from GitHub
  local version
  version=$(curl -s https://api.github.com/repos/mudler/LocalAI/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
  echo "$version"
}

update_script() {
  LXC=1
  APP="localai"
  GH_REPO="mudler/LocalAI"
  GH_RELEASE="latest"
  BINARY="local-ai"
  
  # Get current version
  CURRENT_VERSION=$(local-ai --version 2>/dev/null | head -n1 | awk '{print $NF}' | sed 's/v//')
  
  # Check for new version
  if check_for_gh_release "$GH_REPO" "$GH_RELEASE" "$CURRENT_VERSION"; then
    msg_info "Updating $APP to latest version"
    
    # Stop service before update
    systemctl stop localai
    
    # Download and deploy new binary
    fetch_and_deploy_gh_release "$GH_REPO" "prebuild" "$BINARY"
    
    # Start service
    systemctl start localai
    
    msg_ok "Updated $APP to latest version"
  else
    msg_ok "$APP is already up to date"
  fi
}
