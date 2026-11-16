#!/usr/bin/env bash
# Keeps one CI VM (pve-ci, incus-ci, ...) as a single-use GitHub runner host.
# Runs on the hypervisor (prox1), which PR code never touches.
#
# Every cycle:
#   1. roll the VM back to its clean snapshot and boot it;
#   2. register a just-in-time runner on it (generate-jitconfig) for the
#      host's repository. Such a runner takes exactly one job and is deleted
#      by GitHub afterwards, so its credentials are worthless once that job
#      is over;
#   3. (with several repositories in REPOS: as soon as one runner is busy,
#      delete the others that are still idle, so no second job starts on a
#      host that is about to be reset);
#   4. once every runner of this cycle is gone, start over at 1.
#
# PR code runs as root on the VM, so nothing the VM says is trusted: when a
# job is over is read from GitHub's API, never from the VM.
#
# Config: /etc/ci-controller/<vmid>.conf (or the environment), see below.
# Usage:  ci-vm-controller.sh <vmid>          run forever (the systemd unit)
#         ONE_CYCLE=1 ci-vm-controller.sh <vmid>   one job, then stop (testing)

set -euo pipefail

VMID=${1:?usage: ci-vm-controller.sh <vmid>}
CONF=${CONF:-/etc/ci-controller/$VMID.conf}
# shellcheck source=/dev/null
[[ -f "$CONF" ]] && . "$CONF"

: "${VM_IP:?VM_IP}"                       # address of the CI VM
: "${HOST_NAME:?HOST_NAME}"               # runner name prefix, e.g. pve-ci
: "${LABEL:?LABEL}"                       # proxmox-test or incus-test
# One repository per host. Several would each have a runner waiting on the
# VM, and a job of one could read the idle runner's JIT config of the other
# and use it elsewhere before it is withdrawn: one repository's PR code
# faking the other's results. (Several are fine within one trust domain.)
: "${REPOS:?REPOS, e.g. community-scripts/DevScripts}"
EXTRA_LABELS=${EXTRA_LABELS:-}            # space-separated, e.g. for a test
SNAPSHOT=${SNAPSHOT:-clean}
TOKEN_CMD=${TOKEN_CMD:-/usr/local/sbin/ci-gh-token}  # prints a token with repo Administration: write
PVE=${PVE:-}                              # prefix for qm, e.g. "ssh root@prox1" when not run on it
GUEST_SSH=${GUEST_SSH:-"ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new root@$VM_IP"}
POLL=${POLL:-20}
MAX_BUSY_MIN=${MAX_BUSY_MIN:-180}         # the test job's own limit is 90
MAX_IDLE_MIN=${MAX_IDLE_MIN:-720}         # recycle an idle host twice a day
ONE_CYCLE=${ONE_CYCLE:-}

log() { echo "[$(date -u +%FT%TZ)] vm $VMID: $*"; }
qm() { if [[ -n "$PVE" ]]; then $PVE qm "$@"; else command qm "$@"; fi; }

# Not in a subshell, so the status and the cached token survive the call:
# api METHOD PATH [JSON] -> body in $API_BODY, HTTP status in $API_STATUS.
API_FILE=$(mktemp)
trap 'rm -f "$API_FILE"' EXIT
TOKEN="" TOKEN_AT=0
api() {
  local method=$1 path=$2 data=${3:-}
  # Cached for 30 minutes (an App installation token lives 60).
  if [[ -z "$TOKEN" || $(($(date +%s) - TOKEN_AT)) -gt 1800 ]]; then
    TOKEN=$($TOKEN_CMD) || { log "no GitHub token"; API_STATUS=000 API_BODY=""; return 1; }
    TOKEN_AT=$(date +%s)
  fi
  API_STATUS=$(curl -sS -o "$API_FILE" -w '%{http_code}' -X "$method" \
    -H "Authorization: Bearer $TOKEN" -H 'Accept: application/vnd.github+json' \
    -H 'X-GitHub-Api-Version: 2022-11-28' ${data:+-d "$data"} "https://api.github.com$path") || API_STATUS=000
  API_BODY=$(<"$API_FILE")
  [[ "$API_STATUS" != 000 ]]
}

reset_vm() {
  log "rolling back to '$SNAPSHOT'"
  [[ "$(qm status "$VMID")" == *running* ]] && qm stop "$VMID" --timeout 60 >/dev/null
  qm rollback "$VMID" "$SNAPSHOT" >/dev/null
  qm start "$VMID" >/dev/null
  local i
  for i in $(seq 1 60); do
    $GUEST_SSH true 2>/dev/null && { log "booted"; return 0; }
    sleep 5
  done
  log "no SSH after 5 minutes"
  return 1
}

# Parallel arrays: one entry per runner registered in this cycle.
R_REPO=() R_ID=() R_GONE=()

register() { # register <owner/repo>
  local repo=$1 name dir labels body cfg id
  name="$HOST_NAME-${repo#*/}-$(date +%s)"
  dir=/opt/actions-runner/${repo#*/}
  labels=$(printf '%s\n' "$LABEL" $EXTRA_LABELS | jq -R . | jq -sc .)
  api POST "/repos/$repo/actions/runners/generate-jitconfig" \
    "$(jq -nc --arg n "$name" --argjson l "$labels" '{name: $n, runner_group_id: 1, labels: $l, work_folder: "_work"}')" || return 1
  body=$API_BODY
  [[ "$API_STATUS" == 201 ]] || { log "$repo: generate-jitconfig failed ($API_STATUS): $(jq -r .message <<<"$body" 2>/dev/null)"; return 1; }
  id=$(jq -r .runner.id <<<"$body")
  cfg=$(jq -r .encoded_jit_config <<<"$body")
  # The config goes in through stdin, not the command line.
  if ! $GUEST_SSH "umask 077; cat >/run/ci-jit-${repo#*/} && systemd-run --quiet --collect --unit=ci-jit-${repo#*/} \
      -p WorkingDirectory=$dir -E RUNNER_ALLOW_RUNASROOT=1 \
      /bin/sh -c 'cfg=\$(cat /run/ci-jit-${repo#*/}); rm -f /run/ci-jit-${repo#*/}; exec ./run.sh --jitconfig \"\$cfg\"'" <<<"$cfg"; then
    log "$repo: could not start the runner on the VM"
    api DELETE "/repos/$repo/actions/runners/$id" >/dev/null || true
    return 1
  fi
  R_REPO+=("$repo") R_ID+=("$id") R_GONE+=(0)
  log "$repo: runner $name (id $id) started"
}

drop() { # drop <index>: delete an idle runner; GitHub refuses a busy one
  local i=$1
  api DELETE "/repos/${R_REPO[$i]}/actions/runners/${R_ID[$i]}" >/dev/null || return 1
  if [[ "$API_STATUS" == 204 || "$API_STATUS" == 404 ]]; then R_GONE[$i]=1; return 0; fi
  return 1
}

watch_cycle() {
  local start busy_since="" i body status busy any_busy left offline_since=""
  start=$(date +%s)
  while :; do
    sleep "$POLL"
    any_busy=0 left=0 offline=0
    for i in "${!R_ID[@]}"; do
      [[ "${R_GONE[$i]}" == 1 ]] && continue
      api GET "/repos/${R_REPO[$i]}/actions/runners/${R_ID[$i]}" || { left=1; continue; }
      body=$API_BODY
      if [[ "$API_STATUS" == 404 ]]; then
        R_GONE[$i]=1
        log "${R_REPO[$i]}: runner ${R_ID[$i]} is gone (job done or removed)"
        continue
      fi
      left=1
      busy=$(jq -r .busy <<<"$body"); status=$(jq -r .status <<<"$body")
      [[ "$busy" == true ]] && any_busy=1
      [[ "$status" == offline ]] && offline=1
    done
    if [[ "$any_busy" == 1 && -z "$busy_since" ]]; then
      busy_since=$(date +%s)
      log "a job started; withdrawing the idle runners"
    fi
    # A host that has started a job takes no other one: it will be reset.
    if [[ -n "$busy_since" ]]; then
      for i in "${!R_ID[@]}"; do
        [[ "${R_GONE[$i]}" == 1 ]] && continue
        api GET "/repos/${R_REPO[$i]}/actions/runners/${R_ID[$i]}" || continue
        body=$API_BODY
        [[ "$API_STATUS" == 200 && "$(jq -r .busy <<<"$body")" == false ]] && drop "$i" &&
          log "${R_REPO[$i]}: idle runner ${R_ID[$i]} withdrawn"
      done
    fi
    [[ "$left" == 0 ]] && { log "cycle over"; return 0; }

    local now; now=$(date +%s)
    if [[ -n "$busy_since" && $((now - busy_since)) -gt $((MAX_BUSY_MIN * 60)) ]]; then
      log "job still running after $MAX_BUSY_MIN minutes; resetting anyway"
      break
    fi
    if [[ -z "$busy_since" && $((now - start)) -gt $((MAX_IDLE_MIN * 60)) ]]; then
      log "idle for $MAX_IDLE_MIN minutes; recycling"
      break
    fi
    # A runner that never comes online (or dies while idle) holds the host
    # forever otherwise.
    if [[ -z "$busy_since" && "$offline" == 1 ]]; then
      [[ -z "$offline_since" ]] && offline_since=$now
      if [[ $((now - offline_since)) -gt 300 ]]; then log "a runner is offline for 5 minutes; resetting"; break; fi
    else
      offline_since=""
    fi
  done
  for i in "${!R_ID[@]}"; do [[ "${R_GONE[$i]}" == 1 ]] || drop "$i" || true; done
}

# Registrations of this host that a stopped or crashed controller left behind:
# their VM was reset, so they are offline and never take a job, but they
# clutter the runner list. Busy or online ones are left alone.
cleanup_stale() {
  local repo ids id
  for repo in $REPOS; do
    api GET "/repos/$repo/actions/runners?per_page=100" || continue
    [[ "$API_STATUS" == 200 ]] || continue
    ids=$(jq -r --arg p "$HOST_NAME-${repo#*/}-" \
      '.runners[] | select((.name | startswith($p)) and .status == "offline" and (.busy | not)) | .id' <<<"$API_BODY")
    for id in $ids; do
      api DELETE "/repos/$repo/actions/runners/$id" && log "$repo: stale runner $id removed"
    done
  done
}

while :; do
  R_REPO=() R_ID=() R_GONE=()
  if reset_vm; then
    cleanup_stale
    ok=0
    for repo in $REPOS; do register "$repo" && ok=1 || true; done
    if [[ "$ok" == 1 ]]; then watch_cycle; else log "no runner could be registered"; sleep 60; fi
  else
    sleep 60
  fi
  [[ -n "$ONE_CYCLE" ]] && { log "ONE_CYCLE: stopping; the VM is left as the job left it"; break; }
done
