
start() {

  if command -v incus >/dev/null 2>&1; then
    if ! (whiptail --backtitle "Incus Scripts" --title "${APP} Container" --yesno "This will create a New ${APP} Container. Proceed?" 10 58); then
      clear
      exit_script
      exit
    fi
    SPINNER_PID=""
    install_script
  fi

  if ! command -v incus >/dev/null 2>&1; then
    if ! (whiptail --backtitle "Incus Scripts" --title "${APP} Container UPDATE" --yesno "Support/Update functions for ${APP} Container.  Proceed?" 10 58); then
      clear
      exit_script
      exit
    fi
    SPINNER_PID=""
    update_script
  fi

}
