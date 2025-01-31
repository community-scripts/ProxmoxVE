#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-Author: MickLesk
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

# This sets verbose mode if the global variable is set to "yes"
# if [ "$VERBOSE" == "yes" ]; then set -x; fi

# This function sets color variables for formatting output in the terminal
# Colors
YW=$(echo "\033[33m")
YWB=$(echo "\033[93m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
GN=$(echo "\033[1;92m")

# Formatting
CL=$(echo "\033[m")
UL=$(echo "\033[4m")
BOLD=$(echo "\033[1m")
BFR="\\r\\033[K"
HOLD=" "
TAB="  "

# Icons
CM="${TAB}✔️${TAB}${CL}"
CROSS="${TAB}✖️${TAB}${CL}"
INFO="${TAB}💡${TAB}${CL}"

# This sets error handling options and defines the error_handler function to handle errors
set -Eeuo pipefail
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR

# This function handles errors
function error_handler() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  printf "\e[?25h"
  local exit_code="$?"
  local line_number="$1"
  local command="$2"
  local error_message="${RD}[ERROR]${CL} in line ${RD}$line_number${CL}: exit code ${RD}$exit_code${CL}: while executing command ${YW}$command${CL}"
  echo -e "\n$error_message\n"
}

# This function displays a spinner.
function spinner() {
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local spin_i=0
  local interval=0.1
  printf "\e[?25l"

  local color="${YWB}"

  while true; do
    printf "\r ${color}%s${CL}" "${frames[spin_i]}"
    spin_i=$(( (spin_i + 1) % ${#frames[@]} ))
    sleep "$interval"
  done
}

# This function displays an informational message with a yellow color.
function msg_info() {
  local msg="$1"
  echo -ne "${TAB}${YW}${HOLD}${msg}${HOLD}"
  spinner &
  SPINNER_PID=$!
}

# This function displays a success message with a green color.
function msg_ok() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  printf "\e[?25h"
  local msg="$1"
  echo -e "${BFR}${CM}${GN}${msg}${CL}"
}

# This function displays a error message with a red color.
function msg_error() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  printf "\e[?25h"
  local msg="$1"
  echo -e "${BFR}${CROSS}${RD}${msg}${CL}"
}

# export CACHER=
# export CACHER_IP=
# export tz=Etc/UTC
# export DISABLEIPV6=no
# export APPLICATION=Docker
# export app=docker
# export BRG=br0
# export PASSWORD=
# export VERBOSE=yes
# export SSH_ROOT=no
# export SSH_AUTHORIZED_KEY=
# export CTID=100
# export CTTYPE=1
# export PCT_OSTYPE=debian
# export PCT_OSVERSION=12
# export PCT_DISK_SIZE=4
  # echo export HN="$HN" >>install.func // hostname
  # echo export CORE_COUNT="$CORE_COUNT" >>install.func // cores
  # echo export RAM_SIZE="$RAM_SIZE" >>install.func // memory

IMAGE_NAME="images:${PCT_OSTYPE}/${PCT_OSVERSION:-}"
netflag="${BRG}"

# Create container
msg_info "Creating Incus Container"
incus create "${IMAGE_NAME}" "$app" --network "$netflag" >/dev/null
incus config set "$app" limits.cpu="$CORE_COUNT" #>/dev/null
incus config set "$app" limits.memory="$RAM_SIZE"MiB #>/dev/null
msg_ok "Incus Container ${BL}${app}${CL} ${GN}was successfully created."
