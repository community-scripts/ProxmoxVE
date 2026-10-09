#!/usr/bin/env bash
# ============================================================================
#  Community-Scripts ProxmoxVE — Post-Install Hook: Example Library
# ----------------------------------------------------------------------------
#  This file is NOT meant to be executed as-is.
#  It is a collection of complete, copy-pasteable example hooks for the
#  optional `var_post_install` feature in build.func.
#
#  HOW IT WORKS
#  ------------
#  In the ct/*.sh CT scripts (or via Advanced Settings → Step 28) you can
#  point `var_post_install` to an absolute path on the Proxmox HOST, e.g.:
#
#      # in /root/.community-scripts/default.vars
#      var_post_install=/opt/community-scripts/hooks/notify.sh
#
#      # OR per-app, in app.vars
#      var_post_install=/opt/community-scripts/hooks/vaultwarden-postprovision.sh
#
#      # OR interactively in the Advanced Settings whiptail (Step 28).
#
#  The hook runs ON THE PROXMOX HOST (NOT inside the LXC) as root,
#  AFTER the container is fully provisioned, started and the description
#  is set. stdout/stderr is captured to:
#
#      /var/log/community-scripts/post-install-<CTID>.log
#
#  AVAILABLE ENV VARIABLES
#  -----------------------
#    APP        - Pretty name (e.g. "Vaultwarden")
#    NSAPP      - Slug / lowercase  (e.g. "vaultwarden")
#    CTID       - Numeric container ID (e.g. "103")
#    IP         - IPv4 address of the LXC (e.g. "192.168.1.50")
#    HN         - Hostname (e.g. "vaultwarden")
#    STORAGE    - Storage where the rootfs lives (e.g. "local-lvm")
#    BRG        - Bridge (e.g. "vmbr0")
#
#  GENERAL TIPS
#  ------------
#  - Use `set -euo pipefail` so failures actually surface.
#  - Use `|| true` on best-effort steps you do not want to abort the hook.
#  - The file just needs to be a valid script. `+x` is optional — it is
#    invoked via `bash <path>`. Shebang is honored only if you call it
#    yourself; otherwise the shebang line is purely cosmetic.
#  - If the hook exits non-zero, the user gets a whiptail popup with the
#    last 15 log lines. The LXC creation itself is NOT rolled back.
#  - Keep hooks idempotent — they may be re-run if you recreate a CT.
#
#  HOW TO USE THIS FILE
#  --------------------
#    1. Copy ONE example block (between the BEGIN/END markers) into a new
#       file on the Proxmox host, e.g. /opt/community-scripts/hooks/notify.sh
#    2. chmod +x /opt/community-scripts/hooks/notify.sh   (optional)
#    3. Set var_post_install in default.vars / app.vars or pick the path
#       in Advanced Settings.
# ============================================================================

# ============================================================================
# ▼▼▼ EXAMPLE 1 — BEGIN ▼▼▼
# ----------------------------------------------------------------------------
#  Name        : minimal-logger.sh
#  Purpose     : Append every newly created LXC to a single CSV-ish log.
#  Difficulty  : ⭐ Beginner
#  Side effects: Writes to /var/log/community-scripts/created-lxcs.log
#  Use case    : You just want a paper trail of "what got created when".
# ============================================================================
#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="/var/log/community-scripts"
LOG_FILE="${LOG_DIR}/created-lxcs.log"

mkdir -p "$LOG_DIR"

# Header on first use
if [[ ! -s "$LOG_FILE" ]]; then
  echo "timestamp;ctid;app;hostname;ip;bridge;storage" >"$LOG_FILE"
fi

printf '%s;%s;%s;%s;%s;%s;%s\n' \
  "$(date -Iseconds)" \
  "${CTID}" \
  "${APP}" \
  "${HN}" \
  "${IP}" \
  "${BRG}" \
  "${STORAGE}" \
  >>"$LOG_FILE"

echo "Logged ${APP} (CTID=${CTID}) to ${LOG_FILE}"
# ▲▲▲ EXAMPLE 1 — END ▲▲▲

# ============================================================================
# ▼▼▼ EXAMPLE 2 — BEGIN ▼▼▼
# ----------------------------------------------------------------------------
#  Name        : discord-gotify-notify.sh
#  Purpose     : Send a rich Discord embed AND a Gotify push notification
#                whenever a new LXC is provisioned.
#  Difficulty  : ⭐⭐ Intermediate
#  Requires    : curl on the host (default), reachable webhook URLs.
#  Side effects: Outbound HTTPS to Discord + your Gotify server.
# ============================================================================
#!/usr/bin/env bash
set -euo pipefail

# --- CONFIG (edit me) -------------------------------------------------------
DISCORD_WEBHOOK="https://discord.com/api/webhooks/XXXXXXXX/YYYYYYYY"
GOTIFY_URL="https://gotify.example.com"
GOTIFY_TOKEN="AbCdEfGhIjKlMnO"
GOTIFY_PRIORITY=5
# ----------------------------------------------------------------------------

# Resolve the Proxmox node's hostname for context
NODE="$(hostname -s)"
TS="$(date -Iseconds)"

# --- Discord embed ----------------------------------------------------------
read -r -d '' DISCORD_PAYLOAD <<JSON || true
{
  "username": "Proxmox - ${NODE}",
  "avatar_url": "https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/images/logo-81x112.png",
  "embeds": [{
    "title": "✅ ${APP} LXC created",
    "description": "A new community-script LXC has been provisioned on **${NODE}**.",
    "color": 3066993,
    "timestamp": "${TS}",
    "fields": [
      {"name": "CTID",     "value": "${CTID}",    "inline": true},
      {"name": "Hostname", "value": "${HN}",      "inline": true},
      {"name": "App",      "value": "${APP}",     "inline": true},
      {"name": "IP",       "value": "${IP}",      "inline": true},
      {"name": "Bridge",   "value": "${BRG}",     "inline": true},
      {"name": "Storage",  "value": "${STORAGE}", "inline": true}
    ],
    "footer": {"text": "community-scripts.org"}
  }]
}
JSON

curl -fsS --max-time 10 \
  -H "Content-Type: application/json" \
  -X POST "$DISCORD_WEBHOOK" \
  --data "$DISCORD_PAYLOAD" \
  >/dev/null ||
  echo "WARN: Discord webhook failed (non-fatal)"

# --- Gotify push ------------------------------------------------------------
curl -fsS --max-time 10 \
  -H "X-Gotify-Key: ${GOTIFY_TOKEN}" \
  -F "title=Proxmox: ${APP} LXC created" \
  -F "message=CTID=${CTID}  IP=${IP}  HN=${HN}  on ${NODE}" \
  -F "priority=${GOTIFY_PRIORITY}" \
  "${GOTIFY_URL}/message" \
  >/dev/null ||
  echo "WARN: Gotify push failed (non-fatal)"

echo "Notifications dispatched for CTID=${CTID}"
# ▲▲▲ EXAMPLE 2 — END ▲▲▲

# ============================================================================
# ▼▼▼ EXAMPLE 3 — BEGIN ▼▼▼
# ----------------------------------------------------------------------------
#  Name        : auto-pool-tags-backup.sh
#  Purpose     : Add the new LXC to a Proxmox pool, append cluster-wide tags,
#                register a DNS record in pi-hole, and trigger an immediate
#                snapshot backup to a configured storage.
#  Difficulty  : ⭐⭐⭐ Advanced
#  Requires    : pvesh, pct, vzdump (host-side; available by default on PVE),
#                a reachable pi-hole admin API.
# ============================================================================
#!/usr/bin/env bash
set -euo pipefail

# --- CONFIG (edit me) -------------------------------------------------------
TARGET_POOL="auto-lxc"
EXTRA_TAGS=("auto-provisioned" "${NSAPP}") # community-script tag is set by build.func
BACKUP_STORAGE="pbs-main"                  # set to "" to skip initial backup
PIHOLE_HOST="192.168.1.5"
PIHOLE_PASSWORD="changeme" # web-UI password
DNS_DOMAIN="lan"           # FQDN will be ${HN}.${DNS_DOMAIN}
# ----------------------------------------------------------------------------

# 1) Ensure the pool exists, then attach the CT
if ! pvesh get "/pools/${TARGET_POOL}" >/dev/null 2>&1; then
  echo "Creating pool: ${TARGET_POOL}"
  pvesh create /pools --poolid "${TARGET_POOL}" --comment "Auto-created by post-install hook" || true
fi
echo "Adding CTID=${CTID} to pool=${TARGET_POOL}"
pvesh set "/pools/${TARGET_POOL}" --vms "${CTID}" || echo "WARN: pool attach failed (non-fatal)"

# 2) Merge new tags with existing ones (preserve community-script etc.)
CURRENT_TAGS="$(pct config "${CTID}" | awk -F': ' '/^tags:/{print $2}')"
declare -A TAG_SET
IFS=';' read -r -a CUR_ARR <<<"${CURRENT_TAGS:-}"
for t in "${CUR_ARR[@]}"; do [[ -n "$t" ]] && TAG_SET["$t"]=1; done
for t in "${EXTRA_TAGS[@]}"; do [[ -n "$t" ]] && TAG_SET["$t"]=1; done
NEW_TAGS="$(
  IFS=';'
  echo "${!TAG_SET[*]}"
)"
echo "Setting tags: ${NEW_TAGS}"
pct set "${CTID}" --tags "${NEW_TAGS}" || echo "WARN: tag update failed (non-fatal)"

# 3) Register DNS in pi-hole (custom DNS record)
FQDN="${HN}.${DNS_DOMAIN}"
echo "Registering DNS: ${FQDN} → ${IP} on pi-hole ${PIHOLE_HOST}"
SID="$(curl -fsS --max-time 5 \
  -d "pw=${PIHOLE_PASSWORD}" \
  "http://${PIHOLE_HOST}/api/auth" 2>/dev/null |
  sed -nE 's/.*"sid":"([^"]+)".*/\1/p' || true)"

if [[ -n "${SID}" ]]; then
  curl -fsS --max-time 5 -X PUT \
    -H "Content-Type: application/json" \
    -H "sid: ${SID}" \
    -d "{\"hosts\":[\"${IP} ${FQDN}\"]}" \
    "http://${PIHOLE_HOST}/api/config/dns/hosts" >/dev/null ||
    echo "WARN: pi-hole DNS update failed (non-fatal)"
  curl -fsS --max-time 5 -X DELETE -H "sid: ${SID}" "http://${PIHOLE_HOST}/api/auth" >/dev/null || true
else
  echo "WARN: could not obtain pi-hole session (skipping DNS)"
fi

# 4) Initial backup (best-effort, can take a few minutes)
if [[ -n "${BACKUP_STORAGE}" ]]; then
  if pvesh get "/storage/${BACKUP_STORAGE}" >/dev/null 2>&1; then
    echo "Triggering initial backup of CTID=${CTID} to ${BACKUP_STORAGE}"
    vzdump "${CTID}" \
      --storage "${BACKUP_STORAGE}" \
      --mode snapshot \
      --compress zstd \
      --notes-template "Initial backup of ${APP} (CTID=${CTID})" \
      --notification-mode auto ||
      echo "WARN: initial backup failed (non-fatal)"
  else
    echo "Backup storage '${BACKUP_STORAGE}' not found — skipping."
  fi
fi

echo "Post-provision routine complete for ${APP} (CTID=${CTID})"
# ▲▲▲ EXAMPLE 3 — END ▲▲▲

# ============================================================================
# ▼▼▼ EXAMPLE 4 — BEGIN ▼▼▼
# ----------------------------------------------------------------------------
#  Name        : inject-ssh-and-monitoring.sh
#  Purpose     : Push the host's admin SSH key into the new LXC, install the
#                Beszel monitoring agent inside the container, and register
#                an Uptime-Kuma HTTP push monitor for the LXC's IP.
#  Difficulty  : ⭐⭐⭐ Advanced
#  Requires    : pct (host), curl (inside LXC), reachable Beszel hub +
#                Uptime-Kuma push URL.
# ============================================================================
#!/usr/bin/env bash
set -euo pipefail

# --- CONFIG (edit me) -------------------------------------------------------
ADMIN_KEY="/root/.ssh/admin_ed25519.pub"
BESZEL_HUB_URL="http://192.168.1.10:8090"
BESZEL_AGENT_KEY="ssh-ed25519 AAAA... beszel@hub" # public key of the hub
UPTIME_KUMA_PUSH_BASE="http://uptime.lan/api/push/abc123"
# ----------------------------------------------------------------------------

# 1) Inject the admin SSH key
if [[ -f "${ADMIN_KEY}" ]]; then
  echo "Pushing admin SSH key into CTID=${CTID}"
  pct exec "${CTID}" -- mkdir -p /root/.ssh
  pct exec "${CTID}" -- chmod 700 /root/.ssh
  pct push "${CTID}" "${ADMIN_KEY}" /root/.ssh/authorized_keys
  pct exec "${CTID}" -- chmod 600 /root/.ssh/authorized_keys
else
  echo "WARN: ${ADMIN_KEY} not found on host — skipping SSH key injection"
fi

# 2) Wait for outbound networking inside the CT (max 30 s)
echo "Waiting for network inside CTID=${CTID}…"
for _ in $(seq 1 30); do
  if pct exec "${CTID}" -- bash -c 'getent hosts deb.debian.org >/dev/null 2>&1'; then
    break
  fi
  sleep 1
done

# 3) Install Beszel agent inside the LXC
echo "Installing Beszel agent inside CTID=${CTID}"
pct exec "${CTID}" -- bash -s <<'AGENT_INSTALL' || echo "WARN: Beszel install failed"
set -euo pipefail
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)   ARCH_TAG=amd64 ;;
  aarch64)  ARCH_TAG=arm64 ;;
  *) echo "Unsupported arch: $ARCH"; exit 1 ;;
esac
TMP=$(mktemp -d)
cd "$TMP"
curl -fsSL "https://github.com/henrygd/beszel/releases/latest/download/beszel-agent_linux_${ARCH_TAG}.tar.gz" \
  | tar -xz
install -m 0755 beszel-agent /usr/local/bin/beszel-agent

cat >/etc/systemd/system/beszel-agent.service <<UNIT
[Unit]
Description=Beszel Agent
After=network-online.target
Wants=network-online.target
[Service]
Environment="PORT=45876"
Environment="KEY=__KEY_PLACEHOLDER__"
ExecStart=/usr/local/bin/beszel-agent
Restart=always
[Install]
WantedBy=multi-user.target
UNIT
AGENT_INSTALL

# Inject the configured public key into the unit file (avoids quoting hell)
pct exec "${CTID}" -- sed -i "s|__KEY_PLACEHOLDER__|${BESZEL_AGENT_KEY}|" \
  /etc/systemd/system/beszel-agent.service

pct exec "${CTID}" -- systemctl daemon-reload
pct exec "${CTID}" -- systemctl enable --now beszel-agent.service ||
  echo "WARN: could not start beszel-agent"

# 4) Register an Uptime-Kuma push monitor (host-side, just sends one ping)
echo "Pinging Uptime-Kuma push monitor for ${HN}"
curl -fsS --max-time 5 \
  --get \
  --data-urlencode "status=up" \
  --data-urlencode "msg=created by community-scripts" \
  --data-urlencode "ping=1" \
  --data-urlencode "label=${HN}" \
  "${UPTIME_KUMA_PUSH_BASE}" >/dev/null ||
  echo "WARN: Uptime-Kuma push failed (non-fatal)"

echo "Provisioned monitoring for ${APP} (CTID=${CTID}, IP=${IP})"
# ▲▲▲ EXAMPLE 4 — END ▲▲▲

# ============================================================================
# ▼▼▼ EXAMPLE 5 — BEGIN ▼▼▼
# ----------------------------------------------------------------------------
#  Name        : per-app-router.sh
#  Purpose     : Single dispatcher hook that runs different actions
#                depending on the app being installed (NSAPP). Useful when
#                you want ONE hook for the whole cluster but distinct
#                behavior for, e.g., databases vs media services.
#  Difficulty  : ⭐⭐⭐ Advanced
# ============================================================================
#!/usr/bin/env bash
set -euo pipefail

# --- CONFIG (edit me) -------------------------------------------------------
DEFAULT_DNS_SUFFIX="lan"
PROM_FILE_SD_DIR="/etc/prometheus/file_sd" # on the host that runs Prometheus
# ----------------------------------------------------------------------------

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }

# ---------- shared helpers --------------------------------------------------
register_prometheus_target() {
  local job="$1" port="$2"
  local file="${PROM_FILE_SD_DIR}/${job}.json"
  mkdir -p "${PROM_FILE_SD_DIR}"
  if [[ ! -f "$file" ]]; then echo "[]" >"$file"; fi
  python3 - "$file" "${IP}:${port}" "${HN}" "${NSAPP}" <<'PY'
import json, sys
path, target, hn, app = sys.argv[1:5]
data = json.load(open(path))
# Avoid duplicates
data = [b for b in data if target not in b.get("targets", [])]
data.append({"targets": [target], "labels": {"hostname": hn, "app": app}})
json.dump(data, open(path, "w"), indent=2)
PY
  log "Registered Prometheus target ${IP}:${port} in ${file}"
}

set_ct_options() {
  local cores="$1" mem="$2" desc="$3"
  pct set "${CTID}" --cores "${cores}" --memory "${mem}" || true
  pct set "${CTID}" --description "${desc}" || true
}

# ---------- per-app dispatch ------------------------------------------------
log "Dispatching post-install for NSAPP=${NSAPP} CTID=${CTID}"

case "${NSAPP}" in

# ------ Databases ---------------------------------------------------------
postgresql | mariadb | mongodb | redis | valkey)
  log "Database role: bumping resources & adding to backup-critical pool"
  set_ct_options 4 4096 "DB: ${APP}"
  pvesh set /pools/db-critical --vms "${CTID}" 2>/dev/null || true
  register_prometheus_target "${NSAPP}-exporter" 9187
  ;;

# ------ *arr media stack --------------------------------------------------
sonarr | radarr | prowlarr | lidarr | readarr | bazarr)
  log "Media-arr role: tagging + Sonarr/Radarr API webhook"
  pct set "${CTID}" --tags "community-script;media;arr-stack" || true
  curl -fsS --max-time 5 -X POST \
    "http://media-hub.${DEFAULT_DNS_SUFFIX}/hooks/arr-added" \
    -H "Content-Type: application/json" \
    -d "{\"app\":\"${NSAPP}\",\"ctid\":${CTID},\"ip\":\"${IP}\"}" \
    >/dev/null || log "WARN: media-hub webhook failed"
  ;;

# ------ Web apps that should sit behind NPM/Traefik ----------------------
vaultwarden | paperless-ngx | nextcloud | immich | bookstack)
  log "Web app role: registering reverse-proxy entry"
  curl -fsS --max-time 5 -X POST \
    "http://traefik.${DEFAULT_DNS_SUFFIX}/api/dynamic-add" \
    -H "Content-Type: application/json" \
    -d "$(
      cat <<JSON
{
  "name": "${HN}",
  "host": "${HN}.${DEFAULT_DNS_SUFFIX}",
  "backend": "http://${IP}",
  "app": "${NSAPP}"
}
JSON
    )" >/dev/null || log "WARN: traefik registration failed"
  register_prometheus_target "blackbox-http" 80
  ;;

# ------ Default fallback --------------------------------------------------
*)
  log "No special handling for ${NSAPP} — applying generic defaults"
  register_prometheus_target "node-exporter" 9100
  ;;
esac

log "Finished dispatcher for ${APP} (CTID=${CTID})"
# ▲▲▲ EXAMPLE 5 — END ▲▲▲

# ============================================================================
#  END OF EXAMPLES
# ============================================================================
