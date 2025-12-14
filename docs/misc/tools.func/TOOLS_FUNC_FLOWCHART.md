# tools.func Flowchart

## Main Package Installation Flow

```
┌──────────────────────────────────┐
│  Install Script Starts           │
│  source tools.func               │
└──────────────┬───────────────────┘
               │
               ▼
         ┌─────────────┐
         │ pkg_update()│
         │  (apt/apk)  │
         └──────┬──────┘
                │
                ▼
        ┌────────────────┐
        │ Retry Logic    │  ◄─────┐
        │ (Up to 3 tries)│        │
        └────┬───────────┘        │
             │                    │
             ├─ Success: Continue │
             ├─ Retry 1 ──────────┘
             └─ Fail: Exit
                │
                ▼
        ┌──────────────────┐
        │ setup_deb822_repo│
        │ (Add repository) │
        └────────┬─────────┘
                 │
                 ▼
         ┌─────────────────┐
         │ GPG Key Setup   │
         │ Verify Repo OK  │
         └────────┬────────┘
                  │
                  ▼
         ┌──────────────────┐
         │ Tool Installation│
         │ (setup_nodejs,   │
         │  setup_php, etc.)│
         └────────┬─────────┘
                  │
       ┌──────────┴──────────┐
       │                     │
       ▼                     ▼
  ┌─────────────┐    ┌──────────────┐
  │ Node.js     │    │ MariaDB      │
  │ setup_      │    │ setup_       │
  │ nodejs()    │    │ mariadb()    │
  └──────┬──────┘    └────────┬─────┘
         │                    │
         └────────┬───────────┘
                  │
                  ▼
         ┌───────────────────┐
         │ Installation OK?  │
         └────┬──────────┬───┘
              │          │
            YES          NO
              │          │
              │          ▼
              │     ┌─────────────┐
              │     │ Rollback    │
              │     │ Error Exit  │
              │     └─────────────┘
              │
              ▼
        ┌─────────────────┐
        │ Set Version File│
        │ /opt/TOOL_v.txt │
        └─────────────────┘
```

## Repository Setup Flow (setup_deb822_repo)

```
setup_deb822_repo(URL, name, dist, repo_url, release)
    │
    ├─ Parse Parameters
    │  ├─ URL: Repository URL
    │  ├─ name: Repository name
    │  ├─ dist: Distro (jammy, bookworm)
    │  ├─ repo_url: Main URL
    │  └─ release: Release type
    │
    ├─ Add GPG Key
    │  ├─ Download key from URL
    │  ├─ Add to keyring
    │  └─ Trust key for deb822
    │
    ├─ Create deb822 file
    │  ├─ /etc/apt/sources.list.d/name.sources
    │  ├─ Format: DEB822
    │  └─ Include GPG key reference
    │
    ├─ Validate Repository
    │  ├─ apt-get update
    │  ├─ Check for errors
    │  └─ Retry if needed
    │
    └─ Success / Error
```

## Tool Installation Chain

```
Tools to Install:
├─ Programming Languages
│  ├─ setup_nodejs(VERSION)
│  ├─ setup_php(VERSION)
│  ├─ setup_python(VERSION)
│  ├─ setup_ruby(VERSION)
│  └─ setup_golang(VERSION)
│
├─ Databases
│  ├─ setup_mariadb(VERSION)
│  ├─ setup_postgresql(VERSION)
│  ├─ setup_mongodb(VERSION)
│  └─ setup_redis(VERSION)
│
├─ Web Servers
│  ├─ setup_nginx()
│  ├─ setup_apache()
│  ├─ setup_caddy()
│  └─ setup_traefik()
│
├─ Containers
│  ├─ setup_docker()
│  └─ setup_podman()
│
└─ Utilities
   ├─ setup_git()
   ├─ setup_composer()
   ├─ setup_build_tools()
   └─ setup_[TOOL]()
```

## Package Operation Retry Logic

```
┌─────────────────────┐
│ pkg_install PKG1    │
│ pkg_install PKG2    │
│ pkg_install PKG3    │
└──────────┬──────────┘
           │
           ▼
    ┌─────────────────┐
    │ APT Lock Check  │
    └────┬────────┬───┘
         │        │
      FREE     LOCKED
         │        │
         │        ▼
         │   ┌─────────────┐
         │   │ Wait 5 sec  │
         │   └────────┬────┘
         │            │
         │            ▼
         │   ┌─────────────┐
         │   │ Retry Check │
         │   └────┬────┬───┘
         │        │    │
         │     OK  LOCK
         │        │    │
         │        └────┘ (loop)
         │
         ▼
    ┌──────────────────┐
    │ apt-get install  │
    │ (with $STD)      │
    └────┬─────────┬───┘
         │         │
       SUCCESS   FAILED
         │         │
         │         ▼
         │    ┌──────────────┐
         │    │ Retry Count? │
         │    └────┬─────┬───┘
         │         │     │
         │      <3  ≥3   │
         │      Retry  FAIL
         │         │
         │         └─────────┐
         │                   │
         ▼                   ▼
    ┌─────────┐         ┌─────────┐
    │ SUCCESS │         │ FAILED  │
    └─────────┘         │ EXIT 1  │
                        └─────────┘
```

---

**Visual Reference for**: tools.func package management and tool installation
**Last Updated**: December 2025
