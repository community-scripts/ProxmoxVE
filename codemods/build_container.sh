build_container() {
  #  if [ "$VERB" == "yes" ]; then set -x; fi

  if [ "$CT_TYPE" == "1" ]; then
    FEATURES="keyctl=1,nesting=1"
  else
    FEATURES="nesting=1"
  fi


  TEMP_DIR=$(mktemp -d)
  pushd $TEMP_DIR >/dev/null
  if [ "$var_os" == "alpine" ]; then
    curl -s https://raw.githubusercontent.com/bketelsen/IncusScripts/main/misc/alpine-install.func -o install.func
  else
    curl -s https://raw.githubusercontent.com/bketelsen/IncusScripts/main/misc/install.func -o install.func
  fi
  # if [ "$var_os" == "alpine" ]; then
  #   export FUNCTIONS_FILE_PATH="$(curl -s https://raw.githubusercontent.com/bketelsen/IncusScripts/main/misc/alpine-install.func)"
  # else
  #   export FUNCTIONS_FILE_PATH="$(curl -s https://raw.githubusercontent.com/bketelsen/IncusScripts/main/misc/install.func)"
  # fi
  echo export CACHER="$APT_CACHER" >>install.func
  echo export CACHER_IP="$APT_CACHER_IP" >>install.func
  echo export tz="$timezone" >>install.func
  echo export DISABLEIPV6="$DISABLEIP6" >>install.func
  echo export APPLICATION="$APP" >>install.func
  echo export app="$NSAPP" >>install.func
  echo export PASSWORD="$PW" >>install.func
  echo export VERBOSE="$VERB" >>install.func
  echo export SSH_ROOT="${SSH}" >>install.func
  echo export SSH_AUTHORIZED_KEY "${SSH_AUTHORIZED_KEY}" >>install.func
  echo export CTID="$CT_ID" >>install.func
  echo export CTTYPE="$CT_TYPE" >>install.func
  echo export PCT_OSTYPE="$var_os"  >>install.func
  echo export PCT_OSVERSION="$var_version" >>install.func
  echo export PCT_DISK_SIZE="$DISK_SIZE"  >>install.func
  # echo export PCT_OPTIONS="
  #   -features $FEATURES
  #   -hostname $HN
  #   -tags $TAGS
  #   $SD
  #   $NS
  #   -net0 name=eth0,bridge=$BRG$MAC,ip=$NET$GATE$VLAN$MTU
  #   -onboot 1
  #   -cores $CORE_COUNT
  #   -memory $RAM_SIZE
  #   -unprivileged $CT_TYPE
  #   $PW
  # " >>install.func
  # This executes create_lxc.sh and creates the container and .conf file
  source ./install.func
  bash -c "$(wget -qLO - https://raw.githubusercontent.com/bketelsen/IncusScripts/main/ct/create_lxc.sh)" || exit

#   LXC_CONFIG=/etc/pve/lxc/${CTID}.conf
#   if [ "$CT_TYPE" == "0" ]; then
#     cat <<EOF >>$LXC_CONFIG
# # USB passthrough
# lxc.cgroup2.devices.allow: a
# lxc.cap.drop:
# lxc.cgroup2.devices.allow: c 188:* rwm
# lxc.cgroup2.devices.allow: c 189:* rwm
# lxc.mount.entry: /dev/serial/by-id  dev/serial/by-id  none bind,optional,create=dir
# lxc.mount.entry: /dev/ttyUSB0       dev/ttyUSB0       none bind,optional,create=file
# lxc.mount.entry: /dev/ttyUSB1       dev/ttyUSB1       none bind,optional,create=file
# lxc.mount.entry: /dev/ttyACM0       dev/ttyACM0       none bind,optional,create=file
# lxc.mount.entry: /dev/ttyACM1       dev/ttyACM1       none bind,optional,create=file
# EOF
#   fi

#   if [ "$CT_TYPE" == "0" ]; then
#     if [[ "$APP" == "Channels" || "$APP" == "Emby" || "$APP" == "ErsatzTV" || "$APP" == "Frigate" || "$APP" == "Jellyfin" || "$APP" == "Plex" || "$APP" == "Scrypted" || "$APP" == "Tdarr" || "$APP" == "Unmanic" || "$APP" == "Ollama" ]]; then
#       cat <<EOF >>$LXC_CONFIG
# # VAAPI hardware transcoding
# lxc.cgroup2.devices.allow: c 226:0 rwm
# lxc.cgroup2.devices.allow: c 226:128 rwm
# lxc.cgroup2.devices.allow: c 29:0 rwm
# lxc.mount.entry: /dev/fb0 dev/fb0 none bind,optional,create=file
# lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
# lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file
# EOF
#     fi
#   else
#     if [[ "$APP" == "Channels" || "$APP" == "Emby" || "$APP" == "ErsatzTV" || "$APP" == "Frigate" || "$APP" == "Jellyfin" || "$APP" == "Plex" || "$APP" == "Scrypted" || "$APP" == "Tdarr" || "$APP" == "Unmanic" || "$APP" == "Ollama" ]]; then
#       if [[ -e "/dev/dri/renderD128" ]]; then
#         if [[ -e "/dev/dri/card0" ]]; then
#           cat <<EOF >>$LXC_CONFIG
# # VAAPI hardware transcoding
# dev0: /dev/dri/card0,gid=44
# dev1: /dev/dri/renderD128,gid=104
# EOF
#         else
#           cat <<EOF >>$LXC_CONFIG
# # VAAPI hardware transcoding
# dev0: /dev/dri/card1,gid=44
# dev1: /dev/dri/renderD128,gid=104
# EOF
#         fi
#       fi
#     fi
#   fi

  incus file push --mode 0777 install.func "$app"/root/install.func
  # This starts the container and executes <app>-install.sh
  msg_info "Starting Incus Container"
  incus start "$app"
  msg_ok "Started Incus Container"
  if [ "$var_os" == "alpine" ]; then
    sleep 3
    incus exec "$app" -- /bin/sh -c 'cat <<EOF >/etc/apk/repositories
http://dl-cdn.alpinelinux.org/alpine/latest-stable/main
http://dl-cdn.alpinelinux.org/alpine/latest-stable/community
EOF'
    incus exec "$app" --env=FUNCTIONS_FILE_PATH=/root/install.func  -- ash -c "apk add bash >/dev/null"
  fi
  incus shell "$app" --env=FUNCTIONS_FILE_PATH=/root/install.func -- bash -c "$(wget -qLO - https://raw.githubusercontent.com/bketelsen/IncusScripts/main/install/$var_install.sh)" || exit

}
