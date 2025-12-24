#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# Co-Author: remz1337
# License: MIT
# https://github.com/remz1337/ProxmoxVE/raw/remz/LICENSE

function header_info() {
  clear
  cat <<"EOF"
    _   __      _     ___          ____       _                     
   / | / /   __(_)___/ (_)___ _   / __ \_____(_)   _____  __________
  /  |/ / | / / / __  / / __ `/  / / / / ___/ / | / / _ \/ ___/ ___/
 / /|  /| |/ / / /_/ / / /_/ /  / /_/ / /  / /| |/ /  __/ /  (__  ) 
/_/ |_/ |___/_/\__,_/_/\__,_/  /_____/_/  /_/ |___/\___/_/  /____/  
                                                                    
EOF
}
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
CM='\xE2\x9C\x94\033'
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")

function install_nvidia_drivers_lxc() {
  container=$1
  header_info
  name=$(pct exec "$container" hostname)
  os=$(pct config "$container" | awk '/^ostype/ {print $2}')
  if [[ "$os" == "ubuntu" || "$os" == "debian" || "$os" == "fedora" ]]; then
    disk_info=$(pct exec "$container" df /boot | awk 'NR==2{gsub("%","",$5); printf "%s %.1fG %.1fG %.1fG", $5, $3/1024/1024, $2/1024/1024, $4/1024/1024 }')
    read -ra disk_info_array <<<"$disk_info"
    echo -e "${BL}[Info]${GN} Installing Nvidia to ${BL}$container${CL} : ${GN}$name${CL} - ${YW}Boot Disk: ${disk_info_array[0]}% full [${disk_info_array[1]}/${disk_info_array[2]} used, ${disk_info_array[3]} free]${CL}\n"
  else
    echo -e "${BL}[Info]${GN} Installing Nvidia to ${BL}$container${CL} : ${GN}$name${CL} - ${YW}[No disk info for ${os}]${CL}\n"
  fi
  
  pct exec "$container" -- bash -c "apt install -yq libglvnd-dev libvulkan1 pkg-config"
  pct push "$container" $EXE_FILE /tmp/$EXE_FILE
  pct exec "$container" -- bash -c "bash /tmp/$EXE_FILE -q -a -n -s --no-kernel-module"
  pct exec "$container" -- bash -c "rm /tmp/$EXE_FILE"
}


header_info
echo "Loading..."

if ! (whiptail --backtitle "Proxmox VE Helper Scripts" --title "Nvidia Drivers" --yesno "Installing Nvidia drivers requires to reboot the host. Continue?" 10 58); then
  echo -e "⚠  User exited script \n"
  exit
fi

source <(curl -s https://raw.githubusercontent.com/remz1337/ProxmoxVE/remz/misc/nvidia.func)
nvidia_installed=$(check_nvidia_drivers_installed)
if [ $nvidia_installed == 1 ]; then
  check_nvidia_drivers_version
  echo -e "Nvidia drivers detected. Version ${NVD_VER}"
fi

#Make sure host as appropriate dependencies
apt install -y dkms pve-headers wget

#Clean up old files
rm NVIDIA-Linux-x86_64-*.run

#DRIVER_VERSION="550.67"
#LATEST_VERSION=$(curl -s https://download.nvidia.com/XFree86/Linux-x86_64/latest.txt)
LATEST_VERSION=$(curl -s "https://www.nvidia.com/en-us/drivers/unix/" | grep -oP -m1 "Linux x86_64.*Latest Production Branch Version:.*?\/a>" | sed 's|.*">||g' | sed 's|<.*||g')
#INSTALL_VERSION=${LATEST_VERSION% *}
INSTALL_VERSION="${LATEST_VERSION#"${LATEST_VERSION%%[![:space:]]*}"}"
INSTALL_VERSION="${INSTALL_VERSION%"${INSTALL_VERSION##*[![:space:]]}"}"


echo -e "Nvidia latest drivers version: ${INSTALL_VERSION}"

#NVD_MAJOR=${NVD_VER%%.*}
NVD_MINOR=$(echo ${NVD_VER} | cut -d'.' -f2)
INSTALL_MAJOR=${INSTALL_VERSION%%.*}
INSTALL_MINOR=$(echo ${INSTALL_VERSION} | cut -d'.' -f2)

if [ $INSTALL_MAJOR -gt $NVD_MAJOR ]; then
  echo "New major version available"
elif [ $INSTALL_MAJOR -eq $NVD_MAJOR ] && [ $INSTALL_MINOR -gt $NVD_MINOR ]; then
  echo "New minor version available"
else
  echo "Installed drivers are up to date"
  read -r -p "Do you still want to manually install a different version? <y/N> " prompt
  if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
    echo -e "Proceeding with installation"
  else
    exit 1
  fi
fi

if INPUT=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Enter Nvidia Drivers Version" 8 58 $INSTALL_VERSION --title "NVIDIA DRIVERS" 3>&1 1>&2 2>&3); then
  if [ ! -z "$INPUT" ]; then
    INSTALL_VERSION=$(echo ${INPUT,,} | tr -d ' ')
  fi
  echo -e "${DGN}Installing Driver Version: ${BGN}$INSTALL_VERSION${CL}"
else
  exit
fi

EXE_FILE="NVIDIA-Linux-x86_64-$INSTALL_VERSION.run"
DOWNLOAD_URL="https://download.nvidia.com/XFree86/Linux-x86_64/$INSTALL_VERSION/$EXE_FILE"

wget -q $DOWNLOAD_URL

if [ ! -f "$EXE_FILE" ]; then
	echo -e "${RD}Nvidia drivers file not found!${CL}"
	echo -e "Make sure the specified version is available from ${BL}https://download.nvidia.com/XFree86/Linux-x86_64/${CL}"
	exit
fi

#Dependencies for OpenGL/Vulkan
apt install -y libglvnd-dev libvulkan1 pkg-config

#/usr/bin/nvidia-uninstall
#rmmod nvidia-uvm
#sleep 1
#Some additionnal arguments to test
#--skip-module-load --skip-module-unload --allow-installation-with-running-driver --rebuild-initramfs
bash "$EXE_FILE" -q -a -n -s --dkms --allow-installation-with-running-driver

#echo "Installation of NVIDIA drivers complete"


#Installing in LXC
#pct push 104 $EXE_FILE /tmp/$EXE_FILE

#Pre-check containers that are configured with Nvidia GPU passthrough
NVIDIA_CTIDS=$(grep -l "/dev/nvidia" /etc/pve/lxc/*.conf | sed 's/.*\/\([0-9]\+\)\.conf/\1/')

echo "Detected Nvidia-enabled containers:"
echo "$NVIDIA_CTIDS"

whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE Nvidia Updater" --yesno "Do you want to install Nvidia drivers in selected LXC containers?" 10 58 || exit
NODE=$(hostname)
INCLUDE_MENU=()
MSG_MAX_LENGTH=0

while read -r TAG ITEM; do
  OFFSET=2
  # Default selection
  STATE="OFF"
  # If container ID is in Nvidia list, set to ON
  if echo "$NVIDIA_CTIDS" | grep -qw "$TAG"; then
    STATE="ON"
  fi
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  INCLUDE_MENU+=("$TAG" "$ITEM " "$STATE")
done < <(pct list | awk 'NR>1')
included_containers=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Containers on $NODE" --checklist "\nSelect containers to install Nvidia drivers:\n" 16 $((MSG_MAX_LENGTH + 23)) 6 "${INCLUDE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"') || exit

for container in $(pct list | awk '{if(NR>1) print $1}'); do
  if [[ " ${included_containers[@]} " =~ " $container " ]]; then
    status=$(pct status $container)
    template=$(pct config $container | grep -q "template:" && echo "true" || echo "false")
    if [ "$template" == "false" ] && [ "$status" == "status: stopped" ]; then
      echo -e "${BL}[Info]${GN} Starting${BL} $container ${CL} \n"
      pct start $container
      echo -e "${BL}[Info]${GN} Waiting For${BL} $container${CL}${GN} To Start ${CL} \n"
      sleep 5
      install_nvidia_drivers_lxc $container
      echo -e "${BL}[Info]${GN} Shutting down${BL} $container ${CL} \n"
      pct shutdown $container &
    elif [ "$status" == "status: running" ]; then
      install_nvidia_drivers_lxc $container
    fi
    sleep 1
  fi
done
wait

#Clean up install file to avoid backing it up
rm NVIDIA-Linux-x86_64-*.run

header_info
echo -e "${GN} Finished, Nvidia drivers installed.${CL}\n"

if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "Nvidia Drivers" --yesno "Nvidia drivers installation complete. Are you ready to reboot the host?" 10 58); then
  echo -e "⚠  Rebooting \n"
  reboot
fi
