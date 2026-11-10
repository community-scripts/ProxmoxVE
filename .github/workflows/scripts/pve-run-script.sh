#!/usr/bin/env bash
# Build one ct/ script from a pull request on this Proxmox host, check that the
# container really works, destroy it, and leave a result.json behind.
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
CTID_COUNT="${CTID_COUNT:-50}"
SERVE_ROOT="${SERVE_ROOT:-/srv/ci}"
SERVE_URL="${SERVE_URL:-http://10.99.0.1:18080}"
BRIDGE="${BRIDGE:-vmbr1}"
BUILD_TIMEOUT="${BUILD_TIMEOUT:-45m}"
URL_WAIT="${URL_WAIT:-120}"

# Every value below reaches a path, a URL or a command line.
[[ "$PR_REPO" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] || { echo "bad PR_REPO" >&2; exit 2; }
[[ "$UPSTREAM" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] || { echo "bad UPSTREAM" >&2; exit 2; }
[[ "$PR_SHA" =~ ^[0-9a-f]{40}$ ]] || { echo "bad PR_SHA" >&2; exit 2; }
[[ "$SCRIPT" =~ ^ct/[A-Za-z0-9._-]+\.sh$ ]] || { echo "bad SCRIPT" >&2; exit 2; }
[[ -z "$OS" || "$OS" =~ ^(debian|ubuntu|alpine)$ ]] || { echo "bad OS" >&2; exit 2; }
[[ "$CTID_BASE" =~ ^[0-9]+$ ]] || { echo "bad CTID_BASE" >&2; exit 2; }

mkdir -p "$OUT_DIR"
RAW_LOG="$OUT_DIR/build.raw.log"
LOG="$OUT_DIR/build.log"
RESULT="$OUT_DIR/result.json"
INSTALL_LOG_OUT="$OUT_DIR/install.log"

app=$(basename "$SCRIPT" .sh)
job="${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-1}-${app}-${OS:-default}"
tree="$SERVE_ROOT/$job"
base="$SERVE_URL/$job"
started=$(date +%s)

status="fail"
step=""
exit_code=""
ctid=""
ct_ip=""
url=""
http_code=""
failed_units=""

strip_ansi() {
  sed -E 's/\x1B\[[0-9;?]*[A-Za-z]//g; s/\x1B[()][A-Z0-9]//g; s/\r/\n/g' | grep -vE '^\s*$'
}

# The install script's own output: everything $STD hides from the build log.
# Both engines write it inside the container as /root/.install-<session>.log;
# dev_mode=keep makes sure a failed container is still there to read it from.
# If it is gone anyway, the copy the engine leaves on the host is the fallback.
collect_install_log() {
  [[ -n "$ctid" ]] || return 0
  # Exactly one build ran in this container, so the newest install log is ours.
  if pct status "$ctid" &>/dev/null &&
    pct exec "$ctid" -- sh -c 'cat "$(ls -t /root/.install-*.log 2>/dev/null | head -n1)"' 2>/dev/null |
    strip_ansi >"$INSTALL_LOG_OUT" && [[ -s "$INSTALL_LOG_OUT" ]]; then
    return 0
  fi
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

finish() {
  [[ -f "$RAW_LOG" ]] && strip_ansi <"$RAW_LOG" >"$LOG"
  [[ -f "$RAW_LOG" ]] && collect_install_log
  jq -n \
    --arg script "$SCRIPT" --arg os "${OS:-default}" --arg status "$status" \
    --arg step "$step" --arg exit_code "$exit_code" --arg sha "$PR_SHA" \
    --arg ctid "$ctid" --arg url "$url" --arg http_code "$http_code" \
    --arg failed_units "$failed_units" \
    --argjson duration "$(($(date +%s) - started))" \
    --arg tail "$([[ -f "$LOG" ]] && tail -n 60 "$LOG")" \
    '{script: $script, os: $os, status: $status, step: $step, exit_code: $exit_code,
      sha: $sha, ctid: $ctid, url: $url, http_code: $http_code,
      failed_units: $failed_units, duration: $duration, log_tail: $tail}' >"$RESULT"
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
  sed -u -E 's/\r/\n/g; s/\x1B\[[0-9;?]*[ABCDEFGHJKSTfhilnsu]//g' | sed -u -E '/^\s*$/d'
}

start_streams() {
  stream_token=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')
  echo "::stop-commands::${stream_token}"
  tail -n +1 -F --pid="$build_pid" "$RAW_LOG" 2>/dev/null > >(live_filter) &
  log_pid=$!
  # setsid: its own process group, so stop_streams can take down the
  # pct exec / tail pair inside it in one go.
  setsid bash -c '
    for _ in $(seq 1 900); do
      f=$(pct exec "$1" -- sh -c "ls -t /root/.install-*.log 2>/dev/null | head -n1" 2>/dev/null)
      if [ -n "$f" ]; then
        echo "──────── install log of CT $1 (live) ────────"
        exec pct exec "$1" -- tail -n +1 -F "$f"
      fi
      sleep 2
    done' _ "$ctid" 2>/dev/null > >(live_filter | sed -u 's/^/  │ /') &
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
cleanup() {
  stop_streams
  if [[ -n "$build_pid" ]]; then
    pkill -TERM -P "$build_pid" &>/dev/null || true
    kill -TERM "$build_pid" &>/dev/null || true
    sleep 2
  fi
  if [[ -n "$ctid" ]]; then
    if pct status "$ctid" &>/dev/null; then
      pct stop "$ctid" --skiplock 1 &>/dev/null || true
      pct destroy "$ctid" --purge 1 --force 1 &>/dev/null || true
    fi
    rm -f "/run/ci-jobs/$ctid"
    # What the engine leaves on the host for this container and its session.
    local f sid
    for f in /tmp/pct_create_"${ctid}"_*.log; do
      [[ -f "$f" && "$f" -nt "$RAW_LOG.start" ]] || continue
      sid=$(sed -E 's/.*_([0-9a-f]+)\.log$/\1/' <<<"$f")
      rm -f -- "$f" /tmp/create-lxc-"${sid}".log /tmp/*-"${ctid}"-"${sid}".log
    done
  fi
  rm -f "$RAW_LOG.start"
  rm -rf -- "$tree"
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
mkdir -p /run/ci-jobs
exec 9>/run/ci-jobs/.lock
flock 9
for ((id = CTID_BASE; id < CTID_BASE + CTID_COUNT; id++)); do
  [[ -e "/run/ci-jobs/$id" ]] && continue
  pvesh get /cluster/nextid --vmid "$id" &>/dev/null || continue
  echo "$job" >"/run/ci-jobs/$id"
  ctid=$id
  break
done
flock -u 9
exec 9>&-
[[ -n "$ctid" ]] || setup_error "no free container ID in ${CTID_BASE}-$((CTID_BASE + CTID_COUNT - 1))"

# --- Fetch the approved commit and point it at ourselves ------------------------
mkdir -p "$tree"
curl -fsSL --retry 3 "https://codeload.github.com/${PR_REPO}/tar.gz/${PR_SHA}" |
  tar -xz -C "$tree" --strip-components=1 || setup_error "could not download ${PR_REPO}@${PR_SHA:0:7}"
[[ -f "$tree/$SCRIPT" ]] || fail "${SCRIPT} does not exist at ${PR_SHA:0:7}"

upstream_re="https://raw\.githubusercontent\.com/${UPSTREAM//./\\.}/(refs/heads/)?main"
grep -rlE "$upstream_re" "$tree" --include='*.sh' --include='*.func' |
  xargs -r sed -i -E "s#${upstream_re}#${base}#g"

# --- Build ----------------------------------------------------------------------
echo "Building ${SCRIPT} (${OS:-default OS}) as CT ${ctid} from ${PR_REPO}@${PR_SHA:0:7}"
hostname_safe="ci-$(tr -c 'a-z0-9-\n' '-' <<<"${app,,}" | cut -c1-50)"
build_env=(
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  HOME=/root TERM=dumb LANG=C.UTF-8
  mode=default MODE=default PHS_SILENT=1 DIAGNOSTICS=no
  var_ctid="$ctid" var_hostname="$hostname_safe"
  var_container_storage=local var_template_storage=local var_brg="$BRIDGE"
  "dev_mode=timing,keep" COMMUNITY_SCRIPTS_URL="$base"
)
touch "$RAW_LOG.start"
[[ -n "$OS" ]] && build_env+=(var_os="$OS")

# --- Answers for the script's questions ------------------------------------------
# Nobody types into CI, so anything the install asks has to be answered up front.
# AGENTS.md rule 24: a script reads var_<x> first and prompts only when it is
# unset (or uses prompt_input_required ... "var_x"). Every such variable gets a
# CI value here. The names come from json/<app>.json app_vars (DevScripts) and
# from the read/prompt_ lines of the install script (both repos). A bare `read`
# that ignores its variable still fails, and the report says why.
ENGINE_VARS=" var_ctid var_hostname var_os var_version var_cpu var_ram var_disk var_brg var_net var_container_storage var_template_storage var_unprivileged var_tags var_arm64 var_testurl var_verbose var_timezone var_http_proxy var_http_no_proxy var_appversion "
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
json="$tree/json/${app}.json"
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
nsapp=$(grep -m1 -oE '^APP="[^"]+"' "$tree/$SCRIPT" | cut -d'"' -f2 | tr -d ' ' | tr '[:upper:]' '[:lower:]')
for f in "$tree/install/${app}-install.sh" "$tree/install/${nsapp}-install.sh" "$tree/$SCRIPT"; do
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
  bash -c 'bash -c "$(curl -fsSL "$1")"' _ "$base/$SCRIPT" </dev/null >"$RAW_LOG" 2>&1 &
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
pct status "$ctid" 2>/dev/null | grep -q running || fail "container ${ctid} is not running"

ct_ip=$(pct exec "$ctid" -- sh -c "ip -4 -o addr show dev eth0 | awk '{print \$4}' | cut -d/ -f1" 2>/dev/null | head -n1)

if pct exec "$ctid" -- sh -c 'command -v systemctl' &>/dev/null; then
  sleep 10
  failed_units=$(pct exec "$ctid" -- systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}' | paste -sd, -)
elif pct exec "$ctid" -- sh -c 'command -v rc-status' &>/dev/null; then
  failed_units=$(pct exec "$ctid" -- rc-status --crashed 2>/dev/null | awk '{print $1}' | paste -sd, -)
fi
[[ -z "$failed_units" ]] || fail "failed services: ${failed_units}"

# What the app's page looks like, for the PR comment. Chromium runs as its own
# unprivileged user with its sandbox on: the page is served by code under test.
# ci-shot-firewall (pve-ci-host-setup.sh) keeps that user off this host and the
# lab network; without it there is no screenshot rather than an unguarded one.
take_screenshot() {
  command -v chromium >/dev/null && id ci-shot &>/dev/null || return 0
  iptables -w -S CI_SHOT 2>/dev/null | grep -q -- '-d 10.0.0.0/8 .*REJECT' || return 0
  local dir
  dir=$(mktemp -d)
  chown ci-shot "$dir"
  runuser -u ci-shot -- timeout 60 chromium --headless=new --disable-gpu --hide-scrollbars \
    --ignore-certificate-errors --no-first-run --window-size=1280,800 --virtual-time-budget=10000 \
    --user-data-dir="$dir/profile" --screenshot="$dir/shot.png" "$url" &>/dev/null
  # Only a plausible PNG leaves this function.
  if [[ -s "$dir/shot.png" && $(stat -c %s "$dir/shot.png") -lt 3000000 ]] &&
    [[ "$(head -c 8 "$dir/shot.png" | od -An -tx1 | tr -d ' \n')" == "89504e470d0a1a0a" ]]; then
    cp "$dir/shot.png" "$OUT_DIR/screenshot.png"
  fi
  rm -rf -- "$dir"
}

# The URL the script tells the user to open, e.g. http://${IP}:1337/admin, has
# to answer 200 (after redirects, so a jump to /login is fine). A script that
# prints no URL has no web UI to check.
pattern=$(grep -oE 'https?://\$\{IP\}(:[0-9]+)?(/[A-Za-z0-9._~/?=&%-]*)?' "$tree/$SCRIPT" | head -n1)
if [[ -n "$pattern" && -n "$ct_ip" ]]; then
  url="${pattern/\$\{IP\}/$ct_ip}"
  for ((waited = 0; waited < URL_WAIT; waited += 5)); do
    http_code=$(curl -sk -L --max-redirs 5 -o /dev/null -w '%{http_code}' --max-time 10 "$url" || true)
    [[ "$http_code" =~ ^2[0-9][0-9]$ ]] && break
    sleep 5
  done
  # Also when the check fails: an error page explains more than a status code.
  [[ "$http_code" =~ ^[1-5][0-9][0-9]$ ]] && take_screenshot
  [[ "$http_code" =~ ^2[0-9][0-9]$ ]] || fail "${url} answered ${http_code/#000/nothing} instead of 200 within ${URL_WAIT}s"
fi

status="pass"
finish
