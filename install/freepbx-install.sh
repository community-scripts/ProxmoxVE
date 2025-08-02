#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Arian Nasr (arian-nasr)
# Updated by: Javier Pastor (vsc55)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.freepbx.org/

INSTALL_URL="https://github.com/FreePBX/sng_freepbx_debian_install/raw/master/sng_freepbx_debian_install.sh"
INSTALL_PATH="/opt/sng_freepbx_debian_install.sh"

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Run commands with optional verbose output
# This function runs commands and handles both normal and verbose modes.
# Usage: run_bin <command> [<args>...]
# If VERBOSE is set to "yes", it will print the command being run and its output.
# If VERBOSE is set to "no", it will run the command silently.
# Returns the exit code of the command.
# Example: run_bin ls -l /path/to/directory
run_bin() {
  local code=0

  if [[ "$VERBOSE" == "yes" ]]; then
    print_msg ok "Running command [$*]...\n"
    "$@"
    code=$?
    if [[ $code -ne 0 ]]; then
      print_msg error "Command failed [$*] with exit code $code\n"
    fi
  else
    $STD "$@"
    code=$?
  fi
  return $code
}

# Print messages with different types
# This function handles both normal and verbose modes.
# Usage: print_msg <type> <normal_text> [<verbose_text>]
# type: info, ok, warn, error
# txt_normal: text to print in normal mode
# txt_verbose: text to print in verbose mode (optional)
# Example: print_msg info "This is an info message" "This is a verbose info message"
print_msg() {
  local type="$1"
  local txt_normal="${2:-}"
  local txt_verbose="${3:-}"

  local func="msg_$type"

  if [[ "$VERBOSE" == "yes" ]]; then
    if [[ -n "$txt_verbose" ]]; then
      $func "$txt_verbose"
    else
      $func "$txt_normal\n"
    fi
  else
    $func "$txt_normal"
  fi
}

# Check if there are any commercial modules installed
has_commercial_modules() {
  fwconsole ma list | awk '/Commercial/ {found=1} END {exit !found}'
}

# Uninstall commercial modules
uninstall_modules_commercial() {
  
  print_msg info "Removing Commercial modules..."
  
  local max=5
  local count=0

  while has_commercial_modules; do
    ! has_commercial_modules && break

    count=$((count + 1))
    print_msg info "Attempt $count to remove commercial modules..."

    while read -r module; do
      local code=0

      print_msg info "Removing module: $module"

      run_bin fwconsole ma -f remove $module || code=$?
      
      if [[ $code -ne 0 ]]; then
        print_msg error "Module $module could not be removed - error code $code"
      else
        print_msg ok "Module $module removed successfully"
      fi

    done < <(fwconsole ma list | awk '/Commercial/ {print $2}')

    # Check if there are still commercial modules left
    ! has_commercial_modules && break

    # Timeout to avoid infinite loop
    if [[ $count -ge $max ]]; then
      print_msg warn "Failed to remove all commercial modules after $max attempts, remove them manually in the web interface."
      break
    else
      print_msg ok "Removed commercial modules, retrying (attempt $count/$max)..."
    fi
  done

  print_msg ok "Removed all commercial modules successfully"
}

print_msg info "Downloading FreePBX installation script..."
if curl -fsSL "$INSTALL_URL" -o "$INSTALL_PATH"; then
  print_msg ok "Download completed successfully"
else
  curl_exit_code=$?
  print_msg error "Error downloading FreePBX installation script (curl exit code: $curl_exit_code)"
  print_msg error "Aborting!"
  exit 1
fi

install_args=""
ONLY_OPENSOURCE="${ONLY_OPENSOURCE:-no}"
print_msg ok "Remove Commercial modules is set to: $ONLY_OPENSOURCE"

print_msg info "Installing FreePBX, be patient, this takes time..." "Installing FreePBX (Verbose)\n"
run_bin bash "$INSTALL_PATH" $install_args

if [[ $ONLY_OPENSOURCE == "yes" ]]; then
  uninstall_modules_commercial

  print_msg info "Reloading FreePBX..."
  run_bin fwconsole reload
  print_msg ok "FreePBX reloaded completely"
fi
print_msg ok "Installed FreePBX finished"

motd_ssh
customize

print_msg info "Cleaning up installation files..."
rm -f "$INSTALL_PATH"
run_bin apt-get -y autoremove
run_bin apt-get -y autoclean
print_msg ok "Cleanup completed"
