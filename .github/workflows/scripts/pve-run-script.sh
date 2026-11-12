#!/usr/bin/env bash
# Build one ct/ or vm/ script from a pull request on this test host, check
# that the container or VM really works, destroy it, and leave a result.json
# behind. The vm/ part lives in pve-run-vm.sh, sourced from here.
#
# PLATFORM says what this host is: pve (Proxmox VE, pct) or incus. The ct/
# scripts are the same for both; community-scripts/core picks its Incus
# backend by itself when it finds incus instead of pveversion. Only the way
# this harness reaches into the container differs (guest_* below).
#
# Runs on the self-hosted runner, which *is* the disposable test host. The
# harness comes from the default branch; only the script under test comes from
# the pull request, pinned to the commit a maintainer approved.
#
# The engine hardcodes raw.githubusercontent.com/<upstream>/main for every fetch
# (ct -> build.func -> install script -> install.func -> tools.func). Pointing it
# at a fork branch therefore means rewriting those URLs: the PR tree is unpacked
# under SERVE_ROOT, every upstream main URL in it is replaced by this host's own
# HTTP server, and the containers fetch from there. Engine changes in the PR are
# tested along with the script, which is what a reviewer wants anyway.

set -uo pipefail

: "${PR_REPO:?}" "${PR_SHA:?}" "${SCRIPT:?}" "${UPSTREAM:?}" "${CTID_BASE:?}" "${OUT_DIR:?}"
OS="${OS:-}"
PLATFORM="${PLATFORM:-pve}"
CTID_COUNT="${CTID_COUNT:-50}"
SERVE_ROOT="${SERVE_ROOT:-/srv/ci}"
# The containers' own network: vmbr1 + dnsmasq on Proxmox, incusbr0 on Incus.
if [[ "$PLATFORM" == "incus" ]]; then
  SERVE_URL="${SERVE_URL:-http://10.98.0.1:18080}"
  BRIDGE="${BRIDGE:-incusbr0}"
else
  SERVE_URL="${SERVE_URL:-http://10.99.0.1:18080}"
  BRIDGE="${BRIDGE:-vmbr1}"
fi
BUILD_TIMEOUT="${BUILD_TIMEOUT:-45m}"
URL_WAIT="${URL_WAIT:-120}"

# Every value below reaches a path, a URL or a command line.
[[ "$PR_REPO" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] || { echo "bad PR_REPO" >&2; exit 2; }
[[ "$UPSTREAM" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] || { echo "bad UPSTREAM" >&2; exit 2; }
[[ "$PR_SHA" =~ ^[0-9a-f]{40}$ ]] || { echo "bad PR_SHA" >&2; exit 2; }
[[ "$SCRIPT" =~ ^(ct|vm)/[A-Za-z0-9._-]+\.sh$ ]] || { echo "bad SCRIPT" >&2; exit 2; }
[[ -z "$OS" || "$OS" =~ ^(debian|ubuntu|alpine)$ ]] || { echo "bad OS" >&2; exit 2; }
[[ "$PLATFORM" =~ ^(pve|incus)$ ]] || { echo "bad PLATFORM" >&2; exit 2; }
# yes: build with var_arm64=yes. On arm64 the engine refuses to guess for a
# script that leaves var_arm64 unset; the ARM run builds those anyway, to see.
VAR_ARM64="${VAR_ARM64:-}"
[[ -z "$VAR_ARM64" || "$VAR_ARM64" == "yes" ]] || { echo "bad VAR_ARM64" >&2; exit 2; }
# upgrade: install the script as it is on the base branch (BASE_SHA of
# UPSTREAM), then update with the PR. That is what a user does who installed
# before the PR is merged and runs `update` after it. Empty: install and
# update both from the PR.
TEST_MODE="${TEST_MODE:-}"
[[ -z "$TEST_MODE" || "$TEST_MODE" == "upgrade" ]] || { echo "bad TEST_MODE" >&2; exit 2; }
if [[ -n "$TEST_MODE" ]]; then
  [[ "${BASE_SHA:-}" =~ ^[0-9a-f]{40}$ ]] || { echo "bad BASE_SHA" >&2; exit 2; }
  [[ "$SCRIPT" == ct/* ]] || { echo "upgrade tests are for ct/ scripts" >&2; exit 2; }
fi
[[ "$PLATFORM" == "pve" || "$SCRIPT" == ct/* ]] || { echo "vm/ scripts run on pve only" >&2; exit 2; }
[[ "$CTID_BASE" =~ ^[0-9]+$ ]] || { echo "bad CTID_BASE" >&2; exit 2; }

mkdir -p "$OUT_DIR"
RAW_LOG="$OUT_DIR/build.raw.log"
LOG="$OUT_DIR/build.log"
RESULT="$OUT_DIR/result.json"
INSTALL_LOG_OUT="$OUT_DIR/install.log"
UPDATE_RAW="$OUT_DIR/update.raw.log"
UPDATE_LOG="$OUT_DIR/update.log"
UPDATE_TIMEOUT="${UPDATE_TIMEOUT:-30m}"
UPDATE2_RAW="$OUT_DIR/update2.raw.log"
UPDATE2_LOG="$OUT_DIR/update2.log"
# How long the app has to keep running without a service restarting.
STABLE_WAIT="${STABLE_WAIT:-60}"

kind="${SCRIPT%%/*}" # ct or vm
app=$(basename "$SCRIPT" .sh)
job="${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-1}-${PLATFORM}-${kind}-${app}-${OS:-default}${TEST_MODE:+-$TEST_MODE}"
tree="$SERVE_ROOT/$job"
base="$SERVE_URL/$job"
src_tree="$tree" # what gets installed; the base branch's tree in an upgrade test
started=$(date +%s)

status="fail"
step=""
exit_code=""
ctid="" # the guest's ID (pve: 9000, incus: ci-9000), container or VM

# The container, whatever the platform. ctid is set once a slot is reserved.
guest_exec() {
  if [[ "$PLATFORM" == "incus" ]]; then incus exec "$ctid" -- "$@"; else pct exec "$ctid" -- "$@"; fi
}
guest_exists() {
  if [[ "$PLATFORM" == "incus" ]]; then incus info "$ctid" &>/dev/null; else pct status "$ctid" &>/dev/null; fi
}
guest_running() {
  if [[ "$PLATFORM" == "incus" ]]; then
    [[ "$(incus list "^${ctid}\$" -c s -f csv 2>/dev/null)" == "RUNNING" ]]
  else
    pct status "$ctid" 2>/dev/null | grep -q running
  fi
}
guest_destroy() {
  if [[ "$PLATFORM" == "incus" ]]; then
    incus delete "$ctid" --force &>/dev/null || true
  else
    pct stop "$ctid" --skiplock 1 &>/dev/null || true
    pct destroy "$ctid" --purge 1 --force 1 &>/dev/null || true
  fi
}
ct_ip=""
url=""
http_code=""
failed_units=""
# updated: a real update ran; no-update: update ran, nothing to update;
# fail: the update broke; empty: not attempted (the install failed).
update_status=""
update_step=""
# install: building and checking what was installed; update: from the first
# update on. In an upgrade test a failure while installing is the base
# branch's, not the PR's.
phase="install"
# Findings that do not fail the build, shown under the table on the PR.
notes=()
# Disk, RAM and OOM kills of the container, measured at the end.
resources=""
# Second `update` right after the first: no-update, updated-again, or empty.
update2_status=""

# Spinner frames: the engine redraws "⠋ Starting VM" a few times a second
# without a tty too. An alternation, not a bracket: these are multibyte and
# the runner's locale may be C.
SPINNER_RE='^\s*(⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏)'

strip_ansi() {
  sed -E 's/\x1B\[[0-9;?]*[A-Za-z]//g; s/\x1B[()][A-Z0-9]//g; s/\r/\n/g' | grep -vE '^\s*$' | grep -vE "$SPINNER_RE"
}

# The install script's own output: everything $STD hides from the build log.
# Both engines write it inside the container as /root/.install-<session>.log;
# dev_mode=keep makes sure a failed container is still there to read it from.
# If it is gone anyway, the copy the engine leaves on the host is the fallback.
collect_install_log() {
  [[ -n "$ctid" ]] || return 0
  # Exactly one build ran in this container, so the newest install log is ours.
  if guest_exists &&
    guest_exec sh -c 'cat "$(ls -t /root/.install-*.log 2>/dev/null | head -n1)"' 2>/dev/null |
    strip_ansi >"$INSTALL_LOG_OUT" && [[ -s "$INSTALL_LOG_OUT" ]]; then
    return 0
  fi
  [[ "$PLATFORM" == "pve" ]] || { rm -f "$INSTALL_LOG_OUT"; return 0; }
  # The engine names its host-side files after the session: pct_create_<ctid>_<date>_<session>.log
  local sid f
  sid=$(find /tmp -maxdepth 1 -name "pct_create_${ctid}_*.log" -newer "$RAW_LOG.start" -printf '%f\n' 2>/dev/null |
    sed -E 's/.*_([0-9a-f]+)\.log$/\1/' | head -n1)
  [[ -n "$sid" ]] || { rm -f "$INSTALL_LOG_OUT"; return 0; }
  for f in /tmp/*-"${ctid}"-"${sid}".log /var/log/community-scripts/install-"${sid}"-combined-*.log; do
    [[ -s "$f" ]] && { strip_ansi <"$f" >"$INSTALL_LOG_OUT"; return 0; }
  done
  rm -f "$INSTALL_LOG_OUT"
}

# "Requires AVX2" and friends: the script may be fine, the test host's CPU is
# not (Xeon E5-2650, Sandy Bridge: AVX, no AVX2). Shown as untestable rather
# than as a failure of the PR -- but the log is written by the code under test,
# so its word is not enough. Only the engine's error lines count, only when the
# build or install itself failed, and the feature they name must really be
# missing from this host's /proc/cpuinfo. Claiming a feature the host has
# changes nothing.
CPU_RE='(requir|need)[a-z]*[^.]{0,60}(AVX(2|-?512)?|SSE4[._]?2|x86-64-v[234])\b|\b(AVX(2|-?512)?|x86-64-v[234])\b[^.]{0,60}(not (supported|available)|does not have|is missing|unsupported)'

classify_cpu_failure() {
  local line feature flags
  line=$(strip_ansi <"$RAW_LOG" | grep -E '✖|\[ERROR\]' | grep -m1 -iE "$CPU_RE" |
    sed -E 's/^\s*(✖️?|\[[^]]*\]|\s)*//' | cut -c1-200)
  [[ -n "$line" ]] || return 0
  # The CPU flag that would have to be missing for the message to be true.
  case "${line,,}" in
  *avx-512* | *avx512* | *x86-64-v4*) feature=avx512f ;;
  *avx2* | *x86-64-v3*) feature=avx2 ;;
  *sse4.2* | *sse4_2* | *x86-64-v2*) feature=sse4_2 ;;
  *) return 0 ;;
  esac
  flags=" $(grep -m1 '^flags' /proc/cpuinfo | cut -d: -f2) "
  [[ "$flags" == *" ${feature} "* ]] && return 0
  status="unsupported"
  step="needs a newer CPU than the test host has (no ${feature}): ${line}"
}

# Disk used against var_disk, RAM in use at rest (anonymous memory, without
# the page cache that fills any limit) against the limit, and how often the
# kernel killed something for lack of memory, over the container's whole life,
# the build included. The size of a dir-backed Incus root is the host's, so
# then the script's var_disk is the size to compare with.
measure_resources() {
  local out disk_size disk_used anon limit oom want_disk want_ram line=()
  out=$(guest_exec sh -c 'df -Pm / | awk "NR==2 {print \$2, \$3}"
    awk "/^anon / {print int(\$2 / 1048576)}" /sys/fs/cgroup/memory.stat 2>/dev/null || echo -
    cat /sys/fs/cgroup/memory.max 2>/dev/null || echo -
    awk "/^oom_kill / {print \$2}" /sys/fs/cgroup/memory.events 2>/dev/null || echo -' 2>/dev/null) || return 0
  read -r disk_size disk_used <<<"$(sed -n 1p <<<"$out")"
  anon=$(sed -n 2p <<<"$out"); limit=$(sed -n 3p <<<"$out"); oom=$(sed -n 4p <<<"$out")
  want_disk=$(grep -m1 -oE 'var_disk="\$\{var_disk:-[0-9]+\}"' "$src_tree/$SCRIPT" | grep -oE '[0-9]+' | head -n1)
  want_ram=$(grep -m1 -oE 'var_ram="\$\{var_ram:-[0-9]+\}"' "$src_tree/$SCRIPT" | grep -oE '[0-9]+' | head -n1)
  [[ "$disk_size" =~ ^[0-9]+$ && "$disk_used" =~ ^[0-9]+$ ]] || return 0
  if [[ -n "$want_disk" ]] && ((disk_size > want_disk * 1024 * 3 / 2)); then disk_size=$((want_disk * 1024)); fi
  line+=("disk $(awk -v u="$disk_used" 'BEGIN {printf "%.1f", u / 1024}') of $(awk -v s="$disk_size" 'BEGIN {printf "%.0f", s / 1024}') GB")
  if ((disk_used * 100 >= disk_size * 90)); then
    notes+=("disk ${disk_used} of ${disk_size} MB used after the install: var_disk may be too small")
  fi
  [[ "$limit" =~ ^[0-9]+$ ]] && limit=$((limit / 1048576)) || limit="${want_ram:-}"
  if [[ "$anon" =~ ^[0-9]+$ ]]; then
    line+=("RAM at rest ${anon}${limit:+ of ${limit}} MB")
    if [[ "$limit" =~ ^[0-9]+$ ]] && ((anon * 100 >= limit * 80)); then
      notes+=("${anon} of ${limit} MB RAM in use at rest: var_ram may be too small")
    fi
  fi
  if [[ "$oom" =~ ^[0-9]+$ ]]; then
    line+=("OOM kills ${oom}")
    ((oom > 0)) && notes+=("the kernel killed ${oom} process(es) for lack of memory: var_ram is too small for the build or the app")
  fi
  resources=$(
    IFS='|'
    echo "${line[*]}"
  )
  resources=${resources//|/ · }
}

finish() {
  [[ -f "$RAW_LOG" ]] && strip_ansi <"$RAW_LOG" >"$LOG"
  [[ -f "$RAW_LOG" ]] && collect_install_log
  [[ -f "$UPDATE_RAW" ]] && strip_ansi <"$UPDATE_RAW" >"$UPDATE_LOG"
  [[ -f "$UPDATE2_RAW" ]] && strip_ansi <"$UPDATE2_RAW" >"$UPDATE2_LOG"
  rm -f "$UPDATE_RAW" "$UPDATE2_RAW"
  [[ "$kind" == ct && -n "$ctid" && -z "$resources" ]] && guest_running && measure_resources
  jq -n \
    --arg script "$SCRIPT" --arg kind "$kind" --arg platform "$PLATFORM" --arg os "${OS:-default}" --arg status "$status" \
    --arg mode "$TEST_MODE" --arg resources "$resources" --arg update2_status "$update2_status" \
    --arg notes "$(printf '%s\n' "${notes[@]}")" \
    --arg step "$step" --arg exit_code "$exit_code" --arg sha "$PR_SHA" \
    --arg ctid "$ctid" --arg url "$url" --arg http_code "$http_code" \
    --arg failed_units "$failed_units" --arg ip "$ct_ip" --arg arch "$(uname -m)" \
    --arg update_status "$update_status" --arg update_step "$update_step" \
    --argjson duration "$(($(date +%s) - started))" \
    --arg tail "$([[ -f "$LOG" ]] && tail -n 60 "$LOG")" \
    '{script: $script, kind: $kind, platform: $platform, arch: $arch, os: $os, status: $status, step: $step, exit_code: $exit_code,
      sha: $sha, ctid: $ctid, ip: $ip, url: $url, http_code: $http_code,
      failed_units: $failed_units, update_status: $update_status, update_step: $update_step,
      mode: $mode, resources: $resources, update2_status: $update2_status,
      notes: ($notes | split("\n") | map(select(. != ""))),
      duration: $duration, log_tail: $tail}' >"$RESULT"
  echo "::group::result"
  jq 'del(.log_tail)' "$RESULT"
  echo "::endgroup::"
}

# --- Live output ------------------------------------------------------------------
# The job log on GitHub streams while the job runs, so mirroring the build there
# is all "live" takes. Two streams: the engine's own output, and the install
# log inside the container, which holds everything $STD hides (apt, npm, ...).
#
# Both are written by the code under test. A line starting with `::` would be
# read by the runner as a workflow command, so command processing is switched
# off for as long as they run, with a token the build cannot know.
stream_token=""
log_pid=""
install_pid=""

# Colours stay, cursor movement and spinner redraws go.
live_filter() {
  sed -u -E 's/\r/\n/g; s/\x1B\[[0-9;?]*[ABCDEFGHJKSTfhilnsu]//g' | sed -u -E "/^\s*\$/d; /${SPINNER_RE}/d"
}

start_streams() {
  stream_token=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')
  echo "::stop-commands::${stream_token}"
  tail -n +1 -F --pid="$build_pid" "$RAW_LOG" 2>/dev/null > >(live_filter) &
  log_pid=$!
  # A VM has no install log to follow: its script runs on this host only.
  [[ "$kind" == "ct" ]] || return 0
  # setsid: its own process group, so stop_streams can take down the
  # pct/incus exec + tail pair inside it in one go.
  setsid bash -c '
    gx() { if [ "$2" = incus ]; then incus exec "$1" -- "${@:3}"; else pct exec "$1" -- "${@:3}"; fi; }
    for _ in $(seq 1 900); do
      f=$(gx "$1" "$2" sh -c "ls -t /root/.install-*.log 2>/dev/null | head -n1" 2>/dev/null)
      if [ -n "$f" ]; then
        echo "──────── install log of CT $1 (live) ────────"
        if [ "$2" = incus ]; then exec incus exec "$1" -- tail -n +1 -F "$f"; fi
        exec pct exec "$1" -- tail -n +1 -F "$f"
      fi
      sleep 2
    done' _ "$ctid" "$PLATFORM" 2>/dev/null > >(live_filter | sed -u 's/^/  │ /') &
  install_pid=$!
}

stop_streams() {
  [[ -n "$stream_token" ]] || return 0
  [[ -n "$install_pid" ]] && kill -TERM -- "-$install_pid" &>/dev/null
  [[ -n "$log_pid" ]] && kill -TERM "$log_pid" &>/dev/null
  wait "$log_pid" "$install_pid" &>/dev/null
  sleep 1 # let the filters flush
  install_pid=""
  log_pid=""
  echo "::${stream_token}::"
  stream_token=""
}

build_pid=""
update_pid=""
cleanup() {
  stop_streams
  local pid
  for pid in "$build_pid" "$update_pid"; do
    [[ -n "$pid" ]] || continue
    pkill -TERM -P "$pid" &>/dev/null || true
    kill -TERM "$pid" &>/dev/null || true
    sleep 2
  done
  if [[ -n "$ctid" && "$kind" == "vm" ]]; then
    vm_cleanup
  elif [[ -n "$ctid" ]]; then
    guest_exists && guest_destroy
    rm -f "/run/ci-jobs/$ctid"
    # What the engine leaves on the host for this container and its session.
    local f sid
    [[ "$PLATFORM" == "pve" ]] && for f in /tmp/pct_create_"${ctid}"_*.log; do
      [[ -f "$f" && "$f" -nt "$RAW_LOG.start" ]] || continue
      sid=$(sed -E 's/.*_([0-9a-f]+)\.log$/\1/' <<<"$f")
      rm -f -- "$f" /tmp/create-lxc-"${sid}".log /tmp/*-"${ctid}"-"${sid}".log
    done
  fi
  rm -f "$RAW_LOG.start"
  rm -rf -- "$tree" "$tree-base"
}
trap cleanup EXIT
# A cancelled job sends TERM; without this the EXIT trap would not run.
trap 'exit 143' TERM
trap 'exit 130' INT

# fail <reason> [fail|unsupported]: only the build/install branches pass the
# second argument, after classify_cpu_failure has checked the host.
#
# The exit code says whether *this job* worked, not whether the app did. A
# script that fails to build is a result: it is written down, reported on the
# PR (check, comment, review) and the job exits 0 -- a red run per broken app
# would only be notification noise. Only trouble with the test setup itself
# (setup_error) fails the job, because that is ours to look at.
fail() {
  step="$1"
  status="${2:-fail}"
  [[ "$status" == "unsupported" ]] || status="fail"
  if [[ "$TEST_MODE" == "upgrade" && "$phase" == "install" && "$status" == "fail" ]]; then
    status="error"
    step="the install before this PR (${UPSTREAM}@${BASE_SHA:0:7}) failed, so the upgrade was not tested: $1"
  fi
  finish
  echo "::warning title=${SCRIPT}::${step}"
  exit 0
}

setup_error() {
  step="$1"
  status="error"
  finish
  echo "::error title=${SCRIPT}::test setup: ${step}"
  exit 1
}

# --- Reserve a container ID ---------------------------------------------------
# A lock file per ID, not just "first free one", because the engine only creates
# the container minutes later and two jobs would otherwise pick the same ID.
# VMs take the range 100 above the containers' (DevScripts 9100-9149,
# ProxmoxVE 9150-9199).
mkdir -p /run/ci-jobs
if [[ "$kind" == "vm" ]]; then
  source "$(dirname "$0")/pve-run-vm.sh"
  CTID_BASE=$((CTID_BASE + 100))
  vm_wait_turn
fi
exec 9>/run/ci-jobs/.lock
flock 9
# On Incus the ID is an instance name: var_ctid=ci-9000 names the container.
for ((id = CTID_BASE; id < CTID_BASE + CTID_COUNT; id++)); do
  name=$id
  [[ "$PLATFORM" == "incus" ]] && name="ci-$id"
  [[ -e "/run/ci-jobs/$name" ]] && continue
  if [[ "$PLATFORM" == "incus" ]]; then
    incus info "$name" &>/dev/null && continue
  else
    pvesh get /cluster/nextid --vmid "$id" &>/dev/null || continue
  fi
  echo "$job" >"/run/ci-jobs/$name"
  ctid=$name
  break
done
flock -u 9
exec 9>&-
[[ -n "$ctid" ]] || setup_error "no free ${kind} ID in ${CTID_BASE}-$((CTID_BASE + CTID_COUNT - 1))"

# --- Fetch the approved commit and point it at ourselves ------------------------
mkdir -p "$tree"
curl -fsSL --retry 3 "https://codeload.github.com/${PR_REPO}/tar.gz/${PR_SHA}" |
  tar -xz -C "$tree" --strip-components=1 || setup_error "could not download ${PR_REPO}@${PR_SHA:0:7}"
[[ -f "$tree/$SCRIPT" ]] || fail "${SCRIPT} does not exist at ${PR_SHA:0:7}"

upstream_re="https://raw\.githubusercontent\.com/${UPSTREAM//./\\.}/(refs/heads/)?main"
grep -rlE "$upstream_re" "$tree" --include='*.sh' --include='*.func' |
  xargs -r sed -i -E "s#${upstream_re}#${base}#g"

# What gets installed: the PR, or in an upgrade test the base branch.
src_tree="$tree"
src_base="$base"
if [[ "$TEST_MODE" == "upgrade" ]]; then
  src_tree="$tree-base"
  src_base="$base-base"
  mkdir -p "$src_tree"
  curl -fsSL --retry 3 "https://codeload.github.com/${UPSTREAM}/tar.gz/${BASE_SHA}" |
    tar -xz -C "$src_tree" --strip-components=1 || setup_error "could not download ${UPSTREAM}@${BASE_SHA:0:7}"
  [[ -f "$src_tree/$SCRIPT" ]] || fail "${SCRIPT} does not exist at ${UPSTREAM}@${BASE_SHA:0:7}"
  grep -rlE "$upstream_re" "$src_tree" --include='*.sh' --include='*.func' |
    xargs -r sed -i -E "s#${upstream_re}#${src_base}#g"
fi

if [[ "$kind" == "vm" ]]; then
  vm_build_and_check
  exit 0
fi

# --- Build ----------------------------------------------------------------------
if [[ "$TEST_MODE" == "upgrade" ]]; then
  echo "Upgrade test: installing ${SCRIPT} from ${UPSTREAM}@${BASE_SHA:0:7} (before this PR), then updating with ${PR_REPO}@${PR_SHA:0:7}"
fi
echo "Building ${SCRIPT} (${OS:-default OS}) on ${PLATFORM} as CT ${ctid} from $([[ "$TEST_MODE" == upgrade ]] && echo "${UPSTREAM}@${BASE_SHA:0:7}" || echo "${PR_REPO}@${PR_SHA:0:7}")"
hostname_safe="ci-$(tr -c 'a-z0-9-\n' '-' <<<"${app,,}" | cut -c1-50)"
build_env=(
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  HOME=/root TERM=dumb LANG=C.UTF-8
  mode=default MODE=default PHS_SILENT=1 DIAGNOSTICS=no
  var_ctid="$ctid" var_hostname="$hostname_safe" var_brg="$BRIDGE"
  "dev_mode=timing,keep" COMMUNITY_SCRIPTS_URL="$src_base"
)
if [[ "$PLATFORM" == "incus" ]]; then
  build_env+=(var_container_storage=default)
else
  build_env+=(var_container_storage=local var_template_storage=local)
fi
touch "$RAW_LOG.start"
[[ -n "$OS" ]] && build_env+=(var_os="$OS")
[[ -n "$VAR_ARM64" ]] && build_env+=(var_arm64=yes)
# Both engines turn var_github_token into GITHUB_TOKEN inside the container.
[[ -n "${GH_API_TOKEN:-}" ]] && build_env+=(var_github_token="$GH_API_TOKEN")

# --- Answers for the script's questions ------------------------------------------
# Nobody types into CI, so anything the install asks has to be answered up front.
# AGENTS.md rule 24: a script reads var_<x> first and prompts only when it is
# unset (or uses prompt_input_required ... "var_x"). Every such variable gets a
# CI value here. The names come from json/<app>.json app_vars (DevScripts) and
# from the read/prompt_ lines of the install script (both repos). A bare `read`
# that ignores its variable still fails, and the report says why.
ENGINE_VARS=" var_ctid var_hostname var_os var_version var_cpu var_ram var_disk var_brg var_net var_container_storage var_template_storage var_unprivileged var_tags var_arm64 var_testurl var_verbose var_timezone var_http_proxy var_http_no_proxy var_appversion var_github_token "
host_app=$(tr -c 'a-z0-9-\n' '-' <<<"${app,,}")
ci_value() {
  case "${1,,}" in
  *pass* | *secret* | *token* | *key*) head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | cut -c1-20 ;;
  *email* | *mail*) echo "ci@example.test" ;;
  *url* | *endpoint*) echo "https://ci-${host_app}.example.test" ;;
  # One name per variable: var_opencloud_collabora_fqdn ->
  # ci-opencloud-collabora.example.test, so several of them cannot collide.
  *host* | *domain* | *fqdn*)
    local part="${1#var_}"
    part=$(sed -E 's/_?(fqdn|hostname|host|domain)$//' <<<"${part,,}" | tr '_' '-')
    echo "ci-${part:-$host_app}.example.test"
    ;;
  *user*) echo "ciadmin" ;;
  *) echo "ci-test" ;;
  esac
}
declare -A answers=()
json="$src_tree/json/${app}.json"
if [[ -f "$json" ]]; then
  while IFS=$'\t' read -r name default; do
    answers[$name]="$default"
  done < <(jq -r '(if type == "array" then .[0] else . end).app_vars // [] | .[] |
    select(.name | test("^var_[a-z0-9_]{1,40}$")) | [.name, (.default // "" | tostring)] | @tsv' "$json" 2>/dev/null)
fi
# Names built at run time from a loop, e.g. OpenCloud:
#   servers=("opencloud" "collabora" "wopi")
#   for server in "${servers[@]}"; do fqdn_var="var_opencloud_${server}_fqdn"
# Each var_...${x}... template is expanded with the words of `for x in ...`
# (or of the array that loop walks). Nothing is executed, only read.
expand_templates() {
  local tpl x pre suf words arr w
  while read -r tpl; do
    x=$(sed -E 's/^[^$]*\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?.*$/\1/' <<<"$tpl")
    pre="${tpl%%\$*}"
    suf=$(sed -E 's/^[^$]*\$\{?[A-Za-z_][A-Za-z0-9_]*\}?//' <<<"$tpl")
    words=$(grep -m1 -oE "for ${x} in [^;]*" "$1" | sed -E "s/^for ${x} in //")
    if [[ "$words" =~ \$\{([A-Za-z_][A-Za-z0-9_]*)\[@\]\} ]]; then
      arr="${BASH_REMATCH[1]}"
      words=$(grep -m1 -oE "^\s*${arr}=\([^)]*\)" "$1" | sed -E "s/^\s*${arr}=\(//; s/\)$//")
    fi
    for w in $words; do
      w="${w//[\"\']/}"
      [[ "${pre}${w}${suf}" =~ ^var_[a-z0-9_]{1,40}$ ]] && echo "${pre}${w}${suf}"
    done
  done < <(grep -oE 'var_[a-z0-9_]*\$\{?[A-Za-z_][A-Za-z0-9_]*\}?[a-z0-9_]*' "$1" | sort -u)
}

# The engine names the install script after APP (lower case, no spaces), which
# need not match the ct/ file name: ct/bluesky-pds.sh -> blueskypds-install.sh.
nsapp=$(grep -m1 -oE '^APP="[^"]+"' "$src_tree/$SCRIPT" | cut -d'"' -f2 | tr -d ' ' | tr '[:upper:]' '[:lower:]')
for f in "$src_tree/install/${app}-install.sh" "$src_tree/install/${nsapp}-install.sh" "$src_tree/$SCRIPT"; do
  [[ -f "$f" ]] || continue
  while read -r name; do
    [[ -v "answers[$name]" ]] || answers[$name]=""
  done < <({
    grep -E '\bread\b|prompt_(input|input_required|confirm|select|password)\b' "$f" | grep -oE '\bvar_[a-z0-9_]{1,40}\b'
    expand_templates "$f"
  } | sort -u)
done
for name in "${!answers[@]}"; do
  [[ "$ENGINE_VARS" == *" $name "* ]] && continue
  value="${answers[$name]}"
  [[ -n "$value" ]] || value=$(ci_value "$name")
  build_env+=("$name=$value")
  case "${name,,}" in
  *pass* | *secret* | *token* | *key*) echo "Pre-answered ${name}=(random)" ;;
  *) echo "Pre-answered ${name}=${value}" ;;
  esac
done

# In the background so that a TERM from a cancelled job is handled at once:
# bash defers traps until a foreground command returns.
env -i "${build_env[@]}" timeout --kill-after=1m "$BUILD_TIMEOUT" \
  bash -c 'bash -c "$(curl -fsSL "$1")"' _ "$src_base/$SCRIPT" </dev/null >"$RAW_LOG" 2>&1 &
build_pid=$!
start_streams
wait "$build_pid"
exit_code=$?
build_pid=""
stop_streams

if ((exit_code == 124 || exit_code == 137)); then
  fail "build timed out after ${BUILD_TIMEOUT}"
fi
# The engine marks the step that broke with a cross. Its closing "Installation
# failed in container" line is generic, so the cross before it is the useful one.
failure_line() {
  local line
  line=$(strip_ansi <"$RAW_LOG" | grep -E '✖|\[ERROR\]|error:' | grep -v 'Installation failed in container' |
    tail -n 1 | sed -E 's/^\s*(✖️?|\s)*//' | cut -c1-200)
  # A prompt nobody can answer: say what to do instead.
  # First, because the report keeps 200 characters.
  if [[ "$line" == *"read exited with status"* || "$line" == *"executing command read "* ]]; then
    local asked
    asked=$(grep -oE '\bvar_[a-z0-9_]{1,40}\b' <<<"$line" | tail -n 1)
    line="unanswerable prompt (AGENTS.md rule 24): ask only when ${asked:-var_<x>} is unset, or use prompt_input_required. ${line}"
  fi
  echo "$line"
}
if ((exit_code != 0)); then
  last=$(failure_line)
  step="build exited ${exit_code}${last:+: $last}"
  status="fail"
  classify_cpu_failure
  fail "$step" "$status"
fi
# With dev_mode=keep (needed to read the install log) the engine carries on
# after a failed install and still prints "Completed Successfully", exit 0.
install_exit=$(strip_ansi <"$RAW_LOG" | grep -oE 'Installation failed in container [0-9]+ \(exit code: [0-9]+\)' |
  grep -oE '[0-9]+\)$' | tr -d ')' | tail -n 1)
if [[ -n "$install_exit" ]]; then
  last=$(failure_line)
  step="install script exited ${install_exit}${last:+: $last}"
  status="fail"
  classify_cpu_failure
  fail "$step" "$status"
fi
grep -qi 'completed successfully' "$RAW_LOG" || fail "build exited 0 but never reported success"

# --- Checks ---------------------------------------------------------------------
guest_running || fail "container ${ctid} is not running"

ct_ip=$(guest_exec sh -c "ip -4 -o addr show dev eth0 | awk '{print \$4}' | cut -d/ -f1" 2>/dev/null | head -n1)

# What the app's page looks like, for the PR comment. Chromium runs as its own
# unprivileged user with its sandbox on: the page is served by code under test.
# ci-shot-firewall (pve-ci-host-setup.sh) keeps that user off this host and the
# lab network; without it there is no screenshot rather than an unguarded one.
# $1: file name in OUT_DIR (screenshot.png after install, -update after update).
take_screenshot() {
  command -v chromium >/dev/null && id ci-shot &>/dev/null || return 0
  iptables -w -S CI_SHOT 2>/dev/null | grep -q -- '-d 10.0.0.0/8 .*REJECT' || return 0
  local dir
  dir=$(mktemp -d)
  chown ci-shot "$dir"
  # HOME: runuser keeps root's, which ci-shot cannot write; Playwright's
  # Chromium (the ARM runner) then crashes in its crash handler.
  runuser -u ci-shot -- env HOME="$dir" timeout 60 chromium --headless=new --disable-gpu --hide-scrollbars \
    --ignore-certificate-errors --no-first-run --window-size=1280,800 --virtual-time-budget=10000 \
    --user-data-dir="$dir/profile" --screenshot="$dir/shot.png" "$url" &>/dev/null
  # Only a plausible PNG leaves this function.
  if [[ -s "$dir/shot.png" && $(stat -c %s "$dir/shot.png") -lt 3000000 ]] &&
    [[ "$(head -c 8 "$dir/shot.png" | od -An -tx1 | tr -d ' \n')" == "89504e470d0a1a0a" ]]; then
    cp "$dir/shot.png" "$OUT_DIR/${1:-screenshot.png}"
  fi
  rm -rf -- "$dir"
}

# Is the app up? No failed services, and the URL the script tells the user to
# open, e.g. http://${IP}:1337/admin, answers 200 (after redirects, so a jump
# to /login is fine). A script that prints no URL has no web UI to check.
# Run after the install and again after the update. Sets health_problem.
app_url() { # the URL the script at $1 tells the user to open
  local pattern
  pattern=$(grep -oE 'https?://\$\{IP\}(:[0-9]+)?(/[A-Za-z0-9._~/?=&%-]*)?' "$1" | head -n1)
  [[ -n "$pattern" && -n "$ct_ip" ]] && echo "${pattern/\$\{IP\}/$ct_ip}"
}
url=$(app_url "$src_tree/$SCRIPT")
health_problem=""
check_health() {
  health_problem=""
  failed_units=""
  if guest_exec sh -c 'command -v systemctl' &>/dev/null; then
    sleep 10
    failed_units=$(guest_exec systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}' | paste -sd, -)
  elif guest_exec sh -c 'command -v rc-status' &>/dev/null; then
    failed_units=$(guest_exec rc-status --crashed 2>/dev/null | awk '{print $1}' | paste -sd, -)
  fi
  [[ -z "$failed_units" ]] || { health_problem="failed services: ${failed_units}"; return 1; }
  [[ -n "$url" ]] || return 0
  local waited
  for ((waited = 0; waited < URL_WAIT; waited += 5)); do
    http_code=$(curl -sk -L --max-redirs 5 -o /dev/null -w '%{http_code}' --max-time 10 "$url" || true)
    [[ "$http_code" =~ ^2[0-9][0-9]$ ]] && break
    sleep 5
  done
  # Also when the check fails: an error page explains more than a status code.
  [[ "$http_code" =~ ^[1-5][0-9][0-9]$ ]] && take_screenshot "$1"
  [[ "$http_code" =~ ^2[0-9][0-9]$ ]] ||
    { health_problem="${url} answered ${http_code/#000/nothing} instead of 200 within ${URL_WAIT}s"; return 1; }
}

check_health screenshot.png || fail "$health_problem"

# --- Update -------------------------------------------------------------------------
# A fresh install is already on the latest release, so a plain `update` would
# only say "No update available" and never run update_script's real path. The
# version files the install wrote (~/.<app>, one per fetch_and_deploy_gh_release)
# that update_script checks are set back to 0.0.0-ci first; check_for_gh_release then sees an update and
# runs it all. Apps deployed from a branch (fetch_and_deploy_gh_branch, checked
# with check_for_gh_branch) store a commit hash instead of a version; the
# engine compares both as plain strings, so 0.0.0-ci works for them too. `update` is the /usr/bin/update the install generated: it pulls
# ct/<app>.sh from the URL this container was built from, i.e. the PR's tree.
UPDATE_FAKE="0.0.0-ci"
update_fail() {
  update_status="fail"
  update_step="$1"
  fail "update: $1"
}

version_files=$(guest_exec sh -c '
  for f in /root/.*; do
    [ -f "$f" ] || continue
    case "$f" in */.install-* | *.pending | *.bak | */.bash* | */.profile | */.hushlogin | */.viminfo | */.lesshst | */.wget-hsts | */.selected_editor) continue ;; esac
    [ "$(wc -l <"$f")" -le 1 ] && grep -qE "^(v?[0-9]+(\.[0-9A-Za-z_+-]+)+|[0-9a-f]{7,40})$" "$f" && echo "$f"
  done' 2>/dev/null | grep -E '^/root/\.[A-Za-z0-9._-]+$')
# Only set back what update_script checks: the names it passes to
# check_for_*release. The install can also deploy helpers the update never
# touches (immich: ~/.mise); those would stay 0.0.0-ci and fail the run. A
# name that is a variable can't be read here, so then all of them are set back.
tracked=$(grep -oE 'check_for_[a-z]*_?release[[:space:]]+("[^"]*"|[^[:space:]]+)' "$tree/$SCRIPT" |
  sed -E 's/^check_for_[a-z]*_?release[[:space:]]+//; s/^"(.*)"$/\1/' | tr -d ' ' | tr '[:upper:]' '[:lower:]' | sort -u)
if [[ -n "$tracked" && "$tracked" != *'$'* ]]; then
  version_files=$(grep -xF -f <(sed 's|^|/root/.|' <<<"$tracked") <<<"$version_files" || true)
fi
for f in $version_files; do
  guest_exec sh -c "echo '$UPDATE_FAKE' > '$f'; rm -f '$f.pending'" ||
    update_fail "could not reset $f"
done
[[ -n "$version_files" ]] && echo "Update test: set back $(tr '\n' ' ' <<<"$version_files")to ${UPDATE_FAKE}"

phase="update"
# Upgrade test: the container pulls its update from where it was installed
# from (COMMUNITY_SCRIPTS_URL in /usr/bin/update); point that at the PR, as
# merging it would.
if [[ "$TEST_MODE" == "upgrade" ]]; then
  guest_exec sed -i -E "s#^export COMMUNITY_SCRIPTS_URL=.*#export COMMUNITY_SCRIPTS_URL=\"${base}\"#" /usr/bin/update &&
    guest_exec grep -qxF "export COMMUNITY_SCRIPTS_URL=\"${base}\"" /usr/bin/update ||
    setup_error "could not point /usr/bin/update at the PR"
  echo "Upgrade test: /usr/bin/update now pulls from ${PR_REPO}@${PR_SHA:0:7}"
fi

# run_update <raw log> <title>: runs `update` in the container, live in the
# job log; sets update_rc.
run_update() {
  local raw=$1 token
  : >"$raw"
  token=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')
  echo "──────── $2 (live) ────────"
  echo "::stop-commands::${token}"
  # timeout runs a program, not a shell function, so spell out the exec here.
  if [[ "$PLATFORM" == "incus" ]]; then guest_cmd=(incus exec "$ctid" --); else guest_cmd=(pct exec "$ctid" --); fi
  timeout --kill-after=1m "$UPDATE_TIMEOUT" "${guest_cmd[@]}" env PHS_SILENT=1 mode=default MODE=default \
    TERM=dumb DIAGNOSTICS=no var_ignore_breaking_changes=yes ${GH_API_TOKEN:+GITHUB_TOKEN="$GH_API_TOKEN"} update </dev/null \
    > >(tee "$raw" | live_filter) 2>&1 &
  update_pid=$!
  wait "$update_pid"
  update_rc=$?
  update_pid=""
  sleep 1
  echo "::${token}::"
}
run_update "$UPDATE_RAW" "update test"

update_failure_line() {
  strip_ansi <"${1:-$UPDATE_RAW}" | grep -E '✖|\[ERROR\]|error:' | tail -n 1 | sed -E 's/^\s*(✖️?|\s)*//' | cut -c1-180
}
if ((update_rc == 124 || update_rc == 137)); then
  update_fail "timed out after ${UPDATE_TIMEOUT}"
elif ((update_rc != 0)); then
  last=$(update_failure_line)
  update_fail "exited ${update_rc}${last:+: $last}"
fi
# The engine can report an error and still exit 0 (bark-server: "github: rate
# limit reached", then "Cleaned"). A rate limit is ours, not the PR's: the
# update could not be tested. Any other error line is a failed update.
update_error=$(strip_ansi <"$UPDATE_RAW" | grep -E '✖|\[ERROR\]' | tail -n 1 | sed -E 's/^\s*(✖️?|\s)*//' | cut -c1-180)
if [[ -n "$update_error" ]]; then
  if [[ "${update_error,,}" == *"rate limit"* ]]; then
    update_status="error"
    update_step="could not be tested: ${update_error}"
    status="pass"
    finish
    exit 0
  fi
  update_fail "$update_error"
fi
if strip_ansi <"$UPDATE_RAW" | grep -qi 'updated successfully'; then
  update_status="updated"
  for f in $version_files; do
    [[ "$(guest_exec cat "$f" 2>/dev/null)" != "$UPDATE_FAKE" ]] ||
      update_fail "reported success, but $f is still ${UPDATE_FAKE}"
  done
else
  # Ran cleanly without updating anything: no version file to fake (apt/npm
  # based), or an update_script that decides differently. Not a failure.
  update_status="no-update"
  update_step=$(strip_ansi <"$UPDATE_RAW" | grep -iE 'no update|up to date|up-to-date|already' | tail -n 1 | sed -E 's/^\s*(✔️?|ℹ️?|\s)*//' | cut -c1-160)
fi

url=$(app_url "$tree/$SCRIPT")
check_health screenshot-update.png || update_fail "after the update: $health_problem"

# --- Second update ------------------------------------------------------------------
# Right after an update, `update` has nothing to do: it must say so and leave
# the app alone. One that breaks on a second run breaks for every user on
# their next update; one that updates again although nothing changed
# rebuilds on every run (often a version file it never writes).
if [[ "$update_status" == "updated" ]]; then
  run_update "$UPDATE2_RAW" "second update (must have nothing to do)"
  if ((update_rc == 124 || update_rc == 137)); then
    update_fail "second run timed out after ${UPDATE_TIMEOUT}"
  elif ((update_rc != 0)); then
    last=$(update_failure_line "$UPDATE2_RAW")
    update_fail "second run exited ${update_rc}${last:+: $last}"
  fi
  update_error=$(strip_ansi <"$UPDATE2_RAW" | grep -E '✖|\[ERROR\]' | tail -n 1 | sed -E 's/^\s*(✖️?|\s)*//' | cut -c1-180)
  if [[ -n "$update_error" && "${update_error,,}" != *"rate limit"* ]]; then
    update_fail "second run: $update_error"
  fi
  if strip_ansi <"$UPDATE2_RAW" | grep -qi 'updated successfully'; then
    update2_status="updated-again"
    notes+=("a second \`update\` right after the first updated again: update_script does not notice it is current (e.g. a version file it never writes)")
  else
    update2_status="no-update"
  fi
  check_health screenshot-update.png || update_fail "after the second update: $health_problem"
fi

# --- Does it stay up? -----------------------------------------------------------
# A service that crash-loops can be "active" at every single look. Count the
# restarts of every service (and Docker container) over STABLE_WAIT seconds:
# any that went up was restarted while nobody touched the container.
restart_counts() {
  guest_exec sh -c '
    if command -v systemctl >/dev/null; then
      systemctl list-units --type=service --all --no-legend --plain | awk "{print \$1}" |
        while read -r u; do echo "$u $(systemctl show -p NRestarts --value "$u" 2>/dev/null)"; done
    fi
    if command -v docker >/dev/null; then
      docker ps -aq | xargs -r docker inspect -f "docker:{{.Name}} {{.RestartCount}}" 2>/dev/null
    fi' 2>/dev/null | awk '$2 ~ /^[0-9]+$/' | sort
}
before=$(restart_counts)
sleep "$STABLE_WAIT"
after=$(restart_counts)
restarting=$(join <(echo "$before") <(echo "$after") | awk '$3 > $2 {printf "%s%s (+%d)", sep, $1, $3 - $2; sep=", "}')
[[ -z "$restarting" ]] || fail "not stable: restarted within ${STABLE_WAIT}s without anyone touching it: ${restarting}"
check_health screenshot-update.png || fail "not stable: ${STABLE_WAIT}s later, ${health_problem}"

# Error lines in the journal since boot: often harmless, sometimes the reason
# a feature is broken. Information only.
if guest_exec sh -c 'command -v journalctl' &>/dev/null; then
  journal_errors=$(guest_exec journalctl -b -p err -q -o cat --no-pager 2>/dev/null | grep -vE '^\s*$' | sort | uniq -c | sort -rn)
  if [[ -n "$journal_errors" ]]; then
    n=$(awk '{s += $1} END {print s}' <<<"$journal_errors")
    top=$(head -n 2 <<<"$journal_errors" | sed -E 's/^\s*[0-9]+\s+//' | cut -c1-120 | paste -sd'|' - | sed 's/|/; /g')
    notes+=("${n} error line(s) in the journal since boot, e.g. ${top}")
  fi
fi

status="pass"
finish
