#!/usr/bin/env bash
color() {
  return
}
catch_errors() {
  set -Eeuo pipefail
  trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
}

# This function handles errors
error_handler() {
    local exit_code="$?"
  local line_number="$1"
  local command="$2"
  local error_message="Failure in line $line_number: exit code $exit_code: while executing command $command"
  echo -e "\n$error_message"
  exit "$error_message"
}
verb_ip6() {
    return
}

msg_info() {
  local msg="$1"
  echo -ne "${msg}\n"
}

msg_ok() { 
  local msg="$1"
  echo -e "${msg}\n"
}

msg_error() {
  
  local msg="$1"
  echo -e "${msg}\n"
}


VALIDCT=$(pvesm status -content rootdir | awk 'NR>1')
if [ -z "$VALIDCT" ]; then
  msg_error "Unable to detect a valid Container Storage location."
  exit 1
fi
VALIDTMP=$(pvesm status -content vztmpl | awk 'NR>1')
if [ -z "$VALIDTMP" ]; then
  msg_error "Unable to detect a valid Template Storage location."
  exit 1
fi

function select_storage() {
  local CLASS=$1
  local CONTENT
  
  case $CLASS in
    container) CONTENT='rootdir' ;;
    template) CONTENT='vztmpl' ;;
    *) msg_error "Invalid storage class." && exit 201 ;;
  esac

  # Get the first available storage tag
  local STORAGE=$(pvesm status -content $CONTENT | awk 'NR==2 {print $1}')

  if [[ -z "$STORAGE" ]]; then
    msg_error "No available storage found for $CLASS."
    exit 202
  fi
}




[[ "${CTID:-}" ]] || { msg_error "You need to set 'CTID' variable."; exit 203; }
[[ "${PCT_OSTYPE:-}" ]] || { msg_error "You need to set 'PCT_OSTYPE' variable."; exit 204; }

# Test if ID is valid
[ "$CTID" -ge "100" ] || { msg_error "ID cannot be less than 100."; exit 205; }

# Test if ID is in use
if pct status $CTID &>/dev/null; then
  echo -e "ID '$CTID' is already in use."
  unset CTID
  msg_error "Cannot use ID that is already in use."
  exit 206
fi

# Get template storage
TEMPLATE_STORAGE=$(select_storage template) || exit
msg_ok "Using  $TEMPLATE_STORAGE   for Template Storage."

# Get container storage
CONTAINER_STORAGE=$(select_storage container) || exit
msg_ok "Using  $CONTAINER_STORAGE   for Container Storage."

# Update LXC template list
msg_info "Updating LXC Template List"
pveam update >/dev/null
msg_ok "Updated LXC Template List"

# Get LXC template string
TEMPLATE_SEARCH=${PCT_OSTYPE}-${PCT_OSVERSION:-}
mapfile -t TEMPLATES < <(pveam available -section system | sed -n "s/.*\($TEMPLATE_SEARCH.*\)/\1/p" | sort -t - -k 2 -V)
[ ${#TEMPLATES[@]} -gt 0 ] || { msg_error "Unable to find a template when searching for '$TEMPLATE_SEARCH'."; exit 207; }
TEMPLATE="${TEMPLATES[-1]}"

TEMPLATE_PATH="/var/lib/vz/template/cache/$TEMPLATE"
# Check if template exists, if corrupt remove and redownload
if ! pveam list "$TEMPLATE_STORAGE" | grep -q "$TEMPLATE"; then
  [[ -f "$TEMPLATE_PATH" ]] && rm -f "$TEMPLATE_PATH"
  msg_info "Downloading LXC Template"
  pveam download "$TEMPLATE_STORAGE" "$TEMPLATE" >/dev/null ||
    { msg_error "A problem occurred while downloading the LXC template."; exit 208; }
  msg_ok "Downloaded LXC Template"
fi

# Check and fix subuid/subgid
grep -q "root:100000:65536" /etc/subuid || echo "root:100000:65536" >> /etc/subuid
grep -q "root:100000:65536" /etc/subgid || echo "root:100000:65536" >> /etc/subgid

# Combine all options
PCT_OPTIONS=(${PCT_OPTIONS[@]:-${DEFAULT_PCT_OPTIONS[@]}})
[[ " ${PCT_OPTIONS[@]} " =~ " -rootfs " ]] || PCT_OPTIONS+=(-rootfs "$CONTAINER_STORAGE:${PCT_DISK_SIZE:-8}")

# Create container with template integrity check
msg_info "Creating LXC Container"
  if ! pct create "$CTID" "${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE}" "${PCT_OPTIONS[@]}" &>/dev/null; then
      [[ -f "$TEMPLATE_PATH" ]] && rm -f "$TEMPLATE_PATH"
      
    msg_ok "Template integrity check completed"
    pveam download "$TEMPLATE_STORAGE" "$TEMPLATE" >/dev/null ||    
      { msg_error "A problem occurred while re-downloading the LXC template."; exit 208; }
    
    msg_ok "Re-downloaded LXC Template"
    if ! pct create "$CTID" "${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE}" "${PCT_OPTIONS[@]}" &>/dev/null; then
        msg_error "A problem occurred while trying to create container after re-downloading template."
      exit 200
    fi
  fi
msg_ok "LXC Container  $CTID   was successfully created."
