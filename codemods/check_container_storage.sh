check_container_storage() {
  # Check if the /boot partition is more than 80% full
  total_size=$(df / --output=size | tail -n 1)
  local used_size=$(df / --output=used | tail -n 1)
  usage=$(( 100 * used_size / total_size ))
  if (( usage > 80 )); then
    # Prompt the user for confirmation to continue
    echo -e "${INFO}${HOLD} ${YWB}Warning: Storage is dangerously low (${usage}%).${CL}"
    read -r -p "Continue anyway? <y/N>  " prompt
    # Check if the input is 'y' or 'yes', otherwise exit with status 1
    if [[ ! ${prompt,,} =~ ^(y|yes)$ ]]; then
      echo -e "${CROSS}${HOLD}${YWB}Exiting based on user input.${CL}"
      exit 1
    fi
  fi
}
