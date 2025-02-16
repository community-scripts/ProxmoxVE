#!/usr/bin/env bash
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

color() {
  return
}
catch_errors() {
  set -Eeuo pipefail
  trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
}

error_handler() {
    local exit_code="$?"
  local line_number="$1"
  local command="$2"
  local error_message="Failure in line $line_number: exit code $exit_code: while executing command $command"
  echo -e "\n$error_message"
  exit 100
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
  local CONTENT_LABEL
  case $CLASS in
  container)
    CONTENT='rootdir'
    CONTENT_LABEL='Container'
    ;;
  template)
    CONTENT='vztmpl'
    CONTENT_LABEL='Container template'
    ;;
  *) false || { msg_error "Invalid storage class."; exit 201; };;
  esac
  
  # This Queries all storage locations
  local -a MENU
  while read -r line; do
    local TAG=$(echo $line | awk '{print $1}')
    local TYPE=$(echo $line | awk '{printf "%-10s", $2}')
    local FREE=$(echo $line | numfmt --field 4-6 --from-unit=K --to=iec --format %.2f | awk '{printf( "%9sB", $6)}')
    local ITEM="Type: $TYPE Free: $FREE "
    local OFFSET=2
    if [[ $((${#ITEM} + $OFFSET)) -gt ${MSG_MAX_LENGTH:-} ]]; then
      local MSG_MAX_LENGTH=$((${#ITEM} + $OFFSET))
    fi
    MENU+=("$TAG" "$ITEM" "OFF")
  done < <(pvesm status -content $CONTENT | awk 'NR>1')
  
  # Select storage location
  if [ $((${#MENU[@]}/3)) -eq 1 ]; then
    printf ${MENU[0]}
  else
   msg_error "STORAGE ISSUES!"
    exit 202  
  fi
}



[[ "${CTID:-}" ]] || { msg_error "You need to set 'CTID' variable."; exit 203; }
[[ "${PCT_OSTYPE:-}" ]] || { msg_error "You need to set 'PCT_OSTYPE' variable."; exit 204; }

[ "$CTID" -ge "100" ] || { msg_error "ID cannot be less than 100."; exit 205; }

if pct status $CTID &>/dev/null; then
  echo -e "ID '$CTID' is already in use."
  unset CTID
  msg_error "Cannot use ID that is already in use."
  exit 206
fi

TEMPLATE_STORAGE=$(select_storage template) || exit

CONTAINER_STORAGE=$(select_storage container) || exit

pveam update >/dev/null


TEMPLATE_SEARCH=${PCT_OSTYPE}-${PCT_OSVERSION:-}
mapfile -t TEMPLATES < <(pveam available -section system | sed -n "s/.*\($TEMPLATE_SEARCH.*\)/\1/p" | sort -t - -k 2 -V)
[ ${#TEMPLATES[@]} -gt 0 ] || { msg_error "Unable to find a template when searching for '$TEMPLATE_SEARCH'."; exit 207; }
TEMPLATE="${TEMPLATES[-1]}"

TEMPLATE_PATH="/var/lib/vz/template/cache/$TEMPLATE"

if ! pveam list "$TEMPLATE_STORAGE" | grep -q "$TEMPLATE"; then
  [[ -f "$TEMPLATE_PATH" ]] && rm -f "$TEMPLATE_PATH"
  pveam download "$TEMPLATE_STORAGE" "$TEMPLATE" >/dev/null ||
    { msg_error "A problem occurred while downloading the LXC template."; exit 208; }
fi


grep -q "root:100000:65536" /etc/subuid || echo "root:100000:65536" >> /etc/subuid
grep -q "root:100000:65536" /etc/subgid || echo "root:100000:65536" >> /etc/subgid

PCT_OPTIONS=(${PCT_OPTIONS[@]:-${DEFAULT_PCT_OPTIONS[@]}})
[[ " ${PCT_OPTIONS[@]} " =~ " -rootfs " ]] || PCT_OPTIONS+=(-rootfs "$CONTAINER_STORAGE:${PCT_DISK_SIZE:-8}")


  if ! pct create "$CTID" "${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE}" "${PCT_OPTIONS[@]}" &>/dev/null; then
      [[ -f "$TEMPLATE_PATH" ]] && rm -f "$TEMPLATE_PATH"
      

    pveam download "$TEMPLATE_STORAGE" "$TEMPLATE" >/dev/null ||    
      { msg_error "A problem occurred while re-downloading the LXC template."; exit 208; }
    

    if ! pct create "$CTID" "${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE}" "${PCT_OPTIONS[@]}" &>/dev/null; then
        msg_error "A problem occurred while trying to create container after re-downloading template."
      exit 200
    fi
  fi

