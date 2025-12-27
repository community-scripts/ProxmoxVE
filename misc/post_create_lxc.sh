#!/usr/bin/env bash

# Author: remz1337
# License: MIT
# https://github.com/remz1337/ProxmoxVE/raw/remz/LICENSE

# This function sets up the Container OS by generating the locale, setting the timezone, and checking the network connection
default_setup() {
  msg_info "Setting up Container"
  pct exec "$CTID" -- /bin/bash -c "source <(wget -qLO - https://raw.githubusercontent.com/remz1337/ProxmoxVE/remz/misc/install.func) && color && verb_ip6 && catch_errors && setting_up_container && network_check && update_os" || exit
  pct exec $CTID -- /bin/bash -c "apt install -y curl &>/dev/null"
  msg_ok "Set up Container"
}

reboot_lxc(){
  msg_info "Rebooting LXC"
  pct reboot $CTID
  sleep 5
  msg_ok "Rebooted LXC"
}

# This function checks if a given username exists
function user_exists(){
  pct exec $CTID -- /bin/bash -c "id $1 &>/dev/null;"
} # silent, it just sets the exit code

echo -e "${BL}Customizing LXC creation${CL}"

# Test if required variables are set
[[ "${CTID:-}" ]] || exit "You need to set 'CTID' variable."
[[ "${PCT_OSTYPE:-}" ]] || exit "You need to set 'PCT_OSTYPE' variable."
[[ "${PCT_OSVERSION:-}" ]] || exit "You need to set 'PCT_OSVERSION' variable."
[[ "${app:-}" ]] || exit "You need to set 'app' variable."
[[ "${SHARED_MOUNT:-}" ]] || exit "You need to set 'SHARED_MOUNT' variable."
[[ "${POSTFIX_SAT:-}" ]] || exit "You need to set 'POSTFIX_SAT' variable."
[[ "${NVIDIA_PASSTHROUGH:-}" ]] || exit "You need to set 'NVIDIA_PASSTHROUGH' variable."


#Call default setup to have local, timezone and update APT
sleep 2
reboot_lxc
default_setup

#Adding /usr/local/bin to PATH on Debian >=12
if [ "$PCT_OSTYPE" == "debian" ] && [ "$PCT_OSVERSION" -ge "12" ]; then
  pct exec $CTID -- /bin/bash -c 'cd ~ && echo "export PATH=$PATH:/usr/local/bin" >> ~/.bashrc'
  pct exec $CTID -- /bin/bash -c 'source ~/.bashrc'
fi

#Install APT proxy client
msg_info "Installing APT proxy client"
if [ "$PCT_OSTYPE" == "debian" ] && [ "$PCT_OSVERSION" -ge "12" ]; then
  #Squid-deb-proxy-client is not available on Deb12, not sure if it's an issue with using PVE7
  #auto-apt-proxy needs a DNS record "apt-proxy" pointing to AptCacherNg machine IP (I did it using PiHole)
  pct exec $CTID -- /bin/bash -c "apt install -qqy auto-apt-proxy &>/dev/null"
else
  pct exec $CTID -- /bin/bash -c "apt install -qqy squid-deb-proxy-client &>/dev/null"
fi
msg_ok "Installed APT proxy client"

#Install sudo if Debian
if [ "$PCT_OSTYPE" == "debian" ]; then
  msg_info "Installing sudo"
  pct exec $CTID -- /bin/bash -c "apt install -yqq sudo &>/dev/null"
  msg_ok "Installed sudo"
fi

if [[ "${SHARED_MOUNT}" == "yes" ]]; then
  [[ "${SHARED_MOUNT_LOC:-}" ]] || exit "You need to set 'SHARED_MOUNT_LOC' variable."
  [[ "${SHARED_MOUNT_USER:-}" ]] || exit "You need to set 'SHARED_MOUNT_USER' variable."
  msg_info "Mounting shared directory"
  #Add user $SHARED_MOUNT_USER
  if user_exists "$SHARED_MOUNT_USER"; then
    msg_error 'User $SHARED_MOUNT_USER already exists.'
  else
    pct exec $CTID -- /bin/bash -c "adduser $SHARED_MOUNT_USER --disabled-password --no-create-home --gecos '' --uid 1001 &>/dev/null"
    # Add mount point and user mapping
    # This assumes that we have a "share" drive mounted on host with directory 'public' (/mnt/pve/share/public) AND that $SHARED_MOUNT_USER user (and group) has been added on host with appropriate access to the "public" directory
    cat <<EOF >>/etc/pve/lxc/${CTID}.conf
mp0: ${SHARED_MOUNT_LOC},mp=/mnt/pve/share
lxc.idmap: u 0 100000 1001
lxc.idmap: g 0 100000 1001
lxc.idmap: u 1001 1001 1
lxc.idmap: g 1001 1001 1
lxc.idmap: u 1002 101002 64534
lxc.idmap: g 1002 101002 64534
EOF
  fi
  msg_ok "Mounted shared directory"

  reboot_lxc
fi

if [[ "${POSTFIX_SAT}" == "yes" ]]; then
  [[ "${POSTFIX_SAT_DOMAIN:-}" ]] || exit "You need to set 'POSTFIX_SAT_DOMAIN' variable."
  msg_info "Configuring Postfix Satellite"
  #Install deb-conf-utils to set parameters
  pct exec $CTID -- /bin/bash -c "apt install -qqy debconf-utils &>/dev/null"
  pct exec $CTID -- /bin/bash -c "systemctl stop postfix"
  pct exec $CTID -- /bin/bash -c "mv /etc/postfix/main.cf /etc/postfix/main.cf.BAK"
  pct exec $CTID -- /bin/bash -c "echo postfix postfix/main_mailer_type        select  Satellite system | debconf-set-selections"
  pct exec $CTID -- /bin/bash -c "echo postfix postfix/destinations    string  $app.localdomain, localhost.localdomain, localhost | debconf-set-selections"
  pct exec $CTID -- /bin/bash -c "echo postfix postfix/mailname        string  $app.$POSTFIX_SAT_DOMAIN | debconf-set-selections"
  #This config assumes that the postfix relay host is already set up in another LXC with hostname "postfix" (using port 255)
  pct exec $CTID -- /bin/bash -c "echo postfix postfix/relayhost       string  [postfix.$POSTFIX_SAT_DOMAIN]:255 | debconf-set-selections"
  pct exec $CTID -- /bin/bash -c "echo postfix postfix/mynetworks      string  127.0.0.0/8 | debconf-set-selections"
  pct exec $CTID -- /bin/bash -c "echo postfix postfix/mailbox_limit      string  0 | debconf-set-selections"
  pct exec $CTID -- /bin/bash -c "echo postfix postfix/protocols      select  all | debconf-set-selections"
  pct exec $CTID -- /bin/bash -c "dpkg-reconfigure debconf -f noninteractive &>/dev/null"
  pct exec $CTID -- /bin/bash -c "dpkg-reconfigure postfix -f noninteractive &>/dev/null"
  pct exec $CTID -- /bin/bash -c "postconf 'smtp_tls_security_level = encrypt'"
  pct exec $CTID -- /bin/bash -c "postconf 'smtp_tls_wrappermode = yes'"
  pct exec $CTID -- /bin/bash -c "postconf 'smtpd_tls_security_level = none'"
  pct exec $CTID -- /bin/bash -c "systemctl restart postfix"
  msg_ok "Configured Postfix Satellite"
fi

if [[ "${NVIDIA_PASSTHROUGH}" == "yes" ]]; then
  #Fix container unable to start issue by commenting out /dev/dri lines (from tteck's setup)
  sed -e '/^dev/ s/^#*/#/' -i /etc/pve/lxc/${CTID}.conf
  source <(curl -s https://raw.githubusercontent.com/remz1337/ProxmoxVE/remz/misc/nvidia.func)
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  check_nvidia_drivers_version
  select_nvidia_gpu
  #gpu_id=$(select_nvidia_gpu)
  #gpu_lxc_passthrough $gpu_id
  #spinner &
  #SPINNER_PID=$!
  reboot_lxc

  if [ -z $NVD_VER ]; then
    echo "No Nvidia drivers detected on host."
    exit-script
  fi

  msg_info "Installing Nvidia Drivers"
  #DRIVER_VERSION="550.67"
  EXE_FILE="NVIDIA-Linux-x86_64-${NVD_VER}.run"
  DOWNLOAD_URL="https://download.nvidia.com/XFree86/Linux-x86_64/${NVD_VER}/${EXE_FILE}"

  pct exec $CTID -- /bin/bash -c "rm -f NVIDIA-Linux-x86_64-*.run"
  pct exec $CTID -- /bin/bash -c "wget -q $DOWNLOAD_URL"
  pct exec $CTID -- /bin/bash -c "apt install -qqy libglvnd-dev libvulkan1 pkg-config &>/dev/null"
  pct exec $CTID -- /bin/bash -c "bash $EXE_FILE --no-kernel-module --silent &>/dev/null"
  pct exec $CTID -- /bin/bash -c "rm -f NVIDIA-Linux-x86_64-*.run"
  msg_ok "Installed Nvidia Drivers"
fi

msg_ok "Post install script completed."