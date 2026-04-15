#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Joerg Heinemann (heinemannj)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/smallstep/certificates

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb822_repo \
  "smallstep" \
  "https://packages.smallstep.com/keys/apt/repo-signing-key.gpg" \
  "https://packages.smallstep.com/stable/debian" \
  "debs" \
  "main"

msg_info "Installing step-ca and step-cli"
$STD apt install -y step-ca step-cli

STEPHOME="/root/.step"
export STEPPATH=/etc/step-ca
export STEPHOME=$STEPHOME

sed  -i '1i export STEPPATH=/etc/step-ca' /etc/profile
sed  -i '1i export STEPHOME=/root/.step' /etc/profile

setcap CAP_NET_BIND_SERVICE=+eip $(which step-ca)

$STD useradd --user-group --system --home $(step path) --shell /bin/false step
msg_ok "Installed step-ca and step-cli"

DomainName="$(hostname -d)"

PKIName="$(prompt_input "Enter PKIName" "MyHomePKI" 30)"
PKIProvisioner="$(prompt_input "Enter PKIProvisioner" "pki@$DomainName" 30)"
AcmeProvisioner="$(prompt_input "Enter AcmeProvisioner" "acme@$DomainName" 30)"
X509MinDur="$(prompt_input "Enter X509MinDur" "48h" 30)"
X509MaxDur="$(prompt_input "Enter X509MaxDur" "87600h" 30)"
X509DefaultDur="$(prompt_input "Enter X509DefaultDur" "168h" 30)"

msg_info "Initializing step-ca"
DeploymentType="standalone"
FQDN="$(hostname -f)"
IP="${LOCAL_IP}"
LISTENER=":443"

EncryptionPwdDir="$(step path)/encryption"
PwdFile="$EncryptionPwdDir/ca.pwd"
ProvisionerPwdFile="$EncryptionPwdDir/provisioner.pwd"
mkdir -p "$EncryptionPwdDir"
gpg -q --gen-random --armor 2 32 >"$PwdFile"
gpg -q --gen-random --armor 2 32 >"$ProvisionerPwdFile"

$STD step ca init --deployment-type="$DeploymentType" --ssh --name="$PKIName" --dns="$FQDN" --dns="$IP" --address="$LISTENER" --provisioner="$PKIProvisioner" --password-file="$PwdFile" --provisioner-password-file="$ProvisionerPwdFile"

ln -s "$PwdFile" "$(step path)/password.txt"
chown -R step:step $(step path)
chmod -R 700 $(step path)
$STD step ca provisioner add "$AcmeProvisioner" --type ACME --admin-name "$AcmeProvisioner"
$STD step ca provisioner update "$PKIProvisioner" --x509-min-dur="$X509MinDur" --x509-max-dur="$X509MaxDur" --x509-default-dur="$X509DefaultDur" --allow-renewal-after-expiry
$STD step ca provisioner update "$AcmeProvisioner" --x509-min-dur="$X509MinDur" --x509-max-dur="$X509MaxDur" --x509-default-dur="$X509DefaultDur" --allow-renewal-after-expiry
$STD step certificate install --all $(step path)/certs/root_ca.crt
$STD update-ca-certificates
msg_ok "Initialized step-ca"

msg_info "Start step-ca as a Daemon"
cat <<'EOF' >/etc/systemd/system/step-ca.service
[Unit]
Description=step-ca service
Documentation=https://smallstep.com/docs/step-ca
Documentation=https://smallstep.com/docs/step-ca/certificate-authority-server-production
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=30
StartLimitBurst=3
ConditionFileNotEmpty=/etc/step-ca/config/ca.json
ConditionFileNotEmpty=/etc/step-ca/password.txt

[Service]
Type=simple
User=step
Group=step
Environment=STEPPATH=/etc/step-ca
WorkingDirectory=/etc/step-ca
ExecStart=/usr/bin/step-ca config/ca.json --password-file password.txt
ExecReload=/bin/kill -USR1 $MAINPID
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitAction=reboot

; Process capabilities & privileges
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
SecureBits=keep-caps
NoNewPrivileges=yes

; Sandboxing
SystemCallArchitectures=native
SystemCallFilter=@system-service
SystemCallFilter=~@resources @privileged
RestrictNamespaces=yes
LockPersonality=yes
MemoryDenyWriteExecute=yes
RestrictRealtime=yes
RestrictSUIDSGID=yes
PrivateMounts=yes
ProtectControlGroups=yes
ProtectKernelModules=yes
ProtectKernelTunables=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/etc/step-ca/db

; Read only paths
ReadOnlyPaths=/etc/step-ca

[Install]
WantedBy=multi-user.target
EOF
$STD systemctl enable -q --now step-ca
msg_ok "Started step-ca as a Daemon"

fetch_and_deploy_gh_release "step-badger" "lukasz-lobocki/step-badger" "prebuild" "latest" "/opt/step-badger" "step-badger_Linux_x86_64.tar.gz"
ln -s /opt/step-badger/step-badger /usr/local/bin/step-badger

msg_info "Install step-ca Admin script"
mkdir -p "$STEPHOME"
cat <<'ADDON_EOF' >"$STEPHOME/step-ca-admin.sh"
#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Joerg Heinemann (heinemannj)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info() {
  clear
  cat <<"EOF"
         __                                 ___       __          _     
   _____/ /____  ____        _________ _   /   | ____/ /___ ___  (_)___ 
  / ___/ __/ _ \/ __ \______/ ___/ __ `/  / /| |/ __  / __ `__ \/ / __ \
 (__  ) /_/  __/ /_/ /_____/ /__/ /_/ /  / ___ / /_/ / / / / / / / / / /
/____/\__/\___/ .___/      \___/\__,_/  /_/  |_\__,_/_/ /_/ /_/_/_/ /_/ 
             /_/                                                            

EOF
}

function die() {
  echo -e "\n${BL}[ERROR]${GN} ${RD}${1}${CL}\n"
  exit
}

function success() {
  echo -e "${BL}[SUCCESS]${GN} ${1}${CL}\n"
  exit
}

function whiptail_menu() {
  MENU_ARRAY=()
  MSG_MAX_LENGTH=0
  while read -r TAG ITEM; do
    OFFSET=2
    ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
    MENU_ARRAY+=("$TAG" "$ITEM " "OFF")
  done < <(echo "$1")
}

function x509_list() {
  CERT_LIST=""
  cp --recursive --force "$(step path)/db/"* "$STEPHOME/db-copy/"
  cp --recursive --force "$(step path)/certs/"* "$STEPHOME/certs/ca/"
  if [[ $(step-badger x509Certs "${STEPHOME}/db-copy" 2>/dev/null) ]]; then
    CERT_LIST=$(step-badger x509Certs ${STEPHOME}/db-copy 2>/dev/null)
  fi
}

function ssh_list() {
  CERT_LIST=""
  cp --recursive --force "$(step path)/db/"* "$STEPHOME/db-copy/"
  cp --recursive --force "$(step path)/certs/"* "$STEPHOME/certs/ca/"
  if [[ $(step-badger sshCerts "${STEPHOME}/db-copy" 2>/dev/null) ]]; then
    CERT_LIST=$(step-badgersshCerts ${STEPHOME}/db-copy 2>/dev/null)
  fi
}

function x509_serial_to_cn() {
  x509_list
  CN="$(echo "${CERT_LIST}" | grep "${SERIAL_NUMBER}" | awk '{print $2}' | sed 's/CN=//g')"
  CRT="$STEPHOME/certs/x509/$CN.crt"
  KEY="$STEPHOME/certs/x509/$CN.key"
  if ! [[ -f ${CRT} ]]; then
    die "Certificate ${CRT} not found!"
  elif ! [[ -f ${KEY} ]]; then
    die "Private Key ${KEY} not found!"
  fi
}

function x509_revoke() {
  # shellcheck disable=SC2206
  SERIAL_NUMBER_ARRAY=(${CERT_SERIAL_NUMBERS})
  for SERIAL_NUMBER in "${SERIAL_NUMBER_ARRAY[@]}"; do
    echo -e "${BL}[Info]${GN} Revoke x509 Certificate with Serial Number ${BL}${SERIAL_NUMBER}${GN}:${CL}"
    echo
    TOKEN=$(step ca token --provisioner="$PROVISIONER" --provisioner-password-file="$PROVISIONER_PASSWORD" --revoke "${SERIAL_NUMBER}")
    step ca revoke --token "$TOKEN" "${SERIAL_NUMBER}" || die "Failed to revoke certificate!"
    echo
  done
  success "Finished."
}

function x509_renew() {
  # shellcheck disable=SC2206
  SERIAL_NUMBER_ARRAY=(${CERT_SERIAL_NUMBERS})
  for SERIAL_NUMBER in "${SERIAL_NUMBER_ARRAY[@]}"; do
    echo -e "${BL}[Info]${GN} Renew x509 Certificate with Serial Number ${BL}${SERIAL_NUMBER}${GN}:${CL}"
    echo
    x509_serial_to_cn
    step ca renew "${CRT}" "${KEY}" --force || die "Failed to renew certificate!"
    echo
  done
  success "Finished."
}

function x509_inspect() {
  # shellcheck disable=SC2206
  SERIAL_NUMBER_ARRAY=(${CERT_SERIAL_NUMBERS})
  for SERIAL_NUMBER in "${SERIAL_NUMBER_ARRAY[@]}"; do
    echo -e "${BL}[Info]${GN} Inspect x509 Certificate with Serial Number ${BL}${SERIAL_NUMBER}${GN}:${CL}\n"
    x509_serial_to_cn
    step certificate inspect "${CRT}" || die "Failed to inspect certificate!"
    if ! [[ $(step certificate inspect "${CRT}" | grep "${SERIAL_NUMBER}") ]]; then
      die "Serial Number ${SERIAL_NUMBER} mismatch!"
    fi
    echo -e "\n${BL}[Info]${GN} Public Key:${CL}\n"
    cat "${CRT}"
    echo -e "\n${BL}[Info]${GN} Private Key:${CL}\n"
    cat "${KEY}"
    echo
  done
  success "Finished."
}

function x509_request() {
  FQDN=""
  SAN=""

  while true; do
    FQDN=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Certificate Signing Request (CSR)" --inputbox '\nFQDN (e.g. MyLXC.example.com)' 10 50 "$FQDN" 3>&1 1>&2 2>&3)
    IP=$(dig +short "$FQDN")
    if [[ -z "$IP" ]]; then
      die "Resolution failed for $FQDN!"
    fi
    HOST=$(echo "$FQDN" | awk -F'.' '{print $1}')
    IP=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Certificate Signing Request (CSR)" --inputbox '\nIP Address (e.g. x.x.x.x)' 10 50 "$IP" 3>&1 1>&2 2>&3)
    HOST=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Certificate Signing Request (CSR)" --inputbox '\nHostname (e.g. MyHostName)' 10 50 "$HOST" 3>&1 1>&2 2>&3)
    SAN=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Certificate Signing Request (CSR)" --inputbox '\nSubject Alternative Name(s) (SAN) (e.g. myapp-1.example.com, myapp-2.example.com)' 10 50 "$SAN" 3>&1 1>&2 2>&3)
    VALID_TO=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Certificate Signing Request (CSR)" --inputbox '\nValidity (e.g. 2034-01-31T00:00:00Z)' 10 50 "2034-01-31T00:00:00Z" 3>&1 1>&2 2>&3)

    # shellcheck disable=SC2034
    if whiptail_yesno=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Certificate Signing Request (CSR)" --yesno "Continue with below?\n
      FQDN: $FQDN
      Hostname: $HOST
      IP Address: $IP
      Subject Alternative Name(s) (SAN): $SAN
      Validity: $VALID_TO" --no-button "Change" --yes-button "Continue" 15 70 3>&1 1>&2 2>&3); then
      break
    fi
  done

  echo -e "${BL}[Info]${GN} Request x509 Certificate with subject ${BL}${FQDN}${GN}:${CL}"
  echo
  CRT="$STEPHOME/certs/x509/$FQDN.crt"
  KEY="$STEPHOME/certs/x509/$FQDN.key"

  SAN="$FQDN, $HOST, $IP, $SAN"

  IFS=', ' read -r -a array <<< "$SAN"
  for element in "${array[@]}"
  do
    SAN_ARRAY+=(--san "$element")
  done

  step ca certificate "$FQDN" "$CRT" "$KEY" \
    --provisioner="$PROVISIONER" \
    --provisioner-password-file="$PROVISIONER_PASSWORD" \
    --not-after="$VALID_TO" \
    "${SAN_ARRAY[@]}" \
  || die "Failed to request certificate!"

  echo -e "\n${BL}[Info]${GN} Inspect Certificate:${CL}\n"
  step certificate inspect "${CRT}" || die "Failed to inspect certificate!"
  echo -e "\n${BL}[Info]${GN} Public Key:${CL}\n"
  cat "${CRT}"
  echo -e "\n${BL}[Info]${GN} Private Key:${CL}\n"
  cat "${KEY}"
  echo
  success "Finished."
}

set -eEuo pipefail
# shellcheck disable=SC2034
# shellcheck disable=SC2116
# shellcheck disable=SC2028
YW=$(echo "\033[33m")
# shellcheck disable=SC2116
# shellcheck disable=SC2028
BL=$(echo "\033[36m")
# shellcheck disable=SC2116
# shellcheck disable=SC2028
RD=$(echo "\033[01;31m")
# shellcheck disable=SC2034
CM='\xE2\x9C\x94\033'
# shellcheck disable=SC2116
# shellcheck disable=SC2028
GN=$(echo "\033[1;92m")
# shellcheck disable=SC2116
# shellcheck disable=SC2028
CL=$(echo "\033[m")

# Telemetry
# shellcheck disable=SC1090
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "step-ca-admin" "step-ca"

header_info

mkdir --parents "$STEPHOME/db-copy/"
mkdir --parents "$STEPHOME/certs/ca/_archive/"
mkdir --parents "$STEPHOME/certs/ssh/_archive/"
mkdir --parents "$STEPHOME/certs/x509/_archive/"

PROVISIONER=$(jq '.authority.provisioners.[] | select(.type=="JWK") | .name' "$(step path)"/config/ca.json)
PROVISIONER="${PROVISIONER#\"}"
PROVISIONER="${PROVISIONER%\"}"
PROVISIONER_PASSWORD=$(step path)/encryption/provisioner.pwd

whiptail --backtitle "Proxmox VE Helper Scripts" --title "step-ca Admin" --yesno "This will maintain step-ca issued x509 and ssh Certificates. Proceed?" 10 58

MENU_ARRAY=("x509" "Maintain x509 Certificates." "ON")
MENU_ARRAY+=("ssh" "Maintain ssh Certificates." "OFF")
CERT_TYPE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "step-ca Admin" --radiolist "\nSelect Certificate Type:" 16 48 6 "${MENU_ARRAY[@]}" 3>&1 1>&2 2>&3 | tr -d '"')

[[ -z ${CERT_TYPE} ]] && die "No Certificate Type selected!"

case ${CERT_TYPE} in
("x509")
  x509_list
  CERT_LIST=$(echo "$CERT_LIST" | awk 'NR>1 {print $1 " " $2 "|" $3 "|" $4 "|" $5}')
  if [[ $CERT_LIST ]]; then
    whiptail_menu "$CERT_LIST"
  else
    MENU_ARRAY=()
    MSG_MAX_LENGTH=2
  fi
  MENU_ARRAY+=("" "Create a new Certificate" "OFF")
  CERT_SERIAL_NUMBERS=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Certificates on $(hostname)" --checklist "\nSelect Certificate(s) to maintain:\n" 16 $((MSG_MAX_LENGTH + 55)) 6 "${MENU_ARRAY[@]}" 3>&1 1>&2 2>&3 | tr -d '"')

  [[ -z ${CERT_SERIAL_NUMBERS} ]] && x509_request
  
  MENU_ARRAY=("Renew" "Renew x509 Certificates." "ON")
  MENU_ARRAY+=("Revoke" "Revoke x509 Certificates." "OFF")
  MENU_ARRAY+=("Inspect" "Inspect x509 Certificates." "OFF")
  CERT_MAINTENANCE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "step-ca Admin" --radiolist "\nSelect Maintenance Type:" 16 48 6 "${MENU_ARRAY[@]}" 3>&1 1>&2 2>&3 | tr -d '"')

  case ${CERT_MAINTENANCE} in
  ("Renew")
    x509_renew "${CERT_SERIAL_NUMBERS[@]}"
    ;;
  ("Revoke")
    x509_revoke "${CERT_SERIAL_NUMBERS[@]}"
    ;;
  ("Inspect")
    x509_inspect "${CERT_SERIAL_NUMBERS[@]}"
    ;;
  *)
    die "Unsupported CERT_MAINTENANCE Option!"
    ;;
  esac
  ;;
("ssh")
  die "Maintain ssh Certificates - To be implemented in future"
  ;;
*)
  die "Unsupported CERT_TYPE Option!"
  ;;
esac
ADDON_EOF
chmod 700 "$STEPHOME/step-ca-admin.sh"
msg_ok "Installed step-ca Admin script"

motd_ssh
customize
cleanup_lxc
