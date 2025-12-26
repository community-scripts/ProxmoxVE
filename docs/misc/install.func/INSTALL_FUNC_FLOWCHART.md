# install.func Flowchart

## Installation Workflow

```
┌──────────────────────────────────┐
│  Container Started               │
│  (Inside LXC by build.func)      │
└──────────────┬───────────────────┘
               │
               ▼
    ┌──────────────────────┐
    │ Source Functions     │
    │ $FUNCTIONS_FILE_PATH │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │ setting_up_container│
    │ Display setup msg    │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │ network_check()      │
    │ (Verify internet)    │
    └────┬──────────────┬──┘
         │              │
       OK              FAIL
         │              │
         │              ▼
         │         ┌──────────────┐
         │         │ Retry Check  │
         │         │ 3 attempts   │
         │         └────┬─────┬───┘
         │              │     │
         │            OK   FAIL
         │              │     │
         └──────────────┘     │
                 │            │
                 ▼            ▼
    ┌──────────────────────┐ ┌──────────────┐
    │ update_os()          │ │ Exit Error   │
    │ (apt update/upgrade) │ │ No internet  │
    └──────────┬───────────┘ └──────────────┘
               │
               ▼
    ┌──────────────────────┐
    │ verb_ip6() [optional]│
    │ (Enable IPv6)        │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │ Application          │
    │ Installation         │
    │ (Main work)          │
    └──────────┬───────────┘
               │
       ┌───────┴────────┐
       │                │
    SUCCESS           FAILED
       │                │
       │                └─ error_handler catches
       │                   (if catch_errors active)
       │
       ▼
    ┌──────────────────────┐
    │ motd_ssh()           │
    │ (Setup SSH/MOTD)     │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │ customize()          │
    │ (Apply settings)     │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │ cleanup_lxc()        │
    │ (Final cleanup)      │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │ Installation         │
    │ Complete ✓           │
    └──────────────────────┘
```

## Network Check Retry Logic

```
network_check()
    │
    ├─ Ping 8.8.8.8 (Google DNS)
    │  └─ Response?
    │     ├─ YES: Continue
    │     └─ NO: Retry
    │
    ├─ Retry 1
    │  └─ Wait 5s, ping again
    │
    ├─ Retry 2
    │  └─ Wait 5s, ping again
    │
    └─ Retry 3
       ├─ If OK: Continue
       └─ If FAIL: Exit Error
          (Network unavailable)
```

---

**Visual Reference for**: install.func container setup workflows
**Last Updated**: December 2025
