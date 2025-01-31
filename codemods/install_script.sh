install_script() {
  pve_check
  shell_check
  root_check
  arch_check
  ssh_check
  maxkeys_check
  #diagnostics_check

  # if systemctl is-active -q ping-instances.service; then
  #   systemctl -q stop ping-instances.service
  # fi


  NEXTID=$(uuidgen | cut -c1-6)
  timezone=$(cat /etc/timezone)
  header_info
  while true; do

    CHOICE=$(whiptail --backtitle "Incus Scripts" --title "SETTINGS" --menu "Choose an option:" \
      12 50 5 \
      "1" "Default Settings" \
      "2" "Default Settings (with verbose)" \
      "3" "Advanced Settings" \
      "4" "Diagnostic Settings" \
      "5" "Exit" --nocancel --default-item "1" 3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
      echo -e "${CROSS}${RD} Menu canceled. Exiting.${CL}"
      exit 0
    fi

    case $CHOICE in
    1)
      header_info
      echo -e "${DEFAULT}${BOLD}${BL}Using Default Settings on node $PVEHOST_NAME${CL}"
      VERB="no"
      METHOD="default"
      base_settings "$VERB"
      echo_default
      break
      ;;
    2)
      header_info
      echo -e "${DEFAULT}${BOLD}${BL}Using Default Settings on node $PVEHOST_NAME (${SEARCH}Verbose)${CL}"
      VERB="yes"
      METHOD="default"
      base_settings "$VERB"
      echo_default
      break
      ;;
    3)
      header_info
      echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings on node $PVEHOST_NAME${CL}"
      METHOD="advanced"
      advanced_settings
      break
      ;;
     4)
      echo -e "${CROSS}${RD}Skipping diagnostics.${CL}"

        ;;
    5)
      echo -e "${CROSS}${RD}Exiting.${CL}"
      exit 0
      ;;
    *)
      echo -e "${CROSS}${RD}Invalid option, please try again.${CL}"
      ;;
    esac
  done
}
