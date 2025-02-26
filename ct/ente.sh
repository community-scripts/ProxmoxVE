#!/usr/bin/env bash

# ----------------------------------------------------------------------------------
#  Script:  ente.sh
#  Description:  Installs Docker (optionally Portainer) in an LXC, and then 
#                optionally installs Ente server (and web client).
#
#  Copyright (c) 2021-2025 community-scripts ORG
#  Author: Jstaud
#  License: MIT
#  https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
#  Source: ente.io
# ----------------------------------------------------------------------------------

###################################################################################
# (Optional) Source TTeck's helper functions, if available.
# If you're adapting it outside TTeck's environment, remove or comment these lines.
###################################################################################
if [ -n "$FUNCTIONS_FILE_PATH" ] && [ -f "$FUNCTIONS_FILE_PATH" ]; then
  source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
else
  echo "NOTE: FUNCTIONS_FILE_PATH not found. Continuing without TTeck's helper functions..."
  # Provide minimal fallback for msg_info, msg_ok, etc., if desired:
  msg_info() {
    echo -e "\e[94mINFO:\e[0m $*"
  }
  msg_ok() {
    echo -e "\e[92mOK:\e[0m   $*"
  }
  msg_error() {
    echo -e "\e[91mERROR:\e[0m$*"
  }
fi

###################################################################################
# Helper function placeholders if TTeck's environment not present.
# Remove or adapt these if using outside of TTeck's scripts.
###################################################################################
color() { :; }
verb_ip6() { :; }
catch_errors() { :; }
setting_up_container() { :; }
network_check() { :; }
update_os() {
  apt-get update
  apt-get upgrade -y
}
motd_ssh() { :; }
customize() { :; }

###################################################################################
# Script Body
###################################################################################

color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
apt-get install -y curl sudo mc
msg_ok "Installed Dependencies"

###################################################################################
# Optional: Retrieve Latest Releases
# (If we are going to use them or show them, otherwise we can skip.)
###################################################################################
get_latest_release() {
  curl -sL "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | cut -d'"' -f4
}

DOCKER_LATEST_VERSION=$(get_latest_release "moby/moby")
PORTAINER_LATEST_VERSION=$(get_latest_release "portainer/portainer")
PORTAINER_AGENT_LATEST_VERSION=$(get_latest_release "portainer/agent")

###################################################################################
# Install Docker
###################################################################################
msg_info "Installing Docker $DOCKER_LATEST_VERSION"
DOCKER_CONFIG_PATH='/etc/docker/daemon.json'
mkdir -p "$(dirname "$DOCKER_CONFIG_PATH")"
cat <<EOF > "$DOCKER_CONFIG_PATH"
{
  "log-driver": "journald"
}
EOF

# Using Docker's official convenience script:
curl -fsSL https://get.docker.com | sh
msg_ok "Installed Docker $DOCKER_LATEST_VERSION"

###################################################################################
# Prompt: Install Portainer or Portainer Agent
###################################################################################
read -r -p "Would you like to add Portainer? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Installing Portainer $PORTAINER_LATEST_VERSION"
  docker volume create portainer_data >/dev/null 2>&1
  docker run -d \
    -p 8000:8000 \
    -p 9443:9443 \
    --name=portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest
  msg_ok "Installed Portainer $PORTAINER_LATEST_VERSION"
else
  read -r -p "Would you like to add the Portainer Agent? <y/N> " prompt
  if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
    msg_info "Installing Portainer Agent $PORTAINER_AGENT_LATEST_VERSION"
    docker run -d \
      -p 9001:9001 \
      --name portainer_agent \
      --restart=always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v /var/lib/docker/volumes:/var/lib/docker/volumes \
      portainer/agent
    msg_ok "Installed Portainer Agent $PORTAINER_AGENT_LATEST_VERSION"
  fi
fi

###################################################################################
# Prompt: Install Ente Server
###################################################################################
read -r -p "Would you like to install Ente Server? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then

  #############################################################################
  # (A) Using Pre-Built Docker Image from GHCR
  # ---------------------------------------------------------------------------
  # This is the simplest approach: just pull and run the official server image.
  # If you prefer building from the source repo, see option (B) below.
  #############################################################################
  read -r -p "Use the pre-built Docker image (recommended)? <Y/n> " image_prompt
  if [[ ${image_prompt,,} =~ ^(n|no)$ ]]; then
    #############################################################################
    # (B) Build from Source via Docker Compose
    #############################################################################
    msg_info "Installing additional dependencies for build (git, nodejs, npm, yarn)"
    apt-get install -y git nodejs npm
    npm install -g yarn
    msg_ok "Installed dependencies for building Ente from source"

    msg_info "Cloning Ente repository"
    git clone https://github.com/ente-io/ente /opt/ente
    cd /opt/ente/server || {
      msg_error "Failed to enter /opt/ente/server directory!"
      exit 1
    }
    msg_ok "Cloned Ente repository"

    # NOTE: If you'd like to run in background, you can do `docker compose up -d --build`.
    # For demonstration, we'll run it in detached mode:
    msg_info "Starting Ente Server using Docker Compose"
    docker compose up -d --build
    msg_ok "Ente Server is running in Docker (listening on port 8080 by default)"

    #############################################################################
    # Prompt: Install/Run Ente Web client
    #############################################################################
    read -r -p "Would you like to run the Ente Web client as well? <y/N> " web_prompt
    if [[ ${web_prompt,,} =~ ^(y|yes)$ ]]; then
      msg_info "Setting up Ente Web client"
      cd /opt/ente/web || {
        msg_error "Failed to enter /opt/ente/web directory!"
        exit 1
      }
      git submodule update --init --recursive

      # Yarn is already installed globally
      yarn install

      # Launch dev server. By default, Ente's local dev server listens on 3000
      # and expects the Ente server at localhost:8080.
      msg_info "Launching Ente Web in background (port 3000)."
      # The environment variable NEXT_PUBLIC_ENTE_ENDPOINT tells the web app where the server is.
      nohup bash -c "NEXT_PUBLIC_ENTE_ENDPOINT=http://localhost:8080 yarn dev" >/opt/ente/web/ente-web.log 2>&1 &
      msg_ok "Ente Web client started in dev mode (http://<IP>:3000)."
    fi

  else
    # (A) Use the Pre-Built Docker Image
    msg_info "Pulling and starting Ente server container from GHCR.io"
    docker pull ghcr.io/ente-io/server:latest
    # For persistent data or custom config, you may want to bind-mount or use a volume.
    # This is a minimal example:
    docker run -d \
      --name=ente-server \
      --restart=always \
      -p 8080:8080 \
      ghcr.io/ente-io/server:latest
    msg_ok "Ente Server container started (listening on port 8080)."
  fi

  msg_info "Ente server setup complete."
  msg_ok "You can now open http://<LXC_IP>:8080 to communicate with Ente."
  echo ""
  echo "If you build or run the web client, it will connect to the server on port 8080."
  echo "For a local dev environment, see https://github.com/ente-io/ente for more details."
fi

###################################################################################
# Finish up
###################################################################################
motd_ssh
customize

msg_info "Cleaning up"
apt-get -y autoremove
apt-get -y autoclean
msg_ok "Cleaned"