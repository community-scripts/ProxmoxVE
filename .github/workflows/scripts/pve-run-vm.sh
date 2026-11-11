# shellcheck shell=bash
# The vm/ half of pve-run-script.sh, sourced from it: same inputs, same
# result.json, same live output. Only building and checking differ.
#
# A VM script runs entirely on this host (there is no install script inside
# the guest to follow), unattended through the core engine's VM_UNATTENDED=1:
# the script's defaults, with ID, name, bridge and storage set from here. The
# guest then boots on vmbr1 like the containers do, so its address is whatever
# this host's dnsmasq leased to its MAC; no guest agent needed.
#
# What passes: the script exits 0 and says "Completed successfully", the VM is
# running and keeps running through the boot wait, and where the script prints
# a URL built from the VM's address (http://${VM_IP}:9000) that URL answers 200.
# An installer ISO or an image without DHCP gets no address; that is reported,
# not failed. There is no update test: a VM has no `update`.

VM_BOOT_WAIT="${VM_BOOT_WAIT:-300}"
VM_URL_WAIT="${VM_URL_WAIT:-600}"
LEASES="${LEASES:-/var/lib/misc/dnsmasq.leases}"

# One VM build per host at a time: a VM takes 2-8 GB of RAM and a disk image,
# where a container takes a fraction. Held until the job exits; the build is
# started with this descriptor closed, so a QEMU process can never inherit it.
vm_wait_turn() {
  exec 7>/run/ci-jobs/.vm-turn
  flock -n 7 && return 0
  echo "Another VM build is running on this host; waiting for it (one VM at a time)"
  flock -w 3600 7 || setup_error "waited an hour for this host's VM slot"
}

vm_cleanup() {
  if qm status "$ctid" &>/dev/null; then
    qm stop "$ctid" --skiplock 1 --timeout 30 &>/dev/null || true
    qm destroy "$ctid" --purge 1 --destroy-unreferenced-disks 1 --skiplock 1 &>/dev/null || true
  fi
  rm -f "/run/ci-jobs/$ctid" "/run/ci-jobs/console-${ctid}.png"
  # Cloud-Init network snippets the script wrote for this VM.
  [[ -f "$RAW_LOG.start" ]] &&
    find /var/lib/vz/snippets -maxdepth 1 -type f -name "*${ctid}*" -newer "$RAW_LOG.start" -delete 2>/dev/null
  true
}

# The VM's screen, straight from QEMU. Pixels only, but they come from the
# guest, so the same checks as for a browser screenshot apply.
vm_console_shot() {
  local f="/run/ci-jobs/console-${ctid}.png"
  rm -f "$f"
  printf 'screendump %s -f png\n' "$f" | timeout 30 qm monitor "$ctid" &>/dev/null
  if [[ -s "$f" && $(stat -c %s "$f") -lt 3000000 ]] &&
    [[ "$(head -c 8 "$f" | od -An -tx1 | tr -d ' \n')" == "89504e470d0a1a0a" ]]; then
    cp "$f" "$OUT_DIR/screenshot.png"
  fi
  rm -f "$f"
}

vm_running() {
  qm status "$ctid" 2>/dev/null | grep -q 'status: running'
}

vm_build_and_check() {
  local hn mac pattern waited last
  hn="ci-$(tr -c 'a-z0-9-\n' '-' <<<"${app,,}" | cut -c1-40)-${ctid}"
  echo "Building ${SCRIPT} as VM ${ctid} from ${PR_REPO}@${PR_SHA:0:7}"
  local vm_env=(
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    HOME=/root TERM=dumb LANG=C.UTF-8 DIAGNOSTICS=no
    VM_UNATTENDED=1 VM_VMID="$ctid" VM_HOSTNAME="$hn" VM_BRIDGE="$BRIDGE"
    VM_STORAGE=local VM_ISO_STORAGE=local VM_START=yes
    COMMUNITY_SCRIPTS_URL="$base"
  )
  # Release lookups (vm_latest_from_github and the like).
  [[ -n "${GH_API_TOKEN:-}" ]] && vm_env+=(GITHUB_TOKEN="$GH_API_TOKEN")
  touch "$RAW_LOG.start"

  env -i "${vm_env[@]}" timeout --kill-after=1m "$BUILD_TIMEOUT" \
    bash -c 'bash -c "$(curl -fsSL "$1")"' _ "$base/$SCRIPT" </dev/null >"$RAW_LOG" 2>&1 7>&- &
  build_pid=$!
  start_streams
  wait "$build_pid"
  exit_code=$?
  build_pid=""
  stop_streams

  ((exit_code == 124 || exit_code == 137)) && fail "build timed out after ${BUILD_TIMEOUT}"
  if ((exit_code != 0)); then
    last=$(failure_line)
    step="script exited ${exit_code}${last:+: $last}"
    status="fail"
    classify_cpu_failure
    fail "$step" "$status"
  fi
  # vm_finish ends on a msg_ok of the script's choosing ("VM created. ..."),
  # older scripts on "Completed successfully". exit_script and friends leave
  # with 0 too, but on a cross.
  last=$(strip_ansi <"$RAW_LOG" | tail -n 1 | cut -c1-200)
  if ! grep -qi 'completed successfully' "$RAW_LOG" && ! [[ "$last" =~ ^[[:space:]]*✔ ]]; then
    fail "script exited 0 but never reported success${last:+ (last line: ${last})}"
  fi
  vm_running || fail "VM ${ctid} is not running after the script finished"

  # The address dnsmasq handed to this VM's MAC. The VM must stay up while it
  # boots: one that powers itself off or crashes is a failure.
  mac=$(qm config "$ctid" 2>/dev/null | sed -nE 's/^net0:[^=]*=([0-9A-Fa-f:]{17}).*/\1/p' | tr 'A-F' 'a-f')
  echo "Waiting up to ${VM_BOOT_WAIT}s for VM ${ctid} (${mac:-no NIC}) to boot and get an address"
  for ((waited = 0; waited < VM_BOOT_WAIT; waited += 5)); do
    vm_running || fail "VM ${ctid} stopped by itself while booting"
    [[ -n "$mac" ]] && ct_ip=$(awk -v m="$mac" '$2 == m {print $3}' "$LEASES" 2>/dev/null | tail -n 1)
    [[ -n "$ct_ip" ]] && break
    sleep 5
  done
  [[ -n "$ct_ip" ]] && echo "VM ${ctid} got ${ct_ip}" || echo "VM ${ctid} got no DHCP lease within ${VM_BOOT_WAIT}s"

  # Only a URL the script builds from the address it found; <VM-IP> in a
  # summary is a hint for later (after an installer ran), not a promise.
  # ${VM_IP}, $VM_IP and ${VM_IP:-<VM-IP>} all count.
  local ip_re='\$\{?VM_IP(:-[^}]*)?\}?'
  pattern=$(grep -oE "https?://${ip_re}(:[0-9]+)?(/[A-Za-z0-9._~/?=&%-]*)?" "$tree/$SCRIPT" | head -n1)
  if [[ -n "$pattern" ]]; then
    [[ -n "$ct_ip" ]] || fail "no IP address within ${VM_BOOT_WAIT}s, so ${pattern} could not be checked"
    url=$(sed -E "s#${ip_re}#${ct_ip}#" <<<"$pattern")
    for ((waited = 0; waited < VM_URL_WAIT; waited += 10)); do
      vm_running || fail "VM ${ctid} stopped by itself while its web UI was awaited"
      http_code=$(curl -sk -L --max-redirs 5 -o /dev/null -w '%{http_code}' --max-time 10 "$url" || true)
      [[ "$http_code" =~ ^2[0-9][0-9]$ ]] && break
      sleep 10
    done
    [[ "$http_code" =~ ^[1-5][0-9][0-9]$ ]] && take_screenshot screenshot.png
  else
    # Let the console settle on a login prompt rather than a boot message.
    sleep 20
  fi
  [[ -s "$OUT_DIR/screenshot.png" ]] || vm_console_shot
  if [[ -n "$url" && ! "$http_code" =~ ^2[0-9][0-9]$ ]]; then
    fail "${url} answered ${http_code/#000/nothing} instead of 200 within ${VM_URL_WAIT}s"
  fi
  vm_running || fail "VM ${ctid} stopped by itself"

  status="pass"
  finish
}
