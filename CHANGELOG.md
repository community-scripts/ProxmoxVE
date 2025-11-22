<div align="center">
  <a href="#">
    <img src="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/images/logo.png" height="100px" />
 </a>
</div>
<h1 align="center">Changelog</h1>

<h3 align="center">All notable changes to this project will be documented in this file.</h3>

> [!CAUTION]
Exercise vigilance regarding copycat or coat-tailing sites that seek to exploit the project's popularity for potentially malicious purposes.

## 2025-11-22

## 2025-11-21

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - plex: prevent [] syntax issue [@MickLesk](https://github.com/MickLesk) ([#9318](https://github.com/community-scripts/ProxmoxVE/pull/9318))
    - fix: karakeep strip "v" from release version [@CrazyWolf13](https://github.com/CrazyWolf13) ([#9324](https://github.com/community-scripts/ProxmoxVE/pull/9324))
    - NetVisor: fix grep in update [@vhsdream](https://github.com/vhsdream) ([#9334](https://github.com/community-scripts/ProxmoxVE/pull/9334))
    - Immich: pin correct version [@vhsdream](https://github.com/vhsdream) ([#9332](https://github.com/community-scripts/ProxmoxVE/pull/9332))

  - #### 🔧 Refactor

    - Refactor IPv6 disable logic and add 'disable' option [@MickLesk](https://github.com/MickLesk) ([#9326](https://github.com/community-scripts/ProxmoxVE/pull/9326))

## 2025-11-20

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - core: change 'uv cache clear' to 'uv cache clean' [@MickLesk](https://github.com/MickLesk) ([#9299](https://github.com/community-scripts/ProxmoxVE/pull/9299))

  - #### ✨ New Features

    - Immich v2.3.1: OpenVINO tuning, OCR fixes, Maintenance mode, workflows/plugin framework [@vhsdream](https://github.com/vhsdream) ([#9310](https://github.com/community-scripts/ProxmoxVE/pull/9310))
    - kasm: add: update [@CrazyWolf13](https://github.com/CrazyWolf13) ([#9253](https://github.com/community-scripts/ProxmoxVE/pull/9253))
    - tools/pve: expand PVE support to 9.0–9.1 (post-install & netdata) [@MickLesk](https://github.com/MickLesk) ([#9298](https://github.com/community-scripts/ProxmoxVE/pull/9298))

  - #### 💥 Breaking Changes

    - Omada - AVX-only support [@MickLesk](https://github.com/MickLesk) ([#9295](https://github.com/community-scripts/ProxmoxVE/pull/9295))

## 2025-11-19

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - HotFix: Fix NetVisor env var [@vhsdream](https://github.com/vhsdream) ([#9286](https://github.com/community-scripts/ProxmoxVE/pull/9286))
    - Jotty: reduce RAM requirement [@vhsdream](https://github.com/vhsdream) ([#9272](https://github.com/community-scripts/ProxmoxVE/pull/9272))
    - Nginx Proxy Manager: Pin version to v2.13.4 [@tremor021](https://github.com/tremor021) ([#9259](https://github.com/community-scripts/ProxmoxVE/pull/9259))

  - #### ✨ New Features

    - PVE 9.1 version support [@MickLesk](https://github.com/MickLesk) ([#9280](https://github.com/community-scripts/ProxmoxVE/pull/9280))
    - force disable IPv6 if IPV6_METHOD = none [@MickLesk](https://github.com/MickLesk) ([#9277](https://github.com/community-scripts/ProxmoxVE/pull/9277))

  - #### 💥 Breaking Changes

    - NetVisor: v0.10.0 fixes [@vhsdream](https://github.com/vhsdream) ([#9255](https://github.com/community-scripts/ProxmoxVE/pull/9255))

## 2025-11-18

### 🚀 Updated Scripts

  - librenms: Fix password to short [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#9236](https://github.com/community-scripts/ProxmoxVE/pull/9236))

  - #### 🐞 Bug Fixes

    - Huntarr: Downgrade Python to 3.12 [@MickLesk](https://github.com/MickLesk) ([#9246](https://github.com/community-scripts/ProxmoxVE/pull/9246))
    - kasm: fix release fetching [@MickLesk](https://github.com/MickLesk) ([#9244](https://github.com/community-scripts/ProxmoxVE/pull/9244))

## 2025-11-17

### 🆕 New Scripts

  - Passbolt ([#9226](https://github.com/community-scripts/ProxmoxVE/pull/9226))
- Domain-Locker ([#9214](https://github.com/community-scripts/ProxmoxVE/pull/9214))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Domain Monitor: Fix encryption key length in install script [@tremor021](https://github.com/tremor021) ([#9239](https://github.com/community-scripts/ProxmoxVE/pull/9239))
    - NetVisor: add build deps, increase RAM [@vhsdream](https://github.com/vhsdream) ([#9205](https://github.com/community-scripts/ProxmoxVE/pull/9205))
    - fix: restart apache2 after installing zabbix config [@AlphaLawless](https://github.com/AlphaLawless) ([#9206](https://github.com/community-scripts/ProxmoxVE/pull/9206))

  - #### ✨ New Features

    - [core]: harmonize app_name for creds [@MickLesk](https://github.com/MickLesk) ([#9224](https://github.com/community-scripts/ProxmoxVE/pull/9224))

  - #### 💥 Breaking Changes

    - Refactor: paperless-ngx (Breaking Change Inside) [@MickLesk](https://github.com/MickLesk) ([#9223](https://github.com/community-scripts/ProxmoxVE/pull/9223))

### 🧰 Maintenance

  - #### 📂 Github

    - github: add verbose mode check to bug report template [@MickLesk](https://github.com/MickLesk) ([#9234](https://github.com/community-scripts/ProxmoxVE/pull/9234))

## 2025-11-16

### 🆕 New Scripts

  - Metabase ([#9190](https://github.com/community-scripts/ProxmoxVE/pull/9190))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Change backup directory to /opt for paperless-ngx [@ProfDrYoMan](https://github.com/ProfDrYoMan) ([#9195](https://github.com/community-scripts/ProxmoxVE/pull/9195))
    - Kimai: remove deprecated admin_lte section [@MickLesk](https://github.com/MickLesk) ([#9182](https://github.com/community-scripts/ProxmoxVE/pull/9182))
    - healthchecks: bump python to 3.13 [@MickLesk](https://github.com/MickLesk) ([#9175](https://github.com/community-scripts/ProxmoxVE/pull/9175))

### 🌐 Website

  - #### 📝 Script Information

    - fixed config_path for donetick [@TazztheMonster](https://github.com/TazztheMonster) ([#9203](https://github.com/community-scripts/ProxmoxVE/pull/9203))

## 2025-11-15

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - privatebin: fix: syntax error in chmod command [@CrazyWolf13](https://github.com/CrazyWolf13) ([#9169](https://github.com/community-scripts/ProxmoxVE/pull/9169))
    - phpIPHAM: patch db and add fping [@MickLesk](https://github.com/MickLesk) ([#9177](https://github.com/community-scripts/ProxmoxVE/pull/9177))
    - changedetection: fix: increase ressources [@CrazyWolf13](https://github.com/CrazyWolf13) ([#9171](https://github.com/community-scripts/ProxmoxVE/pull/9171))
    - 2fauth: update composer command [@CrazyWolf13](https://github.com/CrazyWolf13) ([#9168](https://github.com/community-scripts/ProxmoxVE/pull/9168))

  - #### 🔧 Refactor

    - firefly: refactor update_script and add dataimporter update [@MickLesk](https://github.com/MickLesk) ([#9178](https://github.com/community-scripts/ProxmoxVE/pull/9178))

## 2025-11-14

### 🆕 New Scripts

  - LibreNMS ([#9148](https://github.com/community-scripts/ProxmoxVE/pull/9148))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - karakeep: clean install after every update [@MickLesk](https://github.com/MickLesk) ([#9144](https://github.com/community-scripts/ProxmoxVE/pull/9144))

  - #### ✨ New Features

    - bump grafana to debian 13 [@mschabhuettl](https://github.com/mschabhuettl) ([#9141](https://github.com/community-scripts/ProxmoxVE/pull/9141))

## 2025-11-13

### 🆕 New Scripts

  - Netvisor ([#9133](https://github.com/community-scripts/ProxmoxVE/pull/9133))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Domain Monitor: Add domain checking cron [@tremor021](https://github.com/tremor021) ([#9129](https://github.com/community-scripts/ProxmoxVE/pull/9129))
    - Kimai: Fix for MariaDB connection URL [@tremor021](https://github.com/tremor021) ([#9124](https://github.com/community-scripts/ProxmoxVE/pull/9124))
    - Fix: filebrowser-quantum update [@MickLesk](https://github.com/MickLesk) ([#9115](https://github.com/community-scripts/ProxmoxVE/pull/9115))
    - tools.func: fix wrong output for setup_java (error token is "0") [@snow2k9](https://github.com/snow2k9) ([#9110](https://github.com/community-scripts/ProxmoxVE/pull/9110))

  - #### ✨ New Features

    - tools.func: improve Rust setup and crate installation logic [@MickLesk](https://github.com/MickLesk) ([#9120](https://github.com/community-scripts/ProxmoxVE/pull/9120))

  - #### 💥 Breaking Changes

    - Remove Barcodebuddy [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#9135](https://github.com/community-scripts/ProxmoxVE/pull/9135))
    - Downgrade Swizzin to Debian 12 Bookworm [@MickLesk](https://github.com/MickLesk) ([#9116](https://github.com/community-scripts/ProxmoxVE/pull/9116))

## 2025-11-12

### 🆕 New Scripts

  - Miniflux ([#9091](https://github.com/community-scripts/ProxmoxVE/pull/9091))
- Splunk Enterprise ([#9090](https://github.com/community-scripts/ProxmoxVE/pull/9090))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - evcc: add missing fi in update  [@MichaelVetter1979](https://github.com/MichaelVetter1979) ([#9107](https://github.com/community-scripts/ProxmoxVE/pull/9107))
    - PeaNUT: use clean install flag during update [@vhsdream](https://github.com/vhsdream) ([#9100](https://github.com/community-scripts/ProxmoxVE/pull/9100))
    - Tududi: Create new env file from example; fix installation & update [@vhsdream](https://github.com/vhsdream) ([#9097](https://github.com/community-scripts/ProxmoxVE/pull/9097))
    - openwebui: Python version usage | core: zsh completion install [@MickLesk](https://github.com/MickLesk) ([#9079](https://github.com/community-scripts/ProxmoxVE/pull/9079))
    - Refactor: evcc [@CrazyWolf13](https://github.com/CrazyWolf13) ([#9057](https://github.com/community-scripts/ProxmoxVE/pull/9057))

  - #### ✨ New Features

    - Bump K to H-Scripts to Debian 13 (Trixie) [@MickLesk](https://github.com/MickLesk) ([#8597](https://github.com/community-scripts/ProxmoxVE/pull/8597))

  - #### 🔧 Refactor

    - Refactor: web-check [@CrazyWolf13](https://github.com/CrazyWolf13) ([#9055](https://github.com/community-scripts/ProxmoxVE/pull/9055))

### 🌐 Website

  - Refactor web analytics to use Rybbit instead of Umami [@BramSuurdje](https://github.com/BramSuurdje) ([#9072](https://github.com/community-scripts/ProxmoxVE/pull/9072))

## 2025-11-11

### 🆕 New Scripts

  - Domain-Monitor ([#9029](https://github.com/community-scripts/ProxmoxVE/pull/9029))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - tools.func: fix JDK count variable initialization in setup_java [@MickLesk](https://github.com/MickLesk) ([#9058](https://github.com/community-scripts/ProxmoxVE/pull/9058))
    - flaresolverr: unpin - use latest version [@CrazyWolf13](https://github.com/CrazyWolf13) ([#9046](https://github.com/community-scripts/ProxmoxVE/pull/9046))
    - Part-DB: Increase amount of RAM [@tremor021](https://github.com/tremor021) ([#9039](https://github.com/community-scripts/ProxmoxVE/pull/9039))

  - #### 🔧 Refactor

    - Refactor: openHAB [@MickLesk](https://github.com/MickLesk) ([#9060](https://github.com/community-scripts/ProxmoxVE/pull/9060))

### 🧰 Maintenance

  - #### 📂 Github

    - [docs / gh]: modernize README | Change Version Support in SECURITY.md | Shoutout to selfhst\icons [@MickLesk](https://github.com/MickLesk) ([#9049](https://github.com/community-scripts/ProxmoxVE/pull/9049))

## 2025-11-10

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Plex: extend checking for deb822 source [@Matt17000](https://github.com/Matt17000) ([#9036](https://github.com/community-scripts/ProxmoxVE/pull/9036))

  - #### ✨ New Features

    - tools.func: add helper functions for MariaDB and PostgreSQL setup [@MickLesk](https://github.com/MickLesk) ([#9026](https://github.com/community-scripts/ProxmoxVE/pull/9026))
    - core: update message for no available updates scenario (if pinned) [@MickLesk](https://github.com/MickLesk) ([#9021](https://github.com/community-scripts/ProxmoxVE/pull/9021))
    - Migrate Open WebUI to uv-based installation [@MickLesk](https://github.com/MickLesk) ([#9019](https://github.com/community-scripts/ProxmoxVE/pull/9019))

  - #### 🔧 Refactor

    - Refactor: phpIPAM [@MickLesk](https://github.com/MickLesk) ([#9027](https://github.com/community-scripts/ProxmoxVE/pull/9027))

## 2025-11-09

### 🚀 Updated Scripts

  - core: improve log cleaning [@MickLesk](https://github.com/MickLesk) ([#8999](https://github.com/community-scripts/ProxmoxVE/pull/8999))

  - #### 🐞 Bug Fixes

    - Add wkhtmltopdf to Odoo installation dependencies [@akileos](https://github.com/akileos) ([#9010](https://github.com/community-scripts/ProxmoxVE/pull/9010))
    - fix(jotty): Comments removed from variables, as they are interpreted. [@schneider-de-com](https://github.com/schneider-de-com) ([#9002](https://github.com/community-scripts/ProxmoxVE/pull/9002))
    - fix(n8n): Add python3-setuptools dependency for Debian 13 [@chrikodo](https://github.com/chrikodo) ([#9007](https://github.com/community-scripts/ProxmoxVE/pull/9007))
    - Paperless-ngx: hotfix config path [@vhsdream](https://github.com/vhsdream) ([#9003](https://github.com/community-scripts/ProxmoxVE/pull/9003))
    - Paperless-NGX: Move config backup outside of app folder [@vhsdream](https://github.com/vhsdream) ([#8996](https://github.com/community-scripts/ProxmoxVE/pull/8996))

## 2025-11-08

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Technitium DNS: Fix update [@tremor021](https://github.com/tremor021) ([#8980](https://github.com/community-scripts/ProxmoxVE/pull/8980))
    - MediaManager: add LOG_FILE to start.sh script; fix BASE_PATH and PUBLIC_API_URL [@vhsdream](https://github.com/vhsdream) ([#8981](https://github.com/community-scripts/ProxmoxVE/pull/8981))
    - Firefly: Fix missing command in update script [@tremor021](https://github.com/tremor021) ([#8972](https://github.com/community-scripts/ProxmoxVE/pull/8972))
    - MongoDB: Remove unused message [@tremor021](https://github.com/tremor021) ([#8969](https://github.com/community-scripts/ProxmoxVE/pull/8969))
    - Set TZ=Etc/UTC in Ghostfolio installation script [@LuloDev](https://github.com/LuloDev) ([#8961](https://github.com/community-scripts/ProxmoxVE/pull/8961))

  - #### 🔧 Refactor

    - paperless: refactor - remove backup after update and enable clean install [@MickLesk](https://github.com/MickLesk) ([#8988](https://github.com/community-scripts/ProxmoxVE/pull/8988))
    - Refactor setup_deb822_repo for optional architectures [@MickLesk](https://github.com/MickLesk) ([#8983](https://github.com/community-scripts/ProxmoxVE/pull/8983))

## 2025-11-07

### 🆕 New Scripts

  - infisical ([#8926](https://github.com/community-scripts/ProxmoxVE/pull/8926))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Update script URLs to ProxmoxVE repository [@MickLesk](https://github.com/MickLesk) ([#8946](https://github.com/community-scripts/ProxmoxVE/pull/8946))
    - tools.func: fix amd64 arm64 mismatch [@MickLesk](https://github.com/MickLesk) ([#8943](https://github.com/community-scripts/ProxmoxVE/pull/8943))
    - ghostfolio: refactor CoinGecko key prompts in installer [@MickLesk](https://github.com/MickLesk) ([#8935](https://github.com/community-scripts/ProxmoxVE/pull/8935))
    - flaresolverr: pin release to 3.4.3 [@CrazyWolf13](https://github.com/CrazyWolf13) ([#8937](https://github.com/community-scripts/ProxmoxVE/pull/8937))

  - #### ✨ New Features

    - Pangolin: Add Traefik proxy [@tremor021](https://github.com/tremor021) ([#8952](https://github.com/community-scripts/ProxmoxVE/pull/8952))

## 2025-11-06

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - OpenProject: Remove duplicate server_path_prefix configuration [@tremor021](https://github.com/tremor021) ([#8919](https://github.com/community-scripts/ProxmoxVE/pull/8919))
    - Grist: Fix change directory to /opt/grist before build steps [@tremor021](https://github.com/tremor021) ([#8913](https://github.com/community-scripts/ProxmoxVE/pull/8913))
    - Jotty hotfix: SSO_FALLBACK_LOCAL value [@vhsdream](https://github.com/vhsdream) ([#8907](https://github.com/community-scripts/ProxmoxVE/pull/8907))
    - npm: add Debian version check to update script [@MickLesk](https://github.com/MickLesk) ([#8901](https://github.com/community-scripts/ProxmoxVE/pull/8901))

  - #### ✨ New Features

    - MongoDB: install script now use setup_mongodb [@MickLesk](https://github.com/MickLesk) ([#8897](https://github.com/community-scripts/ProxmoxVE/pull/8897))

  - #### 🔧 Refactor

    - Refactor: Graylog [@tremor021](https://github.com/tremor021) ([#8912](https://github.com/community-scripts/ProxmoxVE/pull/8912))

## 2025-11-05

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Immich: Pin version to 2.2.3 [@vhsdream](https://github.com/vhsdream) ([#8861](https://github.com/community-scripts/ProxmoxVE/pull/8861))
    - Jotty: increase RAM to 4GB [@vhsdream](https://github.com/vhsdream) ([#8887](https://github.com/community-scripts/ProxmoxVE/pull/8887))
    - Zabbix: fix agent service recognition in update [@MickLesk](https://github.com/MickLesk) ([#8881](https://github.com/community-scripts/ProxmoxVE/pull/8881))

  - #### 💥 Breaking Changes

    - fix: npm: refactor for v2.13.x [@CrazyWolf13](https://github.com/CrazyWolf13) ([#8870](https://github.com/community-scripts/ProxmoxVE/pull/8870))

  - #### 🔧 Refactor

    - Refactor: Open WebUI [@tremor021](https://github.com/tremor021) ([#8874](https://github.com/community-scripts/ProxmoxVE/pull/8874))
    - Refactor(tools.func): Add Retry Logic, OS-Upgrade Safety, Smart Version Detection + 10 Critical Bugfixes [@MickLesk](https://github.com/MickLesk) ([#8871](https://github.com/community-scripts/ProxmoxVE/pull/8871))

### 🌐 Website

  - #### 📝 Script Information

    - npm: Increase RAM and HDD, update Certbot notes [@MickLesk](https://github.com/MickLesk) ([#8882](https://github.com/community-scripts/ProxmoxVE/pull/8882))
    - Update config_path in donetick.json [@fyxtro](https://github.com/fyxtro) ([#8872](https://github.com/community-scripts/ProxmoxVE/pull/8872))

## 2025-11-04

### 🚀 Updated Scripts

  - #### ✨ New Features

    - stirling-pdf: add native jbig2 dep to installation script [@MickLesk](https://github.com/MickLesk) ([#8858](https://github.com/community-scripts/ProxmoxVE/pull/8858))

## 2025-11-03

### 🆕 New Scripts

  - Donetick ([#8835](https://github.com/community-scripts/ProxmoxVE/pull/8835))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Immich: Pin version to 2.2.2 [@vhsdream](https://github.com/vhsdream) ([#8848](https://github.com/community-scripts/ProxmoxVE/pull/8848))
    - Asterisk: handle errors in version retrieval commands [@MickLesk](https://github.com/MickLesk) ([#8844](https://github.com/community-scripts/ProxmoxVE/pull/8844))
    - linkstack: fix wrong directory installation [@omertahaoztop](https://github.com/omertahaoztop) ([#8814](https://github.com/community-scripts/ProxmoxVE/pull/8814))
    - Remove BOM from shebang lines in ct scripts [@MickLesk](https://github.com/MickLesk) ([#8833](https://github.com/community-scripts/ProxmoxVE/pull/8833))

  - #### 💥 Breaking Changes

    - Removed: MeTube [@MickLesk](https://github.com/MickLesk) ([#8830](https://github.com/community-scripts/ProxmoxVE/pull/8830))

## 2025-11-02

### 🚀 Updated Scripts

  - Zigbee2MQTT: fix: pnpm workspace in update [@fkroeger](https://github.com/fkroeger) ([#8825](https://github.com/community-scripts/ProxmoxVE/pull/8825))

  - #### 🐞 Bug Fixes

    - Pangolin: Fix install and database migration [@tremor021](https://github.com/tremor021) ([#8828](https://github.com/community-scripts/ProxmoxVE/pull/8828))
    - MediaManager: fix BASE_PATH error preventing main page load [@vhsdream](https://github.com/vhsdream) ([#8821](https://github.com/community-scripts/ProxmoxVE/pull/8821))

## 2025-11-01

### 🆕 New Scripts

  - Pangolin ([#8809](https://github.com/community-scripts/ProxmoxVE/pull/8809))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - VictoriaMetrics: Fix release fetching for Victori Logs add-on [@tremor021](https://github.com/tremor021) ([#8807](https://github.com/community-scripts/ProxmoxVE/pull/8807))
    - Immich: Pin version to 2.2.1 [@vhsdream](https://github.com/vhsdream) ([#8800](https://github.com/community-scripts/ProxmoxVE/pull/8800))
    - jellyfin: fix: initial update [@CrazyWolf13](https://github.com/CrazyWolf13) ([#8784](https://github.com/community-scripts/ProxmoxVE/pull/8784))

### 🌐 Website

  - frontend: chore: bump debian OS [@CrazyWolf13](https://github.com/CrazyWolf13) ([#8798](https://github.com/community-scripts/ProxmoxVE/pull/8798))

## 2025-10-31

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Reitti: Fix missing data directory [@tremor021](https://github.com/tremor021) ([#8787](https://github.com/community-scripts/ProxmoxVE/pull/8787))
    - omada: fix update script with mongodb 8 [@MickLesk](https://github.com/MickLesk) ([#8724](https://github.com/community-scripts/ProxmoxVE/pull/8724))
    - Booklore: Fix port configuration for Nginx [@tremor021](https://github.com/tremor021) ([#8780](https://github.com/community-scripts/ProxmoxVE/pull/8780))
    - Fix paths in grist.sh [@mrinaldi](https://github.com/mrinaldi) ([#8777](https://github.com/community-scripts/ProxmoxVE/pull/8777))

### 🌐 Website

  - #### 📝 Script Information

    - Removed errant ` from wireguard.json [@AndrewDragonCh](https://github.com/AndrewDragonCh) ([#8791](https://github.com/community-scripts/ProxmoxVE/pull/8791))

## 2025-10-30

### 🆕 New Scripts

  - Livebook ([#8739](https://github.com/community-scripts/ProxmoxVE/pull/8739))
- Reitti ([#8736](https://github.com/community-scripts/ProxmoxVE/pull/8736))
- BentoPDF ([#8735](https://github.com/community-scripts/ProxmoxVE/pull/8735))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Open Archiver: Fix missing daemon-reload [@tremor021](https://github.com/tremor021) ([#8768](https://github.com/community-scripts/ProxmoxVE/pull/8768))
    - Open Archiver: Fix missing command in update procedure [@tremor021](https://github.com/tremor021) ([#8765](https://github.com/community-scripts/ProxmoxVE/pull/8765))
    - Kimai: Fix database connection string [@tremor021](https://github.com/tremor021) ([#8758](https://github.com/community-scripts/ProxmoxVE/pull/8758))
    - Add explicit exit calls to update_script functions [@MickLesk](https://github.com/MickLesk) ([#8752](https://github.com/community-scripts/ProxmoxVE/pull/8752))
    - kimai: Set global SQL mode to empty in install script [@MickLesk](https://github.com/MickLesk) ([#8747](https://github.com/community-scripts/ProxmoxVE/pull/8747))

  - #### ✨ New Features

    - Immich: Updates for v2.2.0 [@vhsdream](https://github.com/vhsdream) ([#8770](https://github.com/community-scripts/ProxmoxVE/pull/8770))
    - Standardize update success messages in scripts [@MickLesk](https://github.com/MickLesk) ([#8757](https://github.com/community-scripts/ProxmoxVE/pull/8757))
    - core: add function cleanup_lxc [@MickLesk](https://github.com/MickLesk) ([#8749](https://github.com/community-scripts/ProxmoxVE/pull/8749))
    - Asterisk: add interactive version selection to installer [@MickLesk](https://github.com/MickLesk) ([#8726](https://github.com/community-scripts/ProxmoxVE/pull/8726))

### 🌐 Website

  - #### 📝 Script Information

    - Cronicle: Update default credentials [@tremor021](https://github.com/tremor021) ([#8720](https://github.com/community-scripts/ProxmoxVE/pull/8720))

## 2025-10-29

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Docker-VM: add workaround for libguestfs issue on Proxmox VE 9+ [@MickLesk](https://github.com/MickLesk) ([#8722](https://github.com/community-scripts/ProxmoxVE/pull/8722))
    - Dispatcharr: add folders in installer / add more build ressources [@MickLesk](https://github.com/MickLesk) ([#8708](https://github.com/community-scripts/ProxmoxVE/pull/8708))
    - LibreTranslate: bump torch version [@MickLesk](https://github.com/MickLesk) ([#8710](https://github.com/community-scripts/ProxmoxVE/pull/8710))

  - #### ✨ New Features

    - Archivebox: add Chromium and Node modules [@MickLesk](https://github.com/MickLesk) ([#8725](https://github.com/community-scripts/ProxmoxVE/pull/8725))

  - #### 🔧 Refactor

    - tracktor: refactor envfile [@CrazyWolf13](https://github.com/CrazyWolf13) ([#8711](https://github.com/community-scripts/ProxmoxVE/pull/8711))
    - Kimai / Ghost / ManageMyDamnLife: Switch to MariaDB [@MickLesk](https://github.com/MickLesk) ([#8712](https://github.com/community-scripts/ProxmoxVE/pull/8712))

## 2025-10-28

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Update alpine-komodo.sh fixing missing pull images command [@glopes](https://github.com/glopes) ([#8689](https://github.com/community-scripts/ProxmoxVE/pull/8689))

  - #### ✨ New Features

    - Update SABnzbd. Include par2cmdline-turbo [@burgerga](https://github.com/burgerga) ([#8648](https://github.com/community-scripts/ProxmoxVE/pull/8648))
    - jotty: Add more ENV VARS (disabled) [@vhsdream](https://github.com/vhsdream) ([#8688](https://github.com/community-scripts/ProxmoxVE/pull/8688))
    - Bump bazarr to Debian 13 [@burgerga](https://github.com/burgerga) ([#8677](https://github.com/community-scripts/ProxmoxVE/pull/8677))
    - Update flaresolverr to Debian 13 [@burgerga](https://github.com/burgerga) ([#8672](https://github.com/community-scripts/ProxmoxVE/pull/8672))

## 2025-10-27

### 🆕 New Scripts

  - Dispatcharr ([#8658](https://github.com/community-scripts/ProxmoxVE/pull/8658))
- Garage | Alpine-Garage ([#8656](https://github.com/community-scripts/ProxmoxVE/pull/8656))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Add typescript and esbuild to browserless setup [@MickLesk](https://github.com/MickLesk) ([#8666](https://github.com/community-scripts/ProxmoxVE/pull/8666))
    - jellyfin: fix: intel deps [@CrazyWolf13](https://github.com/CrazyWolf13) ([#8657](https://github.com/community-scripts/ProxmoxVE/pull/8657))

## 2025-10-26

### 🆕 New Scripts

  - ComfyUI ([#8633](https://github.com/community-scripts/ProxmoxVE/pull/8633))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - PiHole: Bump to Debian 12 [@MickLesk](https://github.com/MickLesk) ([#8649](https://github.com/community-scripts/ProxmoxVE/pull/8649))

  - #### 🔧 Refactor

    - Refactor: Mylar3 [@tremor021](https://github.com/tremor021) ([#8642](https://github.com/community-scripts/ProxmoxVE/pull/8642))

## 2025-10-25

### 🆕 New Scripts

  - PatchMon ([#8632](https://github.com/community-scripts/ProxmoxVE/pull/8632))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - UrBackup Server: Fix install going interactive [@tremor021](https://github.com/tremor021) ([#8622](https://github.com/community-scripts/ProxmoxVE/pull/8622))

## 2025-10-24

### 🌐 Website

  - #### 📝 Script Information

    - Fix config path for BunkerWeb [@Nonolanlan1007](https://github.com/Nonolanlan1007) ([#8618](https://github.com/community-scripts/ProxmoxVE/pull/8618))
    - Update logo URL in guardian.json [@HydroshieldMKII](https://github.com/HydroshieldMKII) ([#8615](https://github.com/community-scripts/ProxmoxVE/pull/8615))

## 2025-10-23

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Radicale: Update dependencies [@ilofX](https://github.com/ilofX) ([#8603](https://github.com/community-scripts/ProxmoxVE/pull/8603))
    - Various Downgrades to Debian 12 (MySQL / OMW / Technitium)  [@MickLesk](https://github.com/MickLesk) ([#8595](https://github.com/community-scripts/ProxmoxVE/pull/8595))
    - MeTube: Fix inserting path into .bashrc [@tremor021](https://github.com/tremor021) ([#8589](https://github.com/community-scripts/ProxmoxVE/pull/8589))

  - #### 🔧 Refactor

    - Refactor: Kavita + Updated tools.func (no-same-owner) [@MickLesk](https://github.com/MickLesk) ([#8594](https://github.com/community-scripts/ProxmoxVE/pull/8594))
    - tools.func: update update_check messages for clarity [@MickLesk](https://github.com/MickLesk) ([#8588](https://github.com/community-scripts/ProxmoxVE/pull/8588))

## 2025-10-22

### 🚀 Updated Scripts

  - Refactor: Full Change & Feature-Bump of tools.func [@MickLesk](https://github.com/MickLesk) ([#8409](https://github.com/community-scripts/ProxmoxVE/pull/8409))

  - #### 🐞 Bug Fixes

    - part-db: use helper-script php function [@MickLesk](https://github.com/MickLesk) ([#8575](https://github.com/community-scripts/ProxmoxVE/pull/8575))
    - omada: remove static mongodb install [@MickLesk](https://github.com/MickLesk) ([#8577](https://github.com/community-scripts/ProxmoxVE/pull/8577))

## 2025-10-21

### 🆕 New Scripts

  - rwMarkable: migrate from rwMarkable => jotty [@vhsdream](https://github.com/vhsdream) ([#8554](https://github.com/community-scripts/ProxmoxVE/pull/8554))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Guardian: Added validation before copying file and fix build command error [@HydroshieldMKII](https://github.com/HydroshieldMKII) ([#8553](https://github.com/community-scripts/ProxmoxVE/pull/8553))
    - Unifi: Bump libssl debian version to new update [@fastiuk](https://github.com/fastiuk) ([#8547](https://github.com/community-scripts/ProxmoxVE/pull/8547))
    - Alpine-TeamSpeak-Server: Fix release version fetching [@tremor021](https://github.com/tremor021) ([#8537](https://github.com/community-scripts/ProxmoxVE/pull/8537))
    - jellyfin: fix opencl dep for ubuntu [@MickLesk](https://github.com/MickLesk) ([#8535](https://github.com/community-scripts/ProxmoxVE/pull/8535))

  - #### ✨ New Features

    - Refactor: ProjectSend [@tremor021](https://github.com/tremor021) ([#8552](https://github.com/community-scripts/ProxmoxVE/pull/8552))

### 🌐 Website

  - #### 📝 Script Information

    - Open Archiver: Fix application icon [@tremor021](https://github.com/tremor021) ([#8542](https://github.com/community-scripts/ProxmoxVE/pull/8542))

## 2025-10-20

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - jellyfin: fix: version conflict [@CrazyWolf13](https://github.com/CrazyWolf13) ([#8520](https://github.com/community-scripts/ProxmoxVE/pull/8520))
    - Paperless-AI: Increase CPU and RAM [@MickLesk](https://github.com/MickLesk) ([#8507](https://github.com/community-scripts/ProxmoxVE/pull/8507))

  - #### ✨ New Features

    - Enhance error message for container creation failure [@MickLesk](https://github.com/MickLesk) ([#8511](https://github.com/community-scripts/ProxmoxVE/pull/8511))
    - Filebrowser-Quantum: change initial config to newer default [@MickLesk](https://github.com/MickLesk) ([#8497](https://github.com/community-scripts/ProxmoxVE/pull/8497))

  - #### 💥 Breaking Changes

    - Remove: GoMFT [@MickLesk](https://github.com/MickLesk) ([#8499](https://github.com/community-scripts/ProxmoxVE/pull/8499))

  - #### 🔧 Refactor

    - palmr: update node to v24 [@CrazyWolf13](https://github.com/CrazyWolf13) ([#8521](https://github.com/community-scripts/ProxmoxVE/pull/8521))
    - jellyfin: add: intel dependencies [@CrazyWolf13](https://github.com/CrazyWolf13) ([#8508](https://github.com/community-scripts/ProxmoxVE/pull/8508))
    - Jellyfin: ensure libjemalloc is used / increase hdd space [@MickLesk](https://github.com/MickLesk) ([#8494](https://github.com/community-scripts/ProxmoxVE/pull/8494))

## 2025-10-19

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - rwMarkable: Increase RAM [@vhsdream](https://github.com/vhsdream) ([#8482](https://github.com/community-scripts/ProxmoxVE/pull/8482))
    - changedetection: fix: update [@CrazyWolf13](https://github.com/CrazyWolf13) ([#8480](https://github.com/community-scripts/ProxmoxVE/pull/8480))

## 2025-10-18

### 🆕 New Scripts

  - Open-Archiver ([#8452](https://github.com/community-scripts/ProxmoxVE/pull/8452))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Cronicle: Dont copy init.d service file [@tremor021](https://github.com/tremor021) ([#8451](https://github.com/community-scripts/ProxmoxVE/pull/8451))

  - #### 🔧 Refactor

    - Refactor: Nginx Proxy Manager [@MickLesk](https://github.com/MickLesk) ([#8453](https://github.com/community-scripts/ProxmoxVE/pull/8453))

## 2025-10-17

### 🚀 Updated Scripts

  - Revert back to debian 12 template for various apps [@tremor021](https://github.com/tremor021) ([#8431](https://github.com/community-scripts/ProxmoxVE/pull/8431))

  - #### 🐞 Bug Fixes

    - [FIX]Pulse: replace policykit-1 with polkitd [@vhsdream](https://github.com/vhsdream) ([#8439](https://github.com/community-scripts/ProxmoxVE/pull/8439))
    - MySpeed: Fix build step [@tremor021](https://github.com/tremor021) ([#8427](https://github.com/community-scripts/ProxmoxVE/pull/8427))

  - #### ✨ New Features

    - GLPI: Bump to Debian 13 base [@tremor021](https://github.com/tremor021) ([#8443](https://github.com/community-scripts/ProxmoxVE/pull/8443))

  - #### 🔧 Refactor

    - refactor: fix pve-scripts local install script [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#8418](https://github.com/community-scripts/ProxmoxVE/pull/8418))

### 🌐 Website

  - #### 📝 Script Information

    - PLANKA: Fix config path [@tremor021](https://github.com/tremor021) ([#8422](https://github.com/community-scripts/ProxmoxVE/pull/8422))

## 2025-10-16

### 🚀 Updated Scripts

  - post-pve/post-pbs: Disable 'pve-enterprise' and 'ceph enterprise' repositories [@MickLesk](https://github.com/MickLesk) ([#8399](https://github.com/community-scripts/ProxmoxVE/pull/8399))

  - #### 🐞 Bug Fixes

    - fix: changedetection: fix for tsc and esbuild not found [@CrazyWolf13](https://github.com/CrazyWolf13) ([#8407](https://github.com/community-scripts/ProxmoxVE/pull/8407))
    - paperless-ngx: remove unneeded deps, use static ghostscript [@MickLesk](https://github.com/MickLesk) ([#8397](https://github.com/community-scripts/ProxmoxVE/pull/8397))
    - UmlautAdaptarr: Revert back to bookworm repo [@tremor021](https://github.com/tremor021) ([#8392](https://github.com/community-scripts/ProxmoxVE/pull/8392))

  - #### 🔧 Refactor

    - Enhance nginx proxy manager install script [@MickLesk](https://github.com/MickLesk) ([#8400](https://github.com/community-scripts/ProxmoxVE/pull/8400))

## 2025-10-15

### 🆕 New Scripts

  - LimeSurvey ([#8364](https://github.com/community-scripts/ProxmoxVE/pull/8364))
- Guardian ([#8365](https://github.com/community-scripts/ProxmoxVE/pull/8365))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Update omada-install.sh to use correct libssl version [@punctualwesley](https://github.com/punctualwesley) ([#8380](https://github.com/community-scripts/ProxmoxVE/pull/8380))
    - zigbee2mqtt: Use hardlinks for PNPM packages [@mikeage](https://github.com/mikeage) ([#8357](https://github.com/community-scripts/ProxmoxVE/pull/8357))

  - #### ✨ New Features

    - Bump Q to S-Scripts to Debian 13 (Trixie) [@MickLesk](https://github.com/MickLesk) ([#8366](https://github.com/community-scripts/ProxmoxVE/pull/8366))
    - Bump O to P-Scripts to Debian 13 (Trixie) [@MickLesk](https://github.com/MickLesk) ([#8367](https://github.com/community-scripts/ProxmoxVE/pull/8367))
    - Bump L to N-Scripts to Debian 13 (Trixie) [@MickLesk](https://github.com/MickLesk) ([#8368](https://github.com/community-scripts/ProxmoxVE/pull/8368))
    - Immich: v2.1.0 - VectorChord 0.5+ support [@vhsdream](https://github.com/vhsdream) ([#8348](https://github.com/community-scripts/ProxmoxVE/pull/8348))

## 2025-10-14

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - MediaManager: Use managed Python 3.13 [@vhsdream](https://github.com/vhsdream) ([#8343](https://github.com/community-scripts/ProxmoxVE/pull/8343))

  - #### 🔧 Refactor

    - Update cockpit installation/update [@burgerga](https://github.com/burgerga) ([#8346](https://github.com/community-scripts/ProxmoxVE/pull/8346))

## 2025-10-13

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - GLPI: fix version 11 [@opastorello](https://github.com/opastorello) ([#8238](https://github.com/community-scripts/ProxmoxVE/pull/8238))
    - Keycloak: Fix typo in update function [@tremor021](https://github.com/tremor021) ([#8316](https://github.com/community-scripts/ProxmoxVE/pull/8316))

  - #### 🔧 Refactor

    - fix: adjust configarr to use binaries [@BlackDark](https://github.com/BlackDark) ([#8254](https://github.com/community-scripts/ProxmoxVE/pull/8254))

## 2025-10-12

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Immich: add Debian Testing repo [@vhsdream](https://github.com/vhsdream) ([#8310](https://github.com/community-scripts/ProxmoxVE/pull/8310))
    - Tinyauth: Fix install issues for v4 [@tremor021](https://github.com/tremor021) ([#8309](https://github.com/community-scripts/ProxmoxVE/pull/8309))

## 2025-10-11

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Zabbix: various bugfixes agent1/agent2 [@MickLesk](https://github.com/MickLesk) ([#8294](https://github.com/community-scripts/ProxmoxVE/pull/8294))
    - wger: fix python and pip install [@MickLesk](https://github.com/MickLesk) ([#8295](https://github.com/community-scripts/ProxmoxVE/pull/8295))
    - searxng: add msgspec as dependency [@MickLesk](https://github.com/MickLesk) ([#8293](https://github.com/community-scripts/ProxmoxVE/pull/8293))
    - keycloak: fix update check [@MickLesk](https://github.com/MickLesk) ([#8275](https://github.com/community-scripts/ProxmoxVE/pull/8275))
    - komga: fix update check [@MickLesk](https://github.com/MickLesk) ([#8285](https://github.com/community-scripts/ProxmoxVE/pull/8285))

  - #### ✨ New Features

    - host-backup.sh: Added "ALL" option and include timestamp in backup filename [@stumpyofpain](https://github.com/stumpyofpain) ([#8276](https://github.com/community-scripts/ProxmoxVE/pull/8276))
    - Komga: Update dependencies and enable RAR5 support [@tremor021](https://github.com/tremor021) ([#8257](https://github.com/community-scripts/ProxmoxVE/pull/8257))

### 🌐 Website

  - Update script count in metadata and page content from 300+ to 400+ [@BramSuurdje](https://github.com/BramSuurdje) ([#8279](https://github.com/community-scripts/ProxmoxVE/pull/8279))
- Refactor CI workflow to use Bun instead of Node.js. [@BramSuurdje](https://github.com/BramSuurdje) ([#8277](https://github.com/community-scripts/ProxmoxVE/pull/8277))

## 2025-10-10

### 🆕 New Scripts

  - Prometheus-Blackbox-Exporter ([#8255](https://github.com/community-scripts/ProxmoxVE/pull/8255))
- SonarQube ([#8256](https://github.com/community-scripts/ProxmoxVE/pull/8256))

### 🚀 Updated Scripts

  - Unifi installation script fix [@knightfall](https://github.com/knightfall) ([#8242](https://github.com/community-scripts/ProxmoxVE/pull/8242))

  - #### 🐞 Bug Fixes

    - Docmost: Fix env variables [@tremor021](https://github.com/tremor021) ([#8244](https://github.com/community-scripts/ProxmoxVE/pull/8244))

  - #### 🔧 Refactor

    - Harmonize Service MSG-Blocks [@MickLesk](https://github.com/MickLesk) ([#8233](https://github.com/community-scripts/ProxmoxVE/pull/8233))

## 2025-10-09

### 🆕 New Scripts

  - New Script: rwMarkable ([#8215](https://github.com/community-scripts/ProxmoxVE/pull/8215))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Alpine-Tinyauth: Fixes for v4 release [@tremor021](https://github.com/tremor021) ([#8225](https://github.com/community-scripts/ProxmoxVE/pull/8225))

  - #### ✨ New Features

    - Bump U-T Scripts to Debian 13 [@MickLesk](https://github.com/MickLesk) ([#8227](https://github.com/community-scripts/ProxmoxVE/pull/8227))

## 2025-10-08

### 🚀 Updated Scripts

  - MyIP: Increase resources [@tremor021](https://github.com/tremor021) ([#8199](https://github.com/community-scripts/ProxmoxVE/pull/8199))

  - #### 🐞 Bug Fixes

    - Wireguard: Fix sysctl for Trixie [@tremor021](https://github.com/tremor021) ([#8209](https://github.com/community-scripts/ProxmoxVE/pull/8209))
    - Update prompt for Stirling-PDF login option [@EarMaster](https://github.com/EarMaster) ([#8196](https://github.com/community-scripts/ProxmoxVE/pull/8196))

  - #### 🔧 Refactor

    - Refactor: Fixed incorrect tag variables in several scripts [@tremor021](https://github.com/tremor021) ([#8182](https://github.com/community-scripts/ProxmoxVE/pull/8182))
    - ZeroTier One: Fix install output [@tremor021](https://github.com/tremor021) ([#8179](https://github.com/community-scripts/ProxmoxVE/pull/8179))

## 2025-10-07

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Alpine-Caddy: remove functions [@MickLesk](https://github.com/MickLesk) ([#8177](https://github.com/community-scripts/ProxmoxVE/pull/8177))
    - Palmr: Fix NodeJS setup [@tremor021](https://github.com/tremor021) ([#8173](https://github.com/community-scripts/ProxmoxVE/pull/8173))
    - GLPI: Fix UNBOUND variable [@tremor021](https://github.com/tremor021) ([#8167](https://github.com/community-scripts/ProxmoxVE/pull/8167))
    - BookLore: upgrade to Java 25/Gradle 9 [@vhsdream](https://github.com/vhsdream) ([#8165](https://github.com/community-scripts/ProxmoxVE/pull/8165))
    - Alpine-Wireguard: Fix for update failing in normal mode [@tremor021](https://github.com/tremor021) ([#8160](https://github.com/community-scripts/ProxmoxVE/pull/8160))

  - #### ✨ New Features

    - Bump W-V Scripts to Debian 13 [@MickLesk](https://github.com/MickLesk) ([#8176](https://github.com/community-scripts/ProxmoxVE/pull/8176))
    - Bump Z-Y Scripts to Debian 13 [@MickLesk](https://github.com/MickLesk) ([#8174](https://github.com/community-scripts/ProxmoxVE/pull/8174))
    - Docmost: Fixes and updates [@tremor021](https://github.com/tremor021) ([#8158](https://github.com/community-scripts/ProxmoxVE/pull/8158))

## 2025-10-06

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - GLPI: Revert fix for v11 [@tremor021](https://github.com/tremor021) ([#8148](https://github.com/community-scripts/ProxmoxVE/pull/8148))

  - #### ✨ New Features

    - Node-Red: bump to Debian 13 [@MickLesk](https://github.com/MickLesk) ([#8141](https://github.com/community-scripts/ProxmoxVE/pull/8141))
    - NocoDB: bump to Debian 13 [@MickLesk](https://github.com/MickLesk) ([#8140](https://github.com/community-scripts/ProxmoxVE/pull/8140))
    - Navidrome: bump to Debian 13 [@MickLesk](https://github.com/MickLesk) ([#8139](https://github.com/community-scripts/ProxmoxVE/pull/8139))
    - pve-scripts-local: add update function [@MickLesk](https://github.com/MickLesk) ([#8138](https://github.com/community-scripts/ProxmoxVE/pull/8138))

### 🌐 Website

  - #### 📝 Script Information

    - Update config_path for Zigbee2MQTT configuration [@MickLesk](https://github.com/MickLesk) ([#8153](https://github.com/community-scripts/ProxmoxVE/pull/8153))

## 2025-10-05

### 🚀 Updated Scripts

  - #### ✨ New Features

    - ActualBudget: bump to debian 13 [@MickLesk](https://github.com/MickLesk) ([#8124](https://github.com/community-scripts/ProxmoxVE/pull/8124))
    - 2fauth: bump to debian 13 [@MickLesk](https://github.com/MickLesk) ([#8123](https://github.com/community-scripts/ProxmoxVE/pull/8123))
    - AdventureLog: bump to debian 13 [@MickLesk](https://github.com/MickLesk) ([#8125](https://github.com/community-scripts/ProxmoxVE/pull/8125))
    - Update cockpit to Debian 13 [@burgerga](https://github.com/burgerga) ([#8119](https://github.com/community-scripts/ProxmoxVE/pull/8119))

## 2025-10-04

### 🚀 Updated Scripts

  - immich: guard /dev/dri permissions so CPU-only installs don’t fail [@mlongwell](https://github.com/mlongwell) ([#8094](https://github.com/community-scripts/ProxmoxVE/pull/8094))

  - #### ✨ New Features

    - PosgreSQL: Add version choice [@tremor021](https://github.com/tremor021) ([#8103](https://github.com/community-scripts/ProxmoxVE/pull/8103))

## 2025-10-03

### 🆕 New Scripts

  - pve-scripts-local ([#8083](https://github.com/community-scripts/ProxmoxVE/pull/8083))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - GLPI: Pin version to v10.0.20 [@tremor021](https://github.com/tremor021) ([#8092](https://github.com/community-scripts/ProxmoxVE/pull/8092))
    - GLPI: Fix database setup [@tremor021](https://github.com/tremor021) ([#8074](https://github.com/community-scripts/ProxmoxVE/pull/8074))
    - Overseerr: Increase resources [@tremor021](https://github.com/tremor021) ([#8086](https://github.com/community-scripts/ProxmoxVE/pull/8086))
    - FIX: post-pve-install.sh just quitting [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#8070](https://github.com/community-scripts/ProxmoxVE/pull/8070))
    - fix: ensure /etc/pulse exists before chown in update script [@rcourtman](https://github.com/rcourtman) ([#8068](https://github.com/community-scripts/ProxmoxVE/pull/8068))
    - grist: remove unneeded var [@MickLesk](https://github.com/MickLesk) ([#8060](https://github.com/community-scripts/ProxmoxVE/pull/8060))

  - #### 🔧 Refactor

    - Immich: bump version to 2.0.1 [@vhsdream](https://github.com/vhsdream) ([#8090](https://github.com/community-scripts/ProxmoxVE/pull/8090))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - Adjust navbar layout for large screen [@BramSuurdje](https://github.com/BramSuurdje) ([#8087](https://github.com/community-scripts/ProxmoxVE/pull/8087))

## 2025-10-02

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - EMQX: removal logic in emqx update [@MickLesk](https://github.com/MickLesk) ([#8050](https://github.com/community-scripts/ProxmoxVE/pull/8050))
    - fix FlareSolverr version check to v3.3.25 [@MickLesk](https://github.com/MickLesk) ([#8051](https://github.com/community-scripts/ProxmoxVE/pull/8051))

## 2025-10-01

### 🆕 New Scripts

  - New Script: PhpMyAdmin (Addon) [@MickLesk](https://github.com/MickLesk) ([#8030](https://github.com/community-scripts/ProxmoxVE/pull/8030))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - openwrt: Add conditional logic for EFI disk allocation [@MickLesk](https://github.com/MickLesk) ([#8024](https://github.com/community-scripts/ProxmoxVE/pull/8024))
    - Plant-IT: Pin version to v0.10.0 [@tremor021](https://github.com/tremor021) ([#8023](https://github.com/community-scripts/ProxmoxVE/pull/8023))

  - #### ✨ New Features

    - Immich: bump version to 2.0.0 stable [@vhsdream](https://github.com/vhsdream) ([#8041](https://github.com/community-scripts/ProxmoxVE/pull/8041))

  - #### 🔧 Refactor

    - Immich: bump version to 1.144.1 [@vhsdream](https://github.com/vhsdream) ([#7994](https://github.com/community-scripts/ProxmoxVE/pull/7994))

## 2025-09-30

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - caddy: fix typo for setup_go [@MickLesk](https://github.com/MickLesk) ([#8017](https://github.com/community-scripts/ProxmoxVE/pull/8017))
    - Changedetection: Fix Browserless installation and update process [@h-stoyanov](https://github.com/h-stoyanov) ([#8011](https://github.com/community-scripts/ProxmoxVE/pull/8011))
    - n8n: Update procedure workaround [@tremor021](https://github.com/tremor021) ([#8004](https://github.com/community-scripts/ProxmoxVE/pull/8004))
    - Changedetection: Bump nodejs to 24 [@MickLesk](https://github.com/MickLesk) ([#8002](https://github.com/community-scripts/ProxmoxVE/pull/8002))

  - #### ✨ New Features

    - Bump Guacamole to Debian 13 [@burgerga](https://github.com/burgerga) ([#8010](https://github.com/community-scripts/ProxmoxVE/pull/8010))

## 2025-09-29

### 🆕 New Scripts

  - Ghostfolio ([#7982](https://github.com/community-scripts/ProxmoxVE/pull/7982))
- Warracker ([#7977](https://github.com/community-scripts/ProxmoxVE/pull/7977))
- MyIP ([#7974](https://github.com/community-scripts/ProxmoxVE/pull/7974))
- Verdaccio ([#7967](https://github.com/community-scripts/ProxmoxVE/pull/7967))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - fix sidebar loading issues and navbar on mobile [@BramSuurdje](https://github.com/BramSuurdje) ([#7991](https://github.com/community-scripts/ProxmoxVE/pull/7991))

  - #### ✨ New Features

    - Improve mobile ui: added a hamburger navigation to the mobile view. [@BramSuurdje](https://github.com/BramSuurdje) ([#7987](https://github.com/community-scripts/ProxmoxVE/pull/7987))

  - #### 📝 Script Information

    - Remove Frigate from Website [@MickLesk](https://github.com/MickLesk) ([#7972](https://github.com/community-scripts/ProxmoxVE/pull/7972))

## 2025-09-28

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Metube: remove uv flags [@vhsdream](https://github.com/vhsdream) ([#7962](https://github.com/community-scripts/ProxmoxVE/pull/7962))
    - freshrss: fix for broken permissions after update [@CrazyWolf13](https://github.com/CrazyWolf13) ([#7953](https://github.com/community-scripts/ProxmoxVE/pull/7953))

## 2025-09-27

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - GoAway: Make admin password aquisition more reliable [@tremor021](https://github.com/tremor021) ([#7946](https://github.com/community-scripts/ProxmoxVE/pull/7946))
    - MeTube: Various fixes [@vhsdream](https://github.com/vhsdream) ([#7936](https://github.com/community-scripts/ProxmoxVE/pull/7936))
    - Oddo: Fix typo in update procedure [@tremor021](https://github.com/tremor021) ([#7941](https://github.com/community-scripts/ProxmoxVE/pull/7941))

## 2025-09-26

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Odoo: Fix missing dependencies [@tremor021](https://github.com/tremor021) ([#7931](https://github.com/community-scripts/ProxmoxVE/pull/7931))
    - OpenWebUI: Update NODE_OPTIONS to increase memory limit [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#7919](https://github.com/community-scripts/ProxmoxVE/pull/7919))

### 🌐 Website

  - #### 📝 Script Information

    - Clarify descriptions of update scripts [@tremor021](https://github.com/tremor021) ([#7929](https://github.com/community-scripts/ProxmoxVE/pull/7929))

## 2025-09-25

### 🆕 New Scripts

  - GoAway ([#7900](https://github.com/community-scripts/ProxmoxVE/pull/7900))

### 🚀 Updated Scripts

  - #### ✨ New Features

    - ntfy: bump to debian 13 [@CrazyWolf13](https://github.com/CrazyWolf13) ([#7895](https://github.com/community-scripts/ProxmoxVE/pull/7895))

### 🌐 Website

  - #### ✨ New Features

    - feat: add menu icons to website [@BramSuurdje](https://github.com/BramSuurdje) ([#7894](https://github.com/community-scripts/ProxmoxVE/pull/7894))

## 2025-09-24

### 🆕 New Scripts

  - Add Script: Joplin Server ([#7879](https://github.com/community-scripts/ProxmoxVE/pull/7879))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Monica: Fix dependencies [@tremor021](https://github.com/tremor021) ([#7877](https://github.com/community-scripts/ProxmoxVE/pull/7877))

### 🌐 Website

  - #### 📝 Script Information

    - Update name in lxc-delete.json to 'PVE LXC Deletion' [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#7872](https://github.com/community-scripts/ProxmoxVE/pull/7872))

## 2025-09-23

### 🆕 New Scripts

  - UpSnap ([#7825](https://github.com/community-scripts/ProxmoxVE/pull/7825))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - tools.func: Check for /usr/local/bin in PATH during yq setup [@vhsdream](https://github.com/vhsdream) ([#7856](https://github.com/community-scripts/ProxmoxVE/pull/7856))
    - BookLore: increase RAM [@vhsdream](https://github.com/vhsdream) ([#7855](https://github.com/community-scripts/ProxmoxVE/pull/7855))
    - Bump Immich to v1.143.1 [@vhsdream](https://github.com/vhsdream) ([#7864](https://github.com/community-scripts/ProxmoxVE/pull/7864))
    - zabbix: Remove not exist admin credentials from output [@MickLesk](https://github.com/MickLesk) ([#7849](https://github.com/community-scripts/ProxmoxVE/pull/7849))
    - Suppress wrong errors from uv shell integration in setup_uv [@MickLesk](https://github.com/MickLesk) ([#7822](https://github.com/community-scripts/ProxmoxVE/pull/7822))
    - Refactor Caddyfile configuration for headscale-admin [@MickLesk](https://github.com/MickLesk) ([#7821](https://github.com/community-scripts/ProxmoxVE/pull/7821))
    - Improve subscription element removal (mobile) in post-pve script [@MickLesk](https://github.com/MickLesk) ([#7814](https://github.com/community-scripts/ProxmoxVE/pull/7814))
    - Blocky: Fix release fetching [@tremor021](https://github.com/tremor021) ([#7807](https://github.com/community-scripts/ProxmoxVE/pull/7807))

  - #### ✨ New Features

    - Improve globaleaks install ensuring install can proceed without user … [@evilaliv3](https://github.com/evilaliv3) ([#7860](https://github.com/community-scripts/ProxmoxVE/pull/7860))
    - Manage My Damn Life: use NodeJS 22 [@vhsdream](https://github.com/vhsdream) ([#7861](https://github.com/community-scripts/ProxmoxVE/pull/7861))
    - VM: Increase pv & xz functions (HA OS / Umbrel OS) [@MickLesk](https://github.com/MickLesk) ([#7838](https://github.com/community-scripts/ProxmoxVE/pull/7838))
    - Tandoor: update for newer dependencies (psql) + bump nodejs to 22 [@MickLesk](https://github.com/MickLesk) ([#7826](https://github.com/community-scripts/ProxmoxVE/pull/7826))
    - Update Monica and Outline to use Node.js 22 [@MickLesk](https://github.com/MickLesk) ([#7833](https://github.com/community-scripts/ProxmoxVE/pull/7833))
    - Update Zabbix install for Debian 13 and agent selection [@MickLesk](https://github.com/MickLesk) ([#7819](https://github.com/community-scripts/ProxmoxVE/pull/7819))
    - tracktor: bump to debian 13 | feature bump [@CrazyWolf13](https://github.com/CrazyWolf13) ([#7818](https://github.com/community-scripts/ProxmoxVE/pull/7818))
    - LiteLLM: Bump to Debian 13 & add deps [@MickLesk](https://github.com/MickLesk) ([#7815](https://github.com/community-scripts/ProxmoxVE/pull/7815))
    - Immich: bump to v1.143.0 [@vhsdream](https://github.com/vhsdream) ([#7801](https://github.com/community-scripts/ProxmoxVE/pull/7801))

### 🧰 Maintenance

  - #### 📂 Github

    - gh: remove ai autolabel test [@MickLesk](https://github.com/MickLesk) ([#7817](https://github.com/community-scripts/ProxmoxVE/pull/7817))

### 🌐 Website

  - #### 📝 Script Information

    - OpenWebUI: Add information about Ollama [@tremor021](https://github.com/tremor021) ([#7843](https://github.com/community-scripts/ProxmoxVE/pull/7843))
    - cosmos: add info note for configuration file [@MickLesk](https://github.com/MickLesk) ([#7824](https://github.com/community-scripts/ProxmoxVE/pull/7824))
    - ElementSynapse: add note for Bridge Install Methods [@MickLesk](https://github.com/MickLesk) ([#7820](https://github.com/community-scripts/ProxmoxVE/pull/7820))

## 2025-09-22

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - [core]: Update detection of current running subshell [@tremor021](https://github.com/tremor021) ([#7796](https://github.com/community-scripts/ProxmoxVE/pull/7796))
    - Paymenter: Installation and update fixes [@tremor021](https://github.com/tremor021) ([#7792](https://github.com/community-scripts/ProxmoxVE/pull/7792))

## 2025-09-21

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - fix openwebui update and installer [@HeedfulCrayon](https://github.com/HeedfulCrayon) ([#7788](https://github.com/community-scripts/ProxmoxVE/pull/7788))
    - tracktor: add: cleanup before upgrade [@CrazyWolf13](https://github.com/CrazyWolf13) ([#7782](https://github.com/community-scripts/ProxmoxVE/pull/7782))
    - Fix regex to extract MySQL version correctly [@MickLesk](https://github.com/MickLesk) ([#7774](https://github.com/community-scripts/ProxmoxVE/pull/7774))
    - Update Ollama Installer in OpenWebUI to resume downloads if interrupted [@HeedfulCrayon](https://github.com/HeedfulCrayon) ([#7779](https://github.com/community-scripts/ProxmoxVE/pull/7779))

  - #### ✨ New Features

    - Implement clean install option in tools.func (fetch_and_deploy_gh_release) [@MickLesk](https://github.com/MickLesk) ([#7785](https://github.com/community-scripts/ProxmoxVE/pull/7785))
    - caddy: modify disk size and implement xCaddy update [@MickLesk](https://github.com/MickLesk) ([#7775](https://github.com/community-scripts/ProxmoxVE/pull/7775))

### 🌐 Website

  - #### 📝 Script Information

    - Harmonize  and shorten JSON Names for PVE/PBS/PMG [@MickLesk](https://github.com/MickLesk) ([#7773](https://github.com/community-scripts/ProxmoxVE/pull/7773))

## 2025-09-20

### 🚀 Updated Scripts

  - checkmk.sh Update: Revert old Pr  [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#7765](https://github.com/community-scripts/ProxmoxVE/pull/7765))

  - #### 🐞 Bug Fixes

    - Wazuh: Increase HDD size [@tremor021](https://github.com/tremor021) ([#7759](https://github.com/community-scripts/ProxmoxVE/pull/7759))

### 🧰 Maintenance

  - #### 📂 Github

    - Add Debian 13 in bug report template [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#7757](https://github.com/community-scripts/ProxmoxVE/pull/7757))

## 2025-09-19

### 🆕 New Scripts

  - Tunarr ([#7735](https://github.com/community-scripts/ProxmoxVE/pull/7735))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - SigNoz: Fix wrong URL for Zookeeper [@tremor021](https://github.com/tremor021) ([#7742](https://github.com/community-scripts/ProxmoxVE/pull/7742))

## 2025-09-18

### 🆕 New Scripts

  - Alpine-Caddy [@tremor021](https://github.com/tremor021) ([#7711](https://github.com/community-scripts/ProxmoxVE/pull/7711))
- pve-tool: execute.sh by @jeroenzwart [@MickLesk](https://github.com/MickLesk) ([#7708](https://github.com/community-scripts/ProxmoxVE/pull/7708))
- GlobaLeaks ([#7707](https://github.com/community-scripts/ProxmoxVE/pull/7707))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Delay chmod after updating beszel [@CrazyWolf13](https://github.com/CrazyWolf13) ([#7725](https://github.com/community-scripts/ProxmoxVE/pull/7725))
    - Remove redundant globaleaks configuration [@evilaliv3](https://github.com/evilaliv3) ([#7723](https://github.com/community-scripts/ProxmoxVE/pull/7723))
    - Gatus: check for GO path before update [@vhsdream](https://github.com/vhsdream) ([#7705](https://github.com/community-scripts/ProxmoxVE/pull/7705))

  - #### ✨ New Features

    - Cloudflared: Bump to Debian 13 [@MickLesk](https://github.com/MickLesk) ([#7719](https://github.com/community-scripts/ProxmoxVE/pull/7719))
    - AdGuard Home: Bump to Debian 13 [@MickLesk](https://github.com/MickLesk) ([#7720](https://github.com/community-scripts/ProxmoxVE/pull/7720))

  - #### 🔧 Refactor

    - Immich: Debian Trixie [@vhsdream](https://github.com/vhsdream) ([#7728](https://github.com/community-scripts/ProxmoxVE/pull/7728))

### 🌐 Website

  - #### 📝 Script Information

    - Add Warning for Containerized Home Assistant [@ZaxLofful](https://github.com/ZaxLofful) ([#7704](https://github.com/community-scripts/ProxmoxVE/pull/7704))

## 2025-09-17

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - beszel: fix: binary permission after upgrade [@CrazyWolf13](https://github.com/CrazyWolf13) ([#7697](https://github.com/community-scripts/ProxmoxVE/pull/7697))
    - RabbitMQ: Update repositories [@tremor021](https://github.com/tremor021) ([#7689](https://github.com/community-scripts/ProxmoxVE/pull/7689))
    - Komodo: Add docker compose pull for actually updating docker container [@hanneshier](https://github.com/hanneshier) ([#7682](https://github.com/community-scripts/ProxmoxVE/pull/7682))

  - #### ✨ New Features

    - Debian-LXC: Bump to Debian 13 Trixie [@MickLesk](https://github.com/MickLesk) ([#7683](https://github.com/community-scripts/ProxmoxVE/pull/7683))
    - Bump Immich to v1.142.1 [@vhsdream](https://github.com/vhsdream) ([#7675](https://github.com/community-scripts/ProxmoxVE/pull/7675))

  - #### 🔧 Refactor

    - Refactor: Grist [@tremor021](https://github.com/tremor021) ([#7681](https://github.com/community-scripts/ProxmoxVE/pull/7681))

### 🧰 Maintenance

  - #### 📂 Github

    - Improve: SECURITY.md for clarity and detail + Adding PVE9 as supported [@MickLesk](https://github.com/MickLesk) ([#7690](https://github.com/community-scripts/ProxmoxVE/pull/7690))

## 2025-09-16

### 🚀 Updated Scripts

  - Improve OpenWrt VM boot and readiness check [@MickLesk](https://github.com/MickLesk) ([#7669](https://github.com/community-scripts/ProxmoxVE/pull/7669))

  - #### 🐞 Bug Fixes

    - hortusfox: fix update check [@MickLesk](https://github.com/MickLesk) ([#7667](https://github.com/community-scripts/ProxmoxVE/pull/7667))

## 2025-09-15

### 🆕 New Scripts

  - SigNoz ([#7648](https://github.com/community-scripts/ProxmoxVE/pull/7648))
- Scraparr ([#7644](https://github.com/community-scripts/ProxmoxVE/pull/7644))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - vm: move pv installation into ensure_pv function [@MickLesk](https://github.com/MickLesk) ([#7642](https://github.com/community-scripts/ProxmoxVE/pull/7642))
    - Cloudflare-DDNS: Fix the IP6_PROVIDER variable [@hugodantas](https://github.com/hugodantas) ([#7660](https://github.com/community-scripts/ProxmoxVE/pull/7660))
    - Wikijs: Bump Node.js version to 22 [@MickLesk](https://github.com/MickLesk) ([#7643](https://github.com/community-scripts/ProxmoxVE/pull/7643))

## 2025-09-14

## 2025-09-13

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Palmr: hotfix #7622 [@vhsdream](https://github.com/vhsdream) ([#7625](https://github.com/community-scripts/ProxmoxVE/pull/7625))
    - ollama: fix: ccurl continue on interrupts [@CrazyWolf13](https://github.com/CrazyWolf13) ([#7620](https://github.com/community-scripts/ProxmoxVE/pull/7620))

  - #### 🔧 Refactor

    - pdm: refactor for beta version [@CrazyWolf13](https://github.com/CrazyWolf13) ([#7619](https://github.com/community-scripts/ProxmoxVE/pull/7619))
    - Immich: bump to v1.142.0 [@vhsdream](https://github.com/vhsdream) ([#7594](https://github.com/community-scripts/ProxmoxVE/pull/7594))

### 🌐 Website

  - fix: tagline grammar [@jonathanwuki](https://github.com/jonathanwuki) ([#7621](https://github.com/community-scripts/ProxmoxVE/pull/7621))
- fix: grammar/capitalization for links and taglines [@jonathanwuki](https://github.com/jonathanwuki) ([#7609](https://github.com/community-scripts/ProxmoxVE/pull/7609))

## 2025-09-12

### 🆕 New Scripts

  - Stylus ([#7588](https://github.com/community-scripts/ProxmoxVE/pull/7588))
- UHF ([#7589](https://github.com/community-scripts/ProxmoxVE/pull/7589))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Tweak: post-pve-install: create folder if Not exist  [@JVKeller](https://github.com/JVKeller) ([#7598](https://github.com/community-scripts/ProxmoxVE/pull/7598))
    - Update openwebui.sh [@webmogul1](https://github.com/webmogul1) ([#7582](https://github.com/community-scripts/ProxmoxVE/pull/7582))

  - #### ✨ New Features

    - [core]: add fallback if mariadb upstream unreachable [@MickLesk](https://github.com/MickLesk) ([#7599](https://github.com/community-scripts/ProxmoxVE/pull/7599))
    - ESPHome: Increase default disk size [@tremor021](https://github.com/tremor021) ([#7600](https://github.com/community-scripts/ProxmoxVE/pull/7600))

## 2025-09-11

### 🆕 New Scripts

  - telegraf ([#7576](https://github.com/community-scripts/ProxmoxVE/pull/7576))

### 🚀 Updated Scripts

  - [core] Sort tools.func functions alphabeticaly [@tremor021](https://github.com/tremor021) ([#7569](https://github.com/community-scripts/ProxmoxVE/pull/7569))
- mobile subscription nag fix [@dvino](https://github.com/dvino) ([#7567](https://github.com/community-scripts/ProxmoxVE/pull/7567))

  - #### 🐞 Bug Fixes

    - alpine-install: switch to using GitHub to fetch tools when using GitHub [@burritosoftware](https://github.com/burritosoftware) ([#7566](https://github.com/community-scripts/ProxmoxVE/pull/7566))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - Add margin-bottom to Most Viewed Scripts header to unifi UI [@BramSuurdje](https://github.com/BramSuurdje) ([#7572](https://github.com/community-scripts/ProxmoxVE/pull/7572))

  - #### 📝 Script Information

    - Fix frontend url [@r1cebank](https://github.com/r1cebank) ([#7578](https://github.com/community-scripts/ProxmoxVE/pull/7578))

## 2025-09-10

### 🆕 New Scripts

  - Autocaliweb ([#7515](https://github.com/community-scripts/ProxmoxVE/pull/7515))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Palmr: fix #7556 [@vhsdream](https://github.com/vhsdream) ([#7558](https://github.com/community-scripts/ProxmoxVE/pull/7558))
    - Wizarr: Fix DB migrations [@vhsdream](https://github.com/vhsdream) ([#7552](https://github.com/community-scripts/ProxmoxVE/pull/7552))
    - fix: pmg - split no-nag script into separate config files [@MickLesk](https://github.com/MickLesk) ([#7540](https://github.com/community-scripts/ProxmoxVE/pull/7540))

  - #### ✨ New Features

    - Update Palmr to Support new v3.2.1 [@vhsdream](https://github.com/vhsdream) ([#7526](https://github.com/community-scripts/ProxmoxVE/pull/7526))
    - add external installer warnings and user confirmation in several LXC's [@MickLesk](https://github.com/MickLesk) ([#7539](https://github.com/community-scripts/ProxmoxVE/pull/7539))
    - Booklore: Add Bookdrop location to .env [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#7533](https://github.com/community-scripts/ProxmoxVE/pull/7533))

  - #### 🔧 Refactor

    - Refactor: audiobookshelf [@MickLesk](https://github.com/MickLesk) ([#7538](https://github.com/community-scripts/ProxmoxVE/pull/7538))
    - Refactor: Blocky [@MickLesk](https://github.com/MickLesk) ([#7537](https://github.com/community-scripts/ProxmoxVE/pull/7537))
    - Improve npmplus credential retrieval and messaging [@MickLesk](https://github.com/MickLesk) ([#7532](https://github.com/community-scripts/ProxmoxVE/pull/7532))

### 🌐 Website

  - #### 💥 Breaking Changes

    - Remove Pingvin Share [@CrazyWolf13](https://github.com/CrazyWolf13) ([#7553](https://github.com/community-scripts/ProxmoxVE/pull/7553))

  - #### 📝 Script Information

    - set updateable to true for several lxc JSON-configs [@MickLesk](https://github.com/MickLesk) ([#7534](https://github.com/community-scripts/ProxmoxVE/pull/7534))

## 2025-09-09

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Tududi: v0.81 [@vhsdream](https://github.com/vhsdream) ([#7517](https://github.com/community-scripts/ProxmoxVE/pull/7517))
    - WGDashboard: Revert back to old update method [@tremor021](https://github.com/tremor021) ([#7500](https://github.com/community-scripts/ProxmoxVE/pull/7500))
    - AdventureLog: remove folder during update process [@MickLesk](https://github.com/MickLesk) ([#7507](https://github.com/community-scripts/ProxmoxVE/pull/7507))
    - PLANKA: Fix backup and restore commands [@tremor021](https://github.com/tremor021) ([#7505](https://github.com/community-scripts/ProxmoxVE/pull/7505))
    - Recyclarr: Suppress config creation output [@tremor021](https://github.com/tremor021) ([#7502](https://github.com/community-scripts/ProxmoxVE/pull/7502))

  - #### 🔧 Refactor

    - Pulse: standardise install/update with Pulse repo script [@vhsdream](https://github.com/vhsdream) ([#7519](https://github.com/community-scripts/ProxmoxVE/pull/7519))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - Refactor GitHubStarsButton to wrap in Link component for external navigation [@BramSuurdje](https://github.com/BramSuurdje) ([#7492](https://github.com/community-scripts/ProxmoxVE/pull/7492))

  - #### ✨ New Features

    - Bump vite from 7.0.0 to 7.1.5 in /frontend [@dependabot[bot]](https://github.com/dependabot[bot]) ([#7522](https://github.com/community-scripts/ProxmoxVE/pull/7522))

  - #### 📝 Script Information

    - swizzin: Change category from nvr to media [@MickLesk](https://github.com/MickLesk) ([#7511](https://github.com/community-scripts/ProxmoxVE/pull/7511))

## 2025-09-08

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - CT's: fix missing variable declaration (actualBudget, openziti, umlautadaptarr) [@MickLesk](https://github.com/MickLesk) ([#7483](https://github.com/community-scripts/ProxmoxVE/pull/7483))
    - karakeep: fix service file [@CrazyWolf13](https://github.com/CrazyWolf13) ([#7482](https://github.com/community-scripts/ProxmoxVE/pull/7482))
    - Update searxng-install.sh [@sebguy](https://github.com/sebguy) ([#7469](https://github.com/community-scripts/ProxmoxVE/pull/7469))

  - #### ✨ New Features

    - Immich: bump to version 1.141.1 [@vhsdream](https://github.com/vhsdream) ([#7418](https://github.com/community-scripts/ProxmoxVE/pull/7418))
    - [core]: switch all base_settings to variables [@MickLesk](https://github.com/MickLesk) ([#7479](https://github.com/community-scripts/ProxmoxVE/pull/7479))

  - #### 💥 Breaking Changes

    - RustDesk Server: Update the credentials info [@tremor021](https://github.com/tremor021) ([#7473](https://github.com/community-scripts/ProxmoxVE/pull/7473))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - Format numerical values in DataFetcher component for better readability [@BramSuurdje](https://github.com/BramSuurdje) ([#7477](https://github.com/community-scripts/ProxmoxVE/pull/7477))

  - #### ✨ New Features

    - feat: enhance github stars button to be better looking and more compact [@BramSuurdje](https://github.com/BramSuurdje) ([#7464](https://github.com/community-scripts/ProxmoxVE/pull/7464))

## 2025-09-07

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Update ExecStart path for karakeep service [@CrazyWolf13](https://github.com/CrazyWolf13) ([#7460](https://github.com/community-scripts/ProxmoxVE/pull/7460))

## 2025-09-06

### 🆕 New Scripts

  - Resilio Sync ([#7442](https://github.com/community-scripts/ProxmoxVE/pull/7442))
- leantime ([#7414](https://github.com/community-scripts/ProxmoxVE/pull/7414))

### 🚀 Updated Scripts

  - use debian source for direct installation of MQTT [@EtlamGit](https://github.com/EtlamGit) ([#7423](https://github.com/community-scripts/ProxmoxVE/pull/7423))

  - #### ✨ New Features

    - feat: added mobile ui subscription nag removal [@ivan-penchev](https://github.com/ivan-penchev) ([#7164](https://github.com/community-scripts/ProxmoxVE/pull/7164))

### 🌐 Website

  - #### 📝 Script Information

    - MediaManager Configuration Path [@austinpilz](https://github.com/austinpilz) ([#7408](https://github.com/community-scripts/ProxmoxVE/pull/7408))
    - Paperless-NGX: Remove default credentials from json [@tremor021](https://github.com/tremor021) ([#7403](https://github.com/community-scripts/ProxmoxVE/pull/7403))

## 2025-09-05

### 🚀 Updated Scripts

  - Tududi: Pin version to 0.80 [@vhsdream](https://github.com/vhsdream) ([#7420](https://github.com/community-scripts/ProxmoxVE/pull/7420))

  - #### 🐞 Bug Fixes

    - AdventureLog: Update dependencies [@tremor021](https://github.com/tremor021) ([#7404](https://github.com/community-scripts/ProxmoxVE/pull/7404))

### 🌐 Website

  - refactor: Enhance ScriptAccordion and Sidebar components to support selectedCategory state [@BramSuurdje](https://github.com/BramSuurdje) ([#7405](https://github.com/community-scripts/ProxmoxVE/pull/7405))

## 2025-09-04

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - fix: Syntax error in Immich scripts [@henworth](https://github.com/henworth) ([#7398](https://github.com/community-scripts/ProxmoxVE/pull/7398))
    - Netdata: Fix pve_check for 8 [@MickLesk](https://github.com/MickLesk) ([#7392](https://github.com/community-scripts/ProxmoxVE/pull/7392))

  - #### 🔧 Refactor

    - Immich: pin compiled photo library revisions [@vhsdream](https://github.com/vhsdream) ([#7395](https://github.com/community-scripts/ProxmoxVE/pull/7395))

## 2025-09-03

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Element-Synapse: Increase HDD size [@tremor021](https://github.com/tremor021) ([#7384](https://github.com/community-scripts/ProxmoxVE/pull/7384))
    - Wizarr: fix uv lock issue; use correct output suppression [@vhsdream](https://github.com/vhsdream) ([#7378](https://github.com/community-scripts/ProxmoxVE/pull/7378))
    - Netbox: Fix missing directory [@tremor021](https://github.com/tremor021) ([#7374](https://github.com/community-scripts/ProxmoxVE/pull/7374))

  - #### 🔧 Refactor

    - Enhanced IP-Tag installation script with interactive configuration, improved VM IP detection, and better visual indicators [@DesertGamer](https://github.com/DesertGamer) ([#7366](https://github.com/community-scripts/ProxmoxVE/pull/7366))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - Fix navigation [@BramSuurdje](https://github.com/BramSuurdje) ([#7376](https://github.com/community-scripts/ProxmoxVE/pull/7376))

## 2025-09-02

### 🚀 Updated Scripts

  - Increase default disk size for Apt-Cacher-NG [@MickLesk](https://github.com/MickLesk) ([#7352](https://github.com/community-scripts/ProxmoxVE/pull/7352))

  - #### 🐞 Bug Fixes

    - Snipe-IT: Fix Nginx configuration [@tremor021](https://github.com/tremor021) ([#7358](https://github.com/community-scripts/ProxmoxVE/pull/7358))
    - booklore: remove folder before update [@MickLesk](https://github.com/MickLesk) ([#7351](https://github.com/community-scripts/ProxmoxVE/pull/7351))

  - #### ✨ New Features

    - Immich: bump version to 1.140.1 [@vhsdream](https://github.com/vhsdream) ([#7349](https://github.com/community-scripts/ProxmoxVE/pull/7349))

### 🌐 Website

  - #### 📝 Script Information

    - pbs: increase note on website for ipv6 [@MickLesk](https://github.com/MickLesk) ([#7339](https://github.com/community-scripts/ProxmoxVE/pull/7339))

## 2025-09-01

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Update configarr.sh to mv backep up .env correctly [@finkerle](https://github.com/finkerle) ([#7323](https://github.com/community-scripts/ProxmoxVE/pull/7323))

  - #### ✨ New Features

    - Refactor + Feature Bump: HomeAssistant OS [@MickLesk](https://github.com/MickLesk) ([#7336](https://github.com/community-scripts/ProxmoxVE/pull/7336))
    - UmbrelOS: Refactor / use q35 / better import [@MickLesk](https://github.com/MickLesk) ([#7329](https://github.com/community-scripts/ProxmoxVE/pull/7329))
    - Harmonize GH Release Check (excl. Pre-Releases & Migrate old "_version.txt" [@MickLesk](https://github.com/MickLesk) ([#7328](https://github.com/community-scripts/ProxmoxVE/pull/7328))

### 🌐 Website

  - Bump next from 15.2.4 to 15.5.2 in /frontend [@dependabot[bot]](https://github.com/dependabot[bot]) ([#7309](https://github.com/community-scripts/ProxmoxVE/pull/7309))

  - #### 📝 Script Information

    - booklore: add note for start-up in frontend [@MickLesk](https://github.com/MickLesk) ([#7331](https://github.com/community-scripts/ProxmoxVE/pull/7331))

## 2025-08-31

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - n8n: Increase disk size [@tremor021](https://github.com/tremor021) ([#7320](https://github.com/community-scripts/ProxmoxVE/pull/7320))

## 2025-08-30

### 🚀 Updated Scripts

  - Immich: bump version to 1.140.0 [@vhsdream](https://github.com/vhsdream) ([#7275](https://github.com/community-scripts/ProxmoxVE/pull/7275))

  - #### 🔧 Refactor

    - Refactor gitea-mirror env-file [@CrazyWolf13](https://github.com/CrazyWolf13) ([#7240](https://github.com/community-scripts/ProxmoxVE/pull/7240))

## 2025-08-29

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - fix version check for pocket-id migration [@MickLesk](https://github.com/MickLesk) ([#7298](https://github.com/community-scripts/ProxmoxVE/pull/7298))
    - fix: remove file creation at release fetching and version checking logic [@MickLesk](https://github.com/MickLesk) ([#7299](https://github.com/community-scripts/ProxmoxVE/pull/7299))
    - Zitadel: Fix initial setup [@tremor021](https://github.com/tremor021) ([#7284](https://github.com/community-scripts/ProxmoxVE/pull/7284))
    - post-pbs: increase enterprise recognition [@MickLesk](https://github.com/MickLesk) ([#7280](https://github.com/community-scripts/ProxmoxVE/pull/7280))
    - Fix typo where install mode was changed instead of pinned version [@Brandsma](https://github.com/Brandsma) ([#7277](https://github.com/community-scripts/ProxmoxVE/pull/7277))

  - #### ✨ New Features

    - [core]: feature - check_for_gh_release - version pinning [@MickLesk](https://github.com/MickLesk) ([#7279](https://github.com/community-scripts/ProxmoxVE/pull/7279))
    - [feat]: migrate all update_scripts to new version helper (gh) [@MickLesk](https://github.com/MickLesk) ([#7262](https://github.com/community-scripts/ProxmoxVE/pull/7262))

## 2025-08-28

### 🆕 New Scripts

  - MediaManager ([#7238](https://github.com/community-scripts/ProxmoxVE/pull/7238))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - MMDL: add build-essential as dep [@vhsdream](https://github.com/vhsdream) ([#7266](https://github.com/community-scripts/ProxmoxVE/pull/7266))

  - #### ✨ New Features

    - add support for multiple ip addresses in monitor-all.sh [@moshekv](https://github.com/moshekv) ([#7244](https://github.com/community-scripts/ProxmoxVE/pull/7244))
    - [core]: feature - check_for_gh_release as update-handler [@MickLesk](https://github.com/MickLesk) ([#7254](https://github.com/community-scripts/ProxmoxVE/pull/7254))

  - #### 💥 Breaking Changes

    - Flaresolverr: Pin to 3.3.25 (Python Issue) [@MickLesk](https://github.com/MickLesk) ([#7248](https://github.com/community-scripts/ProxmoxVE/pull/7248))

### 🌐 Website

  - #### 📝 Script Information

    - Keycloak: Update website [@tremor021](https://github.com/tremor021) ([#7256](https://github.com/community-scripts/ProxmoxVE/pull/7256))

## 2025-08-27

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - searxng: improve installation [@MickLesk](https://github.com/MickLesk) ([#7233](https://github.com/community-scripts/ProxmoxVE/pull/7233))
    - Homebox: Fix Update Script [@MickLesk](https://github.com/MickLesk) ([#7232](https://github.com/community-scripts/ProxmoxVE/pull/7232))

## 2025-08-26

### 🆕 New Scripts

  - tracktor ([#7190](https://github.com/community-scripts/ProxmoxVE/pull/7190))
- PBS: Upgrade Script for v4 [@MickLesk](https://github.com/MickLesk) ([#7214](https://github.com/community-scripts/ProxmoxVE/pull/7214))

### 🚀 Updated Scripts

  - #### ✨ New Features

    - Refactor: Post-PBS-Script [@MickLesk](https://github.com/MickLesk) ([#7213](https://github.com/community-scripts/ProxmoxVE/pull/7213))
    - Refactor: Post-PMG-Script [@MickLesk](https://github.com/MickLesk) ([#7212](https://github.com/community-scripts/ProxmoxVE/pull/7212))

### 🌐 Website

  - #### 📝 Script Information

    - [website] Update documentation URLs [@tremor021](https://github.com/tremor021) ([#7201](https://github.com/community-scripts/ProxmoxVE/pull/7201))

## 2025-08-25

### 🆕 New Scripts

  - Alpine-RustDesk Server [@tremor021](https://github.com/tremor021) ([#7191](https://github.com/community-scripts/ProxmoxVE/pull/7191))
- Alpine-Redlib ([#7178](https://github.com/community-scripts/ProxmoxVE/pull/7178))
- healthchecks ([#7177](https://github.com/community-scripts/ProxmoxVE/pull/7177))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - FileBrowser Quantum: safer update (tmp download + atomic replace + arch autodetect) [@CommanderPaladin](https://github.com/CommanderPaladin) ([#7174](https://github.com/community-scripts/ProxmoxVE/pull/7174))
    - Immich: bump to v1.139.4 [@vhsdream](https://github.com/vhsdream) ([#7138](https://github.com/community-scripts/ProxmoxVE/pull/7138))
    - Komodo: Fix compose.env path [@tremor021](https://github.com/tremor021) ([#7202](https://github.com/community-scripts/ProxmoxVE/pull/7202))
    - Komodo: Fix update procedure and missing env var [@tremor021](https://github.com/tremor021) ([#7198](https://github.com/community-scripts/ProxmoxVE/pull/7198))
    - SnipeIT: Update nginx config to v8.3 [@tremor021](https://github.com/tremor021) ([#7171](https://github.com/community-scripts/ProxmoxVE/pull/7171))
    - Lidarr: Fix RELEASE variable fetching [@tremor021](https://github.com/tremor021) ([#7162](https://github.com/community-scripts/ProxmoxVE/pull/7162))

  - #### ✨ New Features

    - Komodo: Generate admin users password [@tremor021](https://github.com/tremor021) ([#7193](https://github.com/community-scripts/ProxmoxVE/pull/7193))
    - [core]: uv uses now "update-shell" command [@MickLesk](https://github.com/MickLesk) ([#7172](https://github.com/community-scripts/ProxmoxVE/pull/7172))
    - [core]: tools.func - better verbose for postgresql [@MickLesk](https://github.com/MickLesk) ([#7173](https://github.com/community-scripts/ProxmoxVE/pull/7173))
    - n8n: Force update to NodeJS v22 [@tremor021](https://github.com/tremor021) ([#7176](https://github.com/community-scripts/ProxmoxVE/pull/7176))

### 🌐 Website

  - #### 📝 Script Information

    - 2FAuth: Fix website and docs URLs [@tremor021](https://github.com/tremor021) ([#7199](https://github.com/community-scripts/ProxmoxVE/pull/7199))

## 2025-08-24

### 🚀 Updated Scripts

  - Kasm: Fix install log parsing [@tremor021](https://github.com/tremor021) ([#7140](https://github.com/community-scripts/ProxmoxVE/pull/7140))

  - #### 🐞 Bug Fixes

    - BookLore: Fix Nginx config [@tremor021](https://github.com/tremor021) ([#7155](https://github.com/community-scripts/ProxmoxVE/pull/7155))

  - #### ✨ New Features

    - Syncthing: Switch to v2 stable repository [@tremor021](https://github.com/tremor021) ([#7150](https://github.com/community-scripts/ProxmoxVE/pull/7150))

## 2025-08-23

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - qBittorrent: Fix file names [@tremor021](https://github.com/tremor021) ([#7136](https://github.com/community-scripts/ProxmoxVE/pull/7136))
    - Tandoor: Fix env path [@tremor021](https://github.com/tremor021) ([#7130](https://github.com/community-scripts/ProxmoxVE/pull/7130))

  - #### 💥 Breaking Changes

    - Immich: v1.139.2 [@vhsdream](https://github.com/vhsdream) ([#7116](https://github.com/community-scripts/ProxmoxVE/pull/7116))

  - #### 🔧 Refactor

    - Refactor: Pf2eTools [@tremor021](https://github.com/tremor021) ([#7096](https://github.com/community-scripts/ProxmoxVE/pull/7096))
    - Refactor: Prowlarr [@tremor021](https://github.com/tremor021) ([#7091](https://github.com/community-scripts/ProxmoxVE/pull/7091))
    - Refactor: Radarr [@tremor021](https://github.com/tremor021) ([#7088](https://github.com/community-scripts/ProxmoxVE/pull/7088))
    - Refactor: Snipe-IT [@tremor021](https://github.com/tremor021) ([#7081](https://github.com/community-scripts/ProxmoxVE/pull/7081))

## 2025-08-22

### 🚀 Updated Scripts

  - Refactor: Prometheus [@tremor021](https://github.com/tremor021) ([#7093](https://github.com/community-scripts/ProxmoxVE/pull/7093))

  - #### 🐞 Bug Fixes

    - paperless: nltk fix [@MickLesk](https://github.com/MickLesk) ([#7098](https://github.com/community-scripts/ProxmoxVE/pull/7098))
    - Tududi Fix: use correct tag parsing for release during update check [@vhsdream](https://github.com/vhsdream) ([#7072](https://github.com/community-scripts/ProxmoxVE/pull/7072))

  - #### 🔧 Refactor

    - Refactor: phpIPAM [@tremor021](https://github.com/tremor021) ([#7095](https://github.com/community-scripts/ProxmoxVE/pull/7095))
    - Refactor: Prometheus Paperless NGX Exporter [@tremor021](https://github.com/tremor021) ([#7092](https://github.com/community-scripts/ProxmoxVE/pull/7092))
    - Refactor: PS5-MQTT [@tremor021](https://github.com/tremor021) ([#7090](https://github.com/community-scripts/ProxmoxVE/pull/7090))
    - Refactor: qBittorrent [@tremor021](https://github.com/tremor021) ([#7089](https://github.com/community-scripts/ProxmoxVE/pull/7089))
    - Refactor: RDTClient [@tremor021](https://github.com/tremor021) ([#7086](https://github.com/community-scripts/ProxmoxVE/pull/7086))
    - Refactor: Recyclarr [@tremor021](https://github.com/tremor021) ([#7085](https://github.com/community-scripts/ProxmoxVE/pull/7085))
    - Refactor: RevealJS [@tremor021](https://github.com/tremor021) ([#7084](https://github.com/community-scripts/ProxmoxVE/pull/7084))
    - Refactor: Rclone [@tremor021](https://github.com/tremor021) ([#7087](https://github.com/community-scripts/ProxmoxVE/pull/7087))
    - Refactor: Semaphore [@tremor021](https://github.com/tremor021) ([#7083](https://github.com/community-scripts/ProxmoxVE/pull/7083))
    - Refactor: Silverbullet [@tremor021](https://github.com/tremor021) ([#7082](https://github.com/community-scripts/ProxmoxVE/pull/7082))
    - Refactor: Plant-it [@tremor021](https://github.com/tremor021) ([#7094](https://github.com/community-scripts/ProxmoxVE/pull/7094))
    - Refactor: TasmoAdmin [@tremor021](https://github.com/tremor021) ([#7080](https://github.com/community-scripts/ProxmoxVE/pull/7080))

## 2025-08-21

### 🆕 New Scripts

  - LiteLLM ([#7052](https://github.com/community-scripts/ProxmoxVE/pull/7052))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - tianji: add uv deps [@MickLesk](https://github.com/MickLesk) ([#7066](https://github.com/community-scripts/ProxmoxVE/pull/7066))
    - Zitadel: installer for v4 [@MickLesk](https://github.com/MickLesk) ([#7058](https://github.com/community-scripts/ProxmoxVE/pull/7058))
    - Paperless-NGX: create direction for nltk [@MickLesk](https://github.com/MickLesk) ([#7064](https://github.com/community-scripts/ProxmoxVE/pull/7064))
    - Immich: hotfix - revert 7035 [@vhsdream](https://github.com/vhsdream) ([#7054](https://github.com/community-scripts/ProxmoxVE/pull/7054))
    - duplicati: fix release pattern [@MickLesk](https://github.com/MickLesk) ([#7049](https://github.com/community-scripts/ProxmoxVE/pull/7049))
    - technitiumdns: fix unbound variable [@MickLesk](https://github.com/MickLesk) ([#7047](https://github.com/community-scripts/ProxmoxVE/pull/7047))
    - [core]: improve binary globbing for gh releases [@MickLesk](https://github.com/MickLesk) ([#7044](https://github.com/community-scripts/ProxmoxVE/pull/7044))

## 2025-08-20

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Post-Install, change pve-test for trixie [@MickLesk](https://github.com/MickLesk) ([#7031](https://github.com/community-scripts/ProxmoxVE/pull/7031))
    - Immich: fix small issue with immich-admin "start" script [@vhsdream](https://github.com/vhsdream) ([#7035](https://github.com/community-scripts/ProxmoxVE/pull/7035))
    - WasteBin: Small fixes [@tremor021](https://github.com/tremor021) ([#7018](https://github.com/community-scripts/ProxmoxVE/pull/7018))
    - Komga: Fix update [@tremor021](https://github.com/tremor021) ([#7027](https://github.com/community-scripts/ProxmoxVE/pull/7027))
    - Barcode Buddy: Fix missing dependency [@tremor021](https://github.com/tremor021) ([#7020](https://github.com/community-scripts/ProxmoxVE/pull/7020))
    - PBS: ifupdown2 reload [@MickLesk](https://github.com/MickLesk) ([#7013](https://github.com/community-scripts/ProxmoxVE/pull/7013))

  - #### ✨ New Features

    - Feature: Netdata support PVE9 (Debian 13 Trixie) [@MickLesk](https://github.com/MickLesk) ([#7012](https://github.com/community-scripts/ProxmoxVE/pull/7012))

  - #### 🔧 Refactor

    - Refactor: RustDesk Server [@tremor021](https://github.com/tremor021) ([#7008](https://github.com/community-scripts/ProxmoxVE/pull/7008))
    - ghost: fix: verbose [@CrazyWolf13](https://github.com/CrazyWolf13) ([#7023](https://github.com/community-scripts/ProxmoxVE/pull/7023))
    - Refactor: Paperless-ngx [@MickLesk](https://github.com/MickLesk) ([#6938](https://github.com/community-scripts/ProxmoxVE/pull/6938))

## 2025-08-19

### 🆕 New Scripts

  - Debian 13 VM [@MickLesk](https://github.com/MickLesk) ([#6970](https://github.com/community-scripts/ProxmoxVE/pull/6970))
- Swizzin ([#6962](https://github.com/community-scripts/ProxmoxVE/pull/6962))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - [core]: create_lxc - fix offline issue with alpine packages [@MickLesk](https://github.com/MickLesk) ([#6994](https://github.com/community-scripts/ProxmoxVE/pull/6994))
    - OpenObserve: Fix release fetching [@tremor021](https://github.com/tremor021) ([#6961](https://github.com/community-scripts/ProxmoxVE/pull/6961))
    - Update hev-socks5-server-install.sh [@iAzamat2](https://github.com/iAzamat2) ([#6953](https://github.com/community-scripts/ProxmoxVE/pull/6953))

  - #### ✨ New Features

    - Refactor: Glances (+ Feature Bump) [@MickLesk](https://github.com/MickLesk) ([#6976](https://github.com/community-scripts/ProxmoxVE/pull/6976))
    - [core]: add new features to create_lxc [@MickLesk](https://github.com/MickLesk) ([#6979](https://github.com/community-scripts/ProxmoxVE/pull/6979))
    - [core]: extend setup_uv to work with alpine [@MickLesk](https://github.com/MickLesk) ([#6978](https://github.com/community-scripts/ProxmoxVE/pull/6978))
    - Immich: Bump version to 1.138.1 [@vhsdream](https://github.com/vhsdream) ([#6984](https://github.com/community-scripts/ProxmoxVE/pull/6984))

  - #### 🔧 Refactor

    - Refactor: Tdarr [@MickLesk](https://github.com/MickLesk) ([#6969](https://github.com/community-scripts/ProxmoxVE/pull/6969))
    - Refactor: The Lounge [@tremor021](https://github.com/tremor021) ([#6958](https://github.com/community-scripts/ProxmoxVE/pull/6958))
    - Refactor: TeddyCloud [@tremor021](https://github.com/tremor021) ([#6963](https://github.com/community-scripts/ProxmoxVE/pull/6963))
    - Refactor: Technitium DNS [@tremor021](https://github.com/tremor021) ([#6968](https://github.com/community-scripts/ProxmoxVE/pull/6968))

### 🌐 Website

  - #### 📝 Script Information

    - [web]: update logos from reactive-resume & slskd [@MickLesk](https://github.com/MickLesk) ([#6990](https://github.com/community-scripts/ProxmoxVE/pull/6990))

## 2025-08-18

### 🆕 New Scripts

  - CopyParty [@MickLesk](https://github.com/MickLesk) ([#6929](https://github.com/community-scripts/ProxmoxVE/pull/6929))
- Twingate-Connector ([#6921](https://github.com/community-scripts/ProxmoxVE/pull/6921))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Keycloak: fix update function [@MickLesk](https://github.com/MickLesk) ([#6943](https://github.com/community-scripts/ProxmoxVE/pull/6943))
    - Immich: add message to indicate image-processing library update check [@vhsdream](https://github.com/vhsdream) ([#6935](https://github.com/community-scripts/ProxmoxVE/pull/6935))
    - fix(uptimekuma): unbound env variable [@vidonnus](https://github.com/vidonnus) ([#6922](https://github.com/community-scripts/ProxmoxVE/pull/6922))

  - #### 🔧 Refactor

    - Refactor: Traefik [@tremor021](https://github.com/tremor021) ([#6940](https://github.com/community-scripts/ProxmoxVE/pull/6940))
    - Refactor: Traccar [@tremor021](https://github.com/tremor021) ([#6942](https://github.com/community-scripts/ProxmoxVE/pull/6942))
    - Refactor: Umami [@tremor021](https://github.com/tremor021) ([#6939](https://github.com/community-scripts/ProxmoxVE/pull/6939))
    - Refactor: GoMFT [@tremor021](https://github.com/tremor021) ([#6916](https://github.com/community-scripts/ProxmoxVE/pull/6916))

### 🌐 Website

  - #### 📝 Script Information

    - OpenWRT: add info for VLAN-aware in frontend [@MickLesk](https://github.com/MickLesk) ([#6944](https://github.com/community-scripts/ProxmoxVE/pull/6944))

## 2025-08-17

## 2025-08-16

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Wireguard: Fix WGDashboard not updating [@tremor021](https://github.com/tremor021) ([#6898](https://github.com/community-scripts/ProxmoxVE/pull/6898))
    - Tandoor Images Fix [@WarLord185](https://github.com/WarLord185) ([#6892](https://github.com/community-scripts/ProxmoxVE/pull/6892))

  - #### 🔧 Refactor

    - Refactor: Uptime Kuma [@tremor021](https://github.com/tremor021) ([#6902](https://github.com/community-scripts/ProxmoxVE/pull/6902))
    - Refactor: Wallos [@tremor021](https://github.com/tremor021) ([#6900](https://github.com/community-scripts/ProxmoxVE/pull/6900))

## 2025-08-15

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Immich: pin Vectorchord release; adjust extension update commands [@vhsdream](https://github.com/vhsdream) ([#6878](https://github.com/community-scripts/ProxmoxVE/pull/6878))

  - #### ✨ New Features

    - Bump Immich to v1.138.0 [@vhsdream](https://github.com/vhsdream) ([#6813](https://github.com/community-scripts/ProxmoxVE/pull/6813))

  - #### 🔧 Refactor

    - Refactor: Wavelog [@tremor021](https://github.com/tremor021) ([#6869](https://github.com/community-scripts/ProxmoxVE/pull/6869))
    - Refactor: WatchYourLAN [@tremor021](https://github.com/tremor021) ([#6871](https://github.com/community-scripts/ProxmoxVE/pull/6871))
    - Refactor: Watcharr [@tremor021](https://github.com/tremor021) ([#6872](https://github.com/community-scripts/ProxmoxVE/pull/6872))

### 🌐 Website

  - #### 📝 Script Information

    - Add missing default user & pass for RabbitMQ [@hbenyoussef](https://github.com/hbenyoussef) ([#6883](https://github.com/community-scripts/ProxmoxVE/pull/6883))

## 2025-08-14

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Bugfix Searxng Redis replaced with Valkey in installscript  [@elvito](https://github.com/elvito) ([#6831](https://github.com/community-scripts/ProxmoxVE/pull/6831))
    - Spoolman: Use environment variables to control host and port [@tremor021](https://github.com/tremor021) ([#6825](https://github.com/community-scripts/ProxmoxVE/pull/6825))
    - Pulse: v4.3.2+ [@vhsdream](https://github.com/vhsdream) ([#6859](https://github.com/community-scripts/ProxmoxVE/pull/6859))
    - rustdeskserver: fix API version file [@steadfasterX](https://github.com/steadfasterX) ([#6847](https://github.com/community-scripts/ProxmoxVE/pull/6847))
    - Immich: quickfix #6836 [@vhsdream](https://github.com/vhsdream) ([#6848](https://github.com/community-scripts/ProxmoxVE/pull/6848))

  - #### 🔧 Refactor

    - Refactor: WikiJS [@tremor021](https://github.com/tremor021) ([#6840](https://github.com/community-scripts/ProxmoxVE/pull/6840))
    - Refactor: Zoraxy [@tremor021](https://github.com/tremor021) ([#6823](https://github.com/community-scripts/ProxmoxVE/pull/6823))
    - Refactor: Zitadel [@tremor021](https://github.com/tremor021) ([#6826](https://github.com/community-scripts/ProxmoxVE/pull/6826))
    - Refactor: WordPress [@tremor021](https://github.com/tremor021) ([#6837](https://github.com/community-scripts/ProxmoxVE/pull/6837))
    - Refactor: WireGuard [@tremor021](https://github.com/tremor021) ([#6839](https://github.com/community-scripts/ProxmoxVE/pull/6839))
    - Refactor: yt-dlp-webui [@tremor021](https://github.com/tremor021) ([#6832](https://github.com/community-scripts/ProxmoxVE/pull/6832))
    - Refactor: Zipline [@tremor021](https://github.com/tremor021) ([#6829](https://github.com/community-scripts/ProxmoxVE/pull/6829))
    - Refactor: Zot-Registry [@tremor021](https://github.com/tremor021) ([#6822](https://github.com/community-scripts/ProxmoxVE/pull/6822))
    - Refactor: Zwave-JS-UI [@tremor021](https://github.com/tremor021) ([#6820](https://github.com/community-scripts/ProxmoxVE/pull/6820))

### 🧰 Maintenance

  - #### 📂 Github

    - ProxmoxVE svg logo [@LuisPalacios](https://github.com/LuisPalacios) ([#6846](https://github.com/community-scripts/ProxmoxVE/pull/6846))

## 2025-08-13

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - emby: fix update output [@MickLesk](https://github.com/MickLesk) ([#6791](https://github.com/community-scripts/ProxmoxVE/pull/6791))
    - archivebox: fix wrong formatted uv command [@MickLesk](https://github.com/MickLesk) ([#6794](https://github.com/community-scripts/ProxmoxVE/pull/6794))
    - Outline: Fixes for install and update procedures [@tremor021](https://github.com/tremor021) ([#6806](https://github.com/community-scripts/ProxmoxVE/pull/6806))
    - Palmr: fix release version parsing // increase RAM [@vhsdream](https://github.com/vhsdream) ([#6800](https://github.com/community-scripts/ProxmoxVE/pull/6800))
    - myspeed: fix update process if no data exist [@MickLesk](https://github.com/MickLesk) ([#6795](https://github.com/community-scripts/ProxmoxVE/pull/6795))
    - crafty-controller: fix update output [@MickLesk](https://github.com/MickLesk) ([#6793](https://github.com/community-scripts/ProxmoxVE/pull/6793))
    - GLPI: Fix timezone command [@tremor021](https://github.com/tremor021) ([#6783](https://github.com/community-scripts/ProxmoxVE/pull/6783))

  - #### ✨ New Features

    - Docker LXC: Add Portainer info [@tremor021](https://github.com/tremor021) ([#6803](https://github.com/community-scripts/ProxmoxVE/pull/6803))
    - AgentDVR: Added update function [@tremor021](https://github.com/tremor021) ([#6804](https://github.com/community-scripts/ProxmoxVE/pull/6804))

## 2025-08-12

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Pulse: binary path changed AGAIN; other fixes [@vhsdream](https://github.com/vhsdream) ([#6770](https://github.com/community-scripts/ProxmoxVE/pull/6770))
    - fix alpine syncthing config not being created [@GamerHun1238](https://github.com/GamerHun1238) ([#6773](https://github.com/community-scripts/ProxmoxVE/pull/6773))
    - change owner of hortusfox directory [@snow2k9](https://github.com/snow2k9) ([#6763](https://github.com/community-scripts/ProxmoxVE/pull/6763))

## 2025-08-11

### 🚀 Updated Scripts

  - Reactive Resume: use new release parsing; other fixes [@vhsdream](https://github.com/vhsdream) ([#6744](https://github.com/community-scripts/ProxmoxVE/pull/6744))

## 2025-08-10

### 🚀 Updated Scripts

  - Fix/thinpool detection as it allows to delete active thinpool with different name than "data" [@onethree7](https://github.com/onethree7) ([#6730](https://github.com/community-scripts/ProxmoxVE/pull/6730))

  - #### 🐞 Bug Fixes

    - Pulse: fix binary path [@vhsdream](https://github.com/vhsdream) ([#6740](https://github.com/community-scripts/ProxmoxVE/pull/6740))
    - Karakeep: chromium fix [@vhsdream](https://github.com/vhsdream) ([#6729](https://github.com/community-scripts/ProxmoxVE/pull/6729))

## 2025-08-09

### 🚀 Updated Scripts

  - Paperless-AI: increase HDD Space to 20G [@MickLesk](https://github.com/MickLesk) ([#6716](https://github.com/community-scripts/ProxmoxVE/pull/6716))

  - #### 🐞 Bug Fixes

    - vaultwarden: increase disk space [@CrazyWolf13](https://github.com/CrazyWolf13) ([#6712](https://github.com/community-scripts/ProxmoxVE/pull/6712))
    - Fix: Bazarr requirements.txt file not parse-able by UV [@Xerovoxx98](https://github.com/Xerovoxx98) ([#6701](https://github.com/community-scripts/ProxmoxVE/pull/6701))
    - Improve backup of adventurelog folder [@ThomasDetemmerman](https://github.com/ThomasDetemmerman) ([#6653](https://github.com/community-scripts/ProxmoxVE/pull/6653))
    - HomeBox: Fixes for update procedure [@tremor021](https://github.com/tremor021) ([#6702](https://github.com/community-scripts/ProxmoxVE/pull/6702))

  - #### 🔧 Refactor

    - Refactor: Tianji [@MickLesk](https://github.com/MickLesk) ([#6662](https://github.com/community-scripts/ProxmoxVE/pull/6662))

## 2025-08-08

### 🆕 New Scripts

  - Palmr ([#6642](https://github.com/community-scripts/ProxmoxVE/pull/6642))
- HortusFox ([#6641](https://github.com/community-scripts/ProxmoxVE/pull/6641))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Unifi: Update libssl dependency [@tremor021](https://github.com/tremor021) ([#6680](https://github.com/community-scripts/ProxmoxVE/pull/6680))
    - HomeBox: Fix checking for existing install [@tremor021](https://github.com/tremor021) ([#6677](https://github.com/community-scripts/ProxmoxVE/pull/6677))
    - Immich: unpin libvips revision [@vhsdream](https://github.com/vhsdream) ([#6669](https://github.com/community-scripts/ProxmoxVE/pull/6669))
    - Meilisearch: fix wrong path switch [@MickLesk](https://github.com/MickLesk) ([#6668](https://github.com/community-scripts/ProxmoxVE/pull/6668))
    - MariaDB: fix "feedback" (statistical informations) whiptail  [@MickLesk](https://github.com/MickLesk) ([#6657](https://github.com/community-scripts/ProxmoxVE/pull/6657))
    - Karakeep: workaround/fix for #6593 [@vhsdream](https://github.com/vhsdream) ([#6648](https://github.com/community-scripts/ProxmoxVE/pull/6648))

  - #### ✨ New Features

    - Feature: FSTrim (Filesystem Trim) - Log / LVM Check / ZFS [@MickLesk](https://github.com/MickLesk) ([#6660](https://github.com/community-scripts/ProxmoxVE/pull/6660))
    - IP Tag: Allow installation on PVE 9.x [@webhdx](https://github.com/webhdx) ([#6679](https://github.com/community-scripts/ProxmoxVE/pull/6679))

  - #### 🔧 Refactor

    - Refactor: Alpine IT-Tools [@tremor021](https://github.com/tremor021) ([#6579](https://github.com/community-scripts/ProxmoxVE/pull/6579))
    - Refactor: ArchiveBox [@MickLesk](https://github.com/MickLesk) ([#6670](https://github.com/community-scripts/ProxmoxVE/pull/6670))
    - Refactor: Bazarr [@MickLesk](https://github.com/MickLesk) ([#6663](https://github.com/community-scripts/ProxmoxVE/pull/6663))
    - Refactor: Kometa [@MickLesk](https://github.com/MickLesk) ([#6673](https://github.com/community-scripts/ProxmoxVE/pull/6673))

## 2025-08-07

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Commafeed: Fix Backup Handling while Update [@MickLesk](https://github.com/MickLesk) ([#6629](https://github.com/community-scripts/ProxmoxVE/pull/6629))
    - VictoriaMetrics: Fix release fetching [@tremor021](https://github.com/tremor021) ([#6632](https://github.com/community-scripts/ProxmoxVE/pull/6632))

  - #### ✨ New Features

    - Feature: Post-PVE-Script (PVE9 Support + some Features) [@MickLesk](https://github.com/MickLesk) ([#6626](https://github.com/community-scripts/ProxmoxVE/pull/6626))
    - Feature: Clean-LXC now supports Alpine based containers [@MickLesk](https://github.com/MickLesk) ([#6628](https://github.com/community-scripts/ProxmoxVE/pull/6628))

  - #### 🔧 Refactor

    - Refactor: Tandoor v2  [@MickLesk](https://github.com/MickLesk) ([#6635](https://github.com/community-scripts/ProxmoxVE/pull/6635))
    - Refactor: Paymenter [@tremor021](https://github.com/tremor021) ([#6589](https://github.com/community-scripts/ProxmoxVE/pull/6589))

## 2025-08-06

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - [core] better y/N handling for ressource check [@MickLesk](https://github.com/MickLesk) ([#6608](https://github.com/community-scripts/ProxmoxVE/pull/6608))
    - fix: update Pulse scripts for v4 Go rewrite support [@rcourtman](https://github.com/rcourtman) ([#6574](https://github.com/community-scripts/ProxmoxVE/pull/6574))
    - OpenProject: Fix missing apt update [@tremor021](https://github.com/tremor021) ([#6598](https://github.com/community-scripts/ProxmoxVE/pull/6598))

  - #### ✨ New Features

    - PVE9: Remove Beta Whiptail / add correct version check [@MickLesk](https://github.com/MickLesk) ([#6599](https://github.com/community-scripts/ProxmoxVE/pull/6599))

## 2025-08-05

### 🚀 Updated Scripts

  - #### ✨ New Features

    - NIC offloading: e1000 support [@rcastley](https://github.com/rcastley) ([#6575](https://github.com/community-scripts/ProxmoxVE/pull/6575))

  - #### 💥 Breaking Changes

    - Temporary Remove: SearXNG [@MickLesk](https://github.com/MickLesk) ([#6578](https://github.com/community-scripts/ProxmoxVE/pull/6578))

  - #### 🔧 Refactor

    - Refactor: Prometheus Alertmanager [@tremor021](https://github.com/tremor021) ([#6577](https://github.com/community-scripts/ProxmoxVE/pull/6577))

## 2025-08-04

### 🆕 New Scripts

  - Tududi ([#6534](https://github.com/community-scripts/ProxmoxVE/pull/6534))
- ots ([#6532](https://github.com/community-scripts/ProxmoxVE/pull/6532))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - MySpeed: fix update and copy old tests back [@MickLesk](https://github.com/MickLesk) ([#6550](https://github.com/community-scripts/ProxmoxVE/pull/6550))
    - Composer: PATH Issues when updating [@MickLesk](https://github.com/MickLesk) ([#6543](https://github.com/community-scripts/ProxmoxVE/pull/6543))

  - #### ✨ New Features

    - Feat: enable tun for VPN services (wireguard) [@MickLesk](https://github.com/MickLesk) ([#6562](https://github.com/community-scripts/ProxmoxVE/pull/6562))
    - turnkey: add hostname & Fix TUN access [@masterofrpm](https://github.com/masterofrpm) ([#6512](https://github.com/community-scripts/ProxmoxVE/pull/6512))
    - Increase: Core Network check (pre-LXC Creation)  [@MickLesk](https://github.com/MickLesk) ([#6546](https://github.com/community-scripts/ProxmoxVE/pull/6546))

  - #### 🔧 Refactor

    - Refactor: PrivateBin [@tremor021](https://github.com/tremor021) ([#6559](https://github.com/community-scripts/ProxmoxVE/pull/6559))
    - Refactor: PocketID [@tremor021](https://github.com/tremor021) ([#6556](https://github.com/community-scripts/ProxmoxVE/pull/6556))
    - Refactor: Pocketbase [@tremor021](https://github.com/tremor021) ([#6554](https://github.com/community-scripts/ProxmoxVE/pull/6554))
    - Refactor: NocoDB [@tremor021](https://github.com/tremor021) ([#6548](https://github.com/community-scripts/ProxmoxVE/pull/6548))
    - Refactor: PairDrop [@tremor021](https://github.com/tremor021) ([#6528](https://github.com/community-scripts/ProxmoxVE/pull/6528))

## 2025-08-03

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - docmost: remove build step due new version [@MickLesk](https://github.com/MickLesk) ([#6513](https://github.com/community-scripts/ProxmoxVE/pull/6513))
    - Fix: Komga uses .komga as storage / so it fails after install [@MickLesk](https://github.com/MickLesk) ([#6517](https://github.com/community-scripts/ProxmoxVE/pull/6517))

  - #### 💥 Breaking Changes

    - Remove: Ubuntu 24.10-VM [@MickLesk](https://github.com/MickLesk) ([#6515](https://github.com/community-scripts/ProxmoxVE/pull/6515))

  - #### 🔧 Refactor

    - Refactor: openHAB [@tremor021](https://github.com/tremor021) ([#6524](https://github.com/community-scripts/ProxmoxVE/pull/6524))
    - Refactor: OpenProject [@tremor021](https://github.com/tremor021) ([#6525](https://github.com/community-scripts/ProxmoxVE/pull/6525))

## 2025-08-02

### 🚀 Updated Scripts

  - Alternative connectivity checks for LXC [@mariano-dagostino](https://github.com/mariano-dagostino) ([#6472](https://github.com/community-scripts/ProxmoxVE/pull/6472))

  - #### 🐞 Bug Fixes

    - Immich: fix copy error during install [@vhsdream](https://github.com/vhsdream) ([#6497](https://github.com/community-scripts/ProxmoxVE/pull/6497))
    - MagicMirror: Fix install process [@tremor021](https://github.com/tremor021) ([#6492](https://github.com/community-scripts/ProxmoxVE/pull/6492))
    - chore: BookLore repo change [@vhsdream](https://github.com/vhsdream) ([#6493](https://github.com/community-scripts/ProxmoxVE/pull/6493))

  - #### ✨ New Features

    - VictoriaMetrics: Make VictoriaLogs optional add-on [@tremor021](https://github.com/tremor021) ([#6489](https://github.com/community-scripts/ProxmoxVE/pull/6489))

## 2025-08-01

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Fumadocs: add git as dependency [@MickLesk](https://github.com/MickLesk) ([#6459](https://github.com/community-scripts/ProxmoxVE/pull/6459))
    - Immich: Fix immich-admin script; other fixes | pin to v.137.3 [@vhsdream](https://github.com/vhsdream) ([#6443](https://github.com/community-scripts/ProxmoxVE/pull/6443))

  - #### ✨ New Features

    - Re-Add: Suwayomi-Server [@MickLesk](https://github.com/MickLesk) ([#6458](https://github.com/community-scripts/ProxmoxVE/pull/6458))

  - #### 🔧 Refactor

    - Update homepage.sh to use setup_nodejs [@burgerga](https://github.com/burgerga) ([#6462](https://github.com/community-scripts/ProxmoxVE/pull/6462))
    - Refactor: Owncast [@tremor021](https://github.com/tremor021) ([#6434](https://github.com/community-scripts/ProxmoxVE/pull/6434))
    - Refactor: MediaMTX [@tremor021](https://github.com/tremor021) ([#6406](https://github.com/community-scripts/ProxmoxVE/pull/6406))
    - Refactor: LubeLogger [@tremor021](https://github.com/tremor021) ([#6400](https://github.com/community-scripts/ProxmoxVE/pull/6400))
    - Refactor: MagicMirror [@tremor021](https://github.com/tremor021) ([#6402](https://github.com/community-scripts/ProxmoxVE/pull/6402))
    - Refactor: Manage My Damn Life [@tremor021](https://github.com/tremor021) ([#6403](https://github.com/community-scripts/ProxmoxVE/pull/6403))
    - Refactor: Meilisearch [@tremor021](https://github.com/tremor021) ([#6407](https://github.com/community-scripts/ProxmoxVE/pull/6407))
    - Refactor: NodeBB [@tremor021](https://github.com/tremor021) ([#6419](https://github.com/community-scripts/ProxmoxVE/pull/6419))
    - Refactor: oauth2-proxy [@tremor021](https://github.com/tremor021) ([#6421](https://github.com/community-scripts/ProxmoxVE/pull/6421))
    - Refactor: Outline [@tremor021](https://github.com/tremor021) ([#6424](https://github.com/community-scripts/ProxmoxVE/pull/6424))
    - Refactor: Overseerr [@tremor021](https://github.com/tremor021) ([#6425](https://github.com/community-scripts/ProxmoxVE/pull/6425))

## 2025-07-31

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - OpenObserve: Fix release fetching [@tremor021](https://github.com/tremor021) ([#6409](https://github.com/community-scripts/ProxmoxVE/pull/6409))

  - #### 💥 Breaking Changes

    - Remove temp. Tandoor during Install & Update Issues [@MickLesk](https://github.com/MickLesk) ([#6438](https://github.com/community-scripts/ProxmoxVE/pull/6438))

  - #### 🔧 Refactor

    - Refactor: listmonk [@tremor021](https://github.com/tremor021) ([#6399](https://github.com/community-scripts/ProxmoxVE/pull/6399))
    - Refactor: Neo4j [@tremor021](https://github.com/tremor021) ([#6418](https://github.com/community-scripts/ProxmoxVE/pull/6418))
    - Refactor: Monica [@tremor021](https://github.com/tremor021) ([#6416](https://github.com/community-scripts/ProxmoxVE/pull/6416))
    - Refactor: Memos [@tremor021](https://github.com/tremor021) ([#6415](https://github.com/community-scripts/ProxmoxVE/pull/6415))
    - Refactor: Opengist [@tremor021](https://github.com/tremor021) ([#6423](https://github.com/community-scripts/ProxmoxVE/pull/6423))
    - Refactor: Ombi [@tremor021](https://github.com/tremor021) ([#6422](https://github.com/community-scripts/ProxmoxVE/pull/6422))
    - Refactor: MySpeed [@tremor021](https://github.com/tremor021) ([#6417](https://github.com/community-scripts/ProxmoxVE/pull/6417))

## 2025-07-30

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Strip SD and NS prefixes before writing to config file [@mattv8](https://github.com/mattv8) ([#6356](https://github.com/community-scripts/ProxmoxVE/pull/6356))
    - [core] fix: expand $CACHER_IP in apt-proxy-detect.sh (revert quoted heredoc) [@MickLesk](https://github.com/MickLesk) ([#6385](https://github.com/community-scripts/ProxmoxVE/pull/6385))
    - PiAlert: bugfix dependencies [@leiweibau](https://github.com/leiweibau) ([#6396](https://github.com/community-scripts/ProxmoxVE/pull/6396))
    - Librespeed-Rust: Fix service name and RELEASE var fetching [@tremor021](https://github.com/tremor021) ([#6378](https://github.com/community-scripts/ProxmoxVE/pull/6378))
    - n8n: add build-essential as dependency [@MickLesk](https://github.com/MickLesk) ([#6392](https://github.com/community-scripts/ProxmoxVE/pull/6392))
    - Habitica: Fix trusted domains [@tremor021](https://github.com/tremor021) ([#6380](https://github.com/community-scripts/ProxmoxVE/pull/6380))
    - Mafl: Fix undeclared var [@tremor021](https://github.com/tremor021) ([#6371](https://github.com/community-scripts/ProxmoxVE/pull/6371))

  - #### 🔧 Refactor

    - Refactor: Lidarr [@tremor021](https://github.com/tremor021) ([#6379](https://github.com/community-scripts/ProxmoxVE/pull/6379))
    - Refactor: Kubo [@tremor021](https://github.com/tremor021) ([#6376](https://github.com/community-scripts/ProxmoxVE/pull/6376))
    - Refactor: Komga [@tremor021](https://github.com/tremor021) ([#6374](https://github.com/community-scripts/ProxmoxVE/pull/6374))
    - Refactor: Koillection [@tremor021](https://github.com/tremor021) ([#6373](https://github.com/community-scripts/ProxmoxVE/pull/6373))
    - Refactor: Karakeep [@tremor021](https://github.com/tremor021) ([#6372](https://github.com/community-scripts/ProxmoxVE/pull/6372))

## 2025-07-29

### 🆕 New Scripts

  - Jeedom ([#6336](https://github.com/community-scripts/ProxmoxVE/pull/6336))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - PiAlert: add new dependencies [@leiweibau](https://github.com/leiweibau) ([#6337](https://github.com/community-scripts/ProxmoxVE/pull/6337))
    - Element Synapse CT RAM increased from 1024 to 2048 [@tjcomserv](https://github.com/tjcomserv) ([#6330](https://github.com/community-scripts/ProxmoxVE/pull/6330))

  - #### 🔧 Refactor

    - Refactor: HomeBox [@tremor021](https://github.com/tremor021) ([#6338](https://github.com/community-scripts/ProxmoxVE/pull/6338))
    - Refactor: InspIRCd [@tremor021](https://github.com/tremor021) ([#6343](https://github.com/community-scripts/ProxmoxVE/pull/6343))
    - Refactor: Jackett [@tremor021](https://github.com/tremor021) ([#6344](https://github.com/community-scripts/ProxmoxVE/pull/6344))
    - Update keycloak script to support configuration of latest release (v26) [@remz1337](https://github.com/remz1337) ([#6322](https://github.com/community-scripts/ProxmoxVE/pull/6322))
    - Refactor: Photoprism [@MickLesk](https://github.com/MickLesk) ([#6335](https://github.com/community-scripts/ProxmoxVE/pull/6335))
    - Refactor: Autobrr [@tremor021](https://github.com/tremor021) ([#6302](https://github.com/community-scripts/ProxmoxVE/pull/6302))

## 2025-07-28

### 🚀 Updated Scripts

  - Refactor: Cronicle [@tremor021](https://github.com/tremor021) ([#6314](https://github.com/community-scripts/ProxmoxVE/pull/6314))
- Refactor: HiveMQ [@tremor021](https://github.com/tremor021) ([#6313](https://github.com/community-scripts/ProxmoxVE/pull/6313))

  - #### 🐞 Bug Fixes

    - fix: SSH authorized keys not added in Alpine install script [@enihsyou](https://github.com/enihsyou) ([#6316](https://github.com/community-scripts/ProxmoxVE/pull/6316))
    - fix: removing ",gw=" from GATE var when reading/writing from/to config. [@teohz](https://github.com/teohz) ([#6177](https://github.com/community-scripts/ProxmoxVE/pull/6177))
    - add 'g++' to actualbudget-install.sh [@saivishnu725](https://github.com/saivishnu725) ([#6293](https://github.com/community-scripts/ProxmoxVE/pull/6293))

  - #### ✨ New Features

    - [core]: create_lxc: better handling, fix lock handling, improve template validation & storage selection UX [@MickLesk](https://github.com/MickLesk) ([#6296](https://github.com/community-scripts/ProxmoxVE/pull/6296))
    - ProxmoxVE 9.0 Beta: add BETA Version as test in pve_check [@MickLesk](https://github.com/MickLesk) ([#6295](https://github.com/community-scripts/ProxmoxVE/pull/6295))
    - karakeep: Run workers in prod without tsx [@vhsdream](https://github.com/vhsdream) ([#6285](https://github.com/community-scripts/ProxmoxVE/pull/6285))

  - #### 🔧 Refactor

    - Refactor: grocy [@tremor021](https://github.com/tremor021) ([#6307](https://github.com/community-scripts/ProxmoxVE/pull/6307))
    - Refactor: Navidrome [@tremor021](https://github.com/tremor021) ([#6300](https://github.com/community-scripts/ProxmoxVE/pull/6300))
    - Refactor: Gotify [@tremor021](https://github.com/tremor021) ([#6301](https://github.com/community-scripts/ProxmoxVE/pull/6301))
    - Refactor: Grafana [@tremor021](https://github.com/tremor021) ([#6306](https://github.com/community-scripts/ProxmoxVE/pull/6306))
    - Refactor: Argus [@tremor021](https://github.com/tremor021) ([#6305](https://github.com/community-scripts/ProxmoxVE/pull/6305))
    - n8n: refactor environmentfile [@CrazyWolf13](https://github.com/CrazyWolf13) ([#6297](https://github.com/community-scripts/ProxmoxVE/pull/6297))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - temp change the analytics url to one that works untill community one is fixed [@BramSuurdje](https://github.com/BramSuurdje) ([#6319](https://github.com/community-scripts/ProxmoxVE/pull/6319))

## 2025-07-27

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - karakeep: export DATA_DIR from user config in update [@vhsdream](https://github.com/vhsdream) ([#6283](https://github.com/community-scripts/ProxmoxVE/pull/6283))
    - go2rtc: Fix release download handling [@tremor021](https://github.com/tremor021) ([#6280](https://github.com/community-scripts/ProxmoxVE/pull/6280))

## 2025-07-26

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - PiAlert: Update dependencies [@leiweibau](https://github.com/leiweibau) ([#6251](https://github.com/community-scripts/ProxmoxVE/pull/6251))

## 2025-07-25

### 🆕 New Scripts

  - Cleanuparr ([#6238](https://github.com/community-scripts/ProxmoxVE/pull/6238))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Immich: fix #6236 [@vhsdream](https://github.com/vhsdream) ([#6243](https://github.com/community-scripts/ProxmoxVE/pull/6243))
    - Wizarr: use absolute path to uv [@vhsdream](https://github.com/vhsdream) ([#6221](https://github.com/community-scripts/ProxmoxVE/pull/6221))
    - Immich v1.136.0 [@vhsdream](https://github.com/vhsdream) ([#6219](https://github.com/community-scripts/ProxmoxVE/pull/6219))

## 2025-07-24

### 🆕 New Scripts

  - Alpine TeamSpeak Server [@tremor021](https://github.com/tremor021) ([#6201](https://github.com/community-scripts/ProxmoxVE/pull/6201))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Immich: Pin Version to v1.135.3 [@MickLesk](https://github.com/MickLesk) ([#6212](https://github.com/community-scripts/ProxmoxVE/pull/6212))
    - Habitica: force npm to 10 [@MickLesk](https://github.com/MickLesk) ([#6192](https://github.com/community-scripts/ProxmoxVE/pull/6192))
    - sabnzbd: add uv setup in update [@MickLesk](https://github.com/MickLesk) ([#6191](https://github.com/community-scripts/ProxmoxVE/pull/6191))

  - #### ✨ New Features

    - SnipeIT - Update dependencies  [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#6217](https://github.com/community-scripts/ProxmoxVE/pull/6217))
    - Refactor: VictoriaMetrics [@tremor021](https://github.com/tremor021) ([#6210](https://github.com/community-scripts/ProxmoxVE/pull/6210))
    - Headscale: Add headscale-admin UI as option [@tremor021](https://github.com/tremor021) ([#6205](https://github.com/community-scripts/ProxmoxVE/pull/6205))

  - #### 🔧 Refactor

    - Refactor: Gokapi [@tremor021](https://github.com/tremor021) ([#6197](https://github.com/community-scripts/ProxmoxVE/pull/6197))
    - Refactor: duplicati [@tremor021](https://github.com/tremor021) ([#6202](https://github.com/community-scripts/ProxmoxVE/pull/6202))
    - Refactor: go2rtc [@tremor021](https://github.com/tremor021) ([#6198](https://github.com/community-scripts/ProxmoxVE/pull/6198))
    - Refactor: Headscale [@tremor021](https://github.com/tremor021) ([#6180](https://github.com/community-scripts/ProxmoxVE/pull/6180))

## 2025-07-23

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - documenso: remove customerId by creating initial user [@MickLesk](https://github.com/MickLesk) ([#6171](https://github.com/community-scripts/ProxmoxVE/pull/6171))

## 2025-07-22

### 🆕 New Scripts

  - Salt ([#6116](https://github.com/community-scripts/ProxmoxVE/pull/6116))
- LinkStack ([#6137](https://github.com/community-scripts/ProxmoxVE/pull/6137))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - tools.func - fix typo for target_file [@tjcomserv](https://github.com/tjcomserv) ([#6156](https://github.com/community-scripts/ProxmoxVE/pull/6156))
    - fix(nginxproxymanager.sh): Set the version number before build. [@JMarcosHP](https://github.com/JMarcosHP) ([#6139](https://github.com/community-scripts/ProxmoxVE/pull/6139))

  - #### ✨ New Features

    - Fixed the previous fix of the anti-nag hook and propagated fixes everywhere [@imcrazytwkr](https://github.com/imcrazytwkr) ([#6162](https://github.com/community-scripts/ProxmoxVE/pull/6162))
    - [core]: Improved LXC Container Startup Handling [@MickLesk](https://github.com/MickLesk) ([#6142](https://github.com/community-scripts/ProxmoxVE/pull/6142))
    - wallos: add cron in installer for yearly cost [@CrazyWolf13](https://github.com/CrazyWolf13) ([#6133](https://github.com/community-scripts/ProxmoxVE/pull/6133))

  - #### 💥 Breaking Changes

    - gitea-mirror: add: migration to 3.0 [@CrazyWolf13](https://github.com/CrazyWolf13) ([#6138](https://github.com/community-scripts/ProxmoxVE/pull/6138))

  - #### 🔧 Refactor

    - [core]: tools.func: increase setup_php function [@MickLesk](https://github.com/MickLesk) ([#6141](https://github.com/community-scripts/ProxmoxVE/pull/6141))

### 🌐 Website

  - Bump form-data from 4.0.3 to 4.0.4 in /frontend [@dependabot[bot]](https://github.com/dependabot[bot]) ([#6150](https://github.com/community-scripts/ProxmoxVE/pull/6150))

## 2025-07-21

### 🆕 New Scripts

  - Teamspeak-Server ([#6121](https://github.com/community-scripts/ProxmoxVE/pull/6121))

### 🚀 Updated Scripts

  - pve-post-installer: remove Nag-File if already exist [@luckman212](https://github.com/luckman212) ([#6098](https://github.com/community-scripts/ProxmoxVE/pull/6098))

  - #### 🐞 Bug Fixes

    - firefly: fix permissions at update [@MickLesk](https://github.com/MickLesk) ([#6119](https://github.com/community-scripts/ProxmoxVE/pull/6119))
    - nginxproxymanager: remove injected footer link (tteck) [@MickLesk](https://github.com/MickLesk) ([#6117](https://github.com/community-scripts/ProxmoxVE/pull/6117))

## 2025-07-20

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Fix OpenWebUI install/update scripts [@karamanliev](https://github.com/karamanliev) ([#6093](https://github.com/community-scripts/ProxmoxVE/pull/6093))

  - #### ✨ New Features

    - karakeep: add DB_WAL_MODE; suppress test output [@vhsdream](https://github.com/vhsdream) ([#6101](https://github.com/community-scripts/ProxmoxVE/pull/6101))

## 2025-07-19

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Fixed nag script on ProxMox 8.4.5 [@imcrazytwkr](https://github.com/imcrazytwkr) ([#6084](https://github.com/community-scripts/ProxmoxVE/pull/6084))

## 2025-07-18

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - AdventureLog: add backup folder before update [@MickLesk](https://github.com/MickLesk) ([#6066](https://github.com/community-scripts/ProxmoxVE/pull/6066))

  - #### ✨ New Features

    - Bar-Assistant: add Cocktail database [@MickLesk](https://github.com/MickLesk) ([#6068](https://github.com/community-scripts/ProxmoxVE/pull/6068))
    - ErsatzTV: use project prebuild ffmpeg version [@MickLesk](https://github.com/MickLesk) ([#6067](https://github.com/community-scripts/ProxmoxVE/pull/6067))

## 2025-07-17

### 🆕 New Scripts

  - Cloudreve ([#6044](https://github.com/community-scripts/ProxmoxVE/pull/6044))

### 🚀 Updated Scripts

  - config-file: set GATE [@ahmaddxb](https://github.com/ahmaddxb) ([#6042](https://github.com/community-scripts/ProxmoxVE/pull/6042))

  - #### 🐞 Bug Fixes

    - add "setup_composer" in update_script (baikal, bar-assistant, firefly) [@MickLesk](https://github.com/MickLesk) ([#6047](https://github.com/community-scripts/ProxmoxVE/pull/6047))
    - PLANKA: Fix update procedure [@tremor021](https://github.com/tremor021) ([#6031](https://github.com/community-scripts/ProxmoxVE/pull/6031))

  - #### ✨ New Features

    - Reactive Resume: switch source to community-maintained fork [@vhsdream](https://github.com/vhsdream) ([#6051](https://github.com/community-scripts/ProxmoxVE/pull/6051))

## 2025-07-16

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - homepage.sh: resolves #6028 [@vhsdream](https://github.com/vhsdream) ([#6032](https://github.com/community-scripts/ProxmoxVE/pull/6032))
    - karakeep-install: Disable Playwright browser download, remove MCP build [@vhsdream](https://github.com/vhsdream) ([#5833](https://github.com/community-scripts/ProxmoxVE/pull/5833))

  - #### 🔧 Refactor

    - chore: reorganize nginxproxymanager update script [@Kirbo](https://github.com/Kirbo) ([#5971](https://github.com/community-scripts/ProxmoxVE/pull/5971))

## 2025-07-15

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - checkmk: change password crawling based on there docs [@MickLesk](https://github.com/MickLesk) ([#6001](https://github.com/community-scripts/ProxmoxVE/pull/6001))
    - Whiptail: Improve Dialogue to work with ESC [@MickLesk](https://github.com/MickLesk) ([#6003](https://github.com/community-scripts/ProxmoxVE/pull/6003))
    - 2FAuth: Improve Update-Check [@MickLesk](https://github.com/MickLesk) ([#5998](https://github.com/community-scripts/ProxmoxVE/pull/5998))

  - #### 💥 Breaking Changes

    - EMQX: Purge Old Install (remove acl.conf too!) [@MickLesk](https://github.com/MickLesk) ([#5999](https://github.com/community-scripts/ProxmoxVE/pull/5999))

  - #### 🔧 Refactor

    - Refactor: PeaNUT [@MickLesk](https://github.com/MickLesk) ([#6002](https://github.com/community-scripts/ProxmoxVE/pull/6002))

## 2025-07-14

### 🆕 New Scripts

  - Bar Assistant ([#5977](https://github.com/community-scripts/ProxmoxVE/pull/5977))
- Mealie ([#5968](https://github.com/community-scripts/ProxmoxVE/pull/5968))

### 🚀 Updated Scripts

  - Config-File: Some Addons, Bugfixes...  [@MickLesk](https://github.com/MickLesk) ([#5978](https://github.com/community-scripts/ProxmoxVE/pull/5978))

  - #### 🐞 Bug Fixes

    - add --break-system-packages certbot-dns-cloudflare to the nginxproxym… [@tug-benson](https://github.com/tug-benson) ([#5957](https://github.com/community-scripts/ProxmoxVE/pull/5957))
    - Dashy: remove unbound variable (RELEASE) [@MickLesk](https://github.com/MickLesk) ([#5974](https://github.com/community-scripts/ProxmoxVE/pull/5974))

### 🌐 Website

  - #### 📝 Script Information

    - Update nic-offloading-fix: add Intel as search Text  [@calvin-li-developer](https://github.com/calvin-li-developer) ([#5954](https://github.com/community-scripts/ProxmoxVE/pull/5954))

## 2025-07-12

## 2025-07-11

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - immich: hotfix #5921 [@vhsdream](https://github.com/vhsdream) ([#5938](https://github.com/community-scripts/ProxmoxVE/pull/5938))
    - bookstack: add setup_composer in update [@MickLesk](https://github.com/MickLesk) ([#5935](https://github.com/community-scripts/ProxmoxVE/pull/5935))
    - Quickfix: Immich: revert install sequence [@vhsdream](https://github.com/vhsdream) ([#5932](https://github.com/community-scripts/ProxmoxVE/pull/5932))

  - #### ✨ New Features

    - Refactor & Function Bump: Docker [@MickLesk](https://github.com/MickLesk) ([#5889](https://github.com/community-scripts/ProxmoxVE/pull/5889))

  - #### 🔧 Refactor

    - Immich: handle custom library dependency updates; other fixes [@vhsdream](https://github.com/vhsdream) ([#5896](https://github.com/community-scripts/ProxmoxVE/pull/5896))

## 2025-07-10

### 🚀 Updated Scripts

  - Refactor: Habitica [@MickLesk](https://github.com/MickLesk) ([#5911](https://github.com/community-scripts/ProxmoxVE/pull/5911))

  - #### 🐞 Bug Fixes

    - core: fix breaking re-download of lxc containers  [@MickLesk](https://github.com/MickLesk) ([#5906](https://github.com/community-scripts/ProxmoxVE/pull/5906))
    - PLANKA: Fix paths to application directory [@tremor021](https://github.com/tremor021) ([#5900](https://github.com/community-scripts/ProxmoxVE/pull/5900))

  - #### 🔧 Refactor

    - Refactor: EMQX + Update-Function + Improved NodeJS Crawling [@MickLesk](https://github.com/MickLesk) ([#5907](https://github.com/community-scripts/ProxmoxVE/pull/5907))

## 2025-07-09

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Omada Update: add missing exit  [@MickLesk](https://github.com/MickLesk) ([#5894](https://github.com/community-scripts/ProxmoxVE/pull/5894))
    - FreshRSS: fix needed php modules [@MickLesk](https://github.com/MickLesk) ([#5886](https://github.com/community-scripts/ProxmoxVE/pull/5886))
    - core: Fix VAAPI passthrough for unprivileged LXC containers via devX  [@MickLesk](https://github.com/MickLesk) ([#5875](https://github.com/community-scripts/ProxmoxVE/pull/5875))
    - tools.func: fix an bug while php libapache2-mod breaks [@MickLesk](https://github.com/MickLesk) ([#5857](https://github.com/community-scripts/ProxmoxVE/pull/5857))
    - BabyBuddy: fix path issues for update [@MickLesk](https://github.com/MickLesk) ([#5856](https://github.com/community-scripts/ProxmoxVE/pull/5856))

  - #### ✨ New Features

    - tools.func: strip leading folders for prebuild assets [@MickLesk](https://github.com/MickLesk) ([#5865](https://github.com/community-scripts/ProxmoxVE/pull/5865))

  - #### 💥 Breaking Changes

    - Refactor: Stirling-PDF [@MickLesk](https://github.com/MickLesk) ([#5872](https://github.com/community-scripts/ProxmoxVE/pull/5872))

  - #### 🔧 Refactor

    - Refactor: EMQX [@tremor021](https://github.com/tremor021) ([#5840](https://github.com/community-scripts/ProxmoxVE/pull/5840))
    - Refactor: Excalidraw [@tremor021](https://github.com/tremor021) ([#5841](https://github.com/community-scripts/ProxmoxVE/pull/5841))
    - Refactor: Firefly [@tremor021](https://github.com/tremor021) ([#5844](https://github.com/community-scripts/ProxmoxVE/pull/5844))
    - Refactor: gatus [@tremor021](https://github.com/tremor021) ([#5849](https://github.com/community-scripts/ProxmoxVE/pull/5849))
    - Refactor: FreshRSS [@tremor021](https://github.com/tremor021) ([#5847](https://github.com/community-scripts/ProxmoxVE/pull/5847))
    - Refactor: Fluid-Calendar [@tremor021](https://github.com/tremor021) ([#5846](https://github.com/community-scripts/ProxmoxVE/pull/5846))
    - Refactor: Commafeed [@tremor021](https://github.com/tremor021) ([#5802](https://github.com/community-scripts/ProxmoxVE/pull/5802))
    - Refactor: FlareSolverr [@tremor021](https://github.com/tremor021) ([#5845](https://github.com/community-scripts/ProxmoxVE/pull/5845))
    - Refactor: Glance [@tremor021](https://github.com/tremor021) ([#5874](https://github.com/community-scripts/ProxmoxVE/pull/5874))
    - Refactor: Gitea [@tremor021](https://github.com/tremor021) ([#5876](https://github.com/community-scripts/ProxmoxVE/pull/5876))
    - Refactor: Ghost (use now MySQL)  [@MickLesk](https://github.com/MickLesk) ([#5871](https://github.com/community-scripts/ProxmoxVE/pull/5871))

### 🧰 Maintenance

  - #### 📂 Github

    - Github: AutoLabler | ChangeLog (Refactor) [@MickLesk](https://github.com/MickLesk) ([#5868](https://github.com/community-scripts/ProxmoxVE/pull/5868))

## 2025-07-08

### 🚀 Updated Scripts

  - Refactor: Emby [@tremor021](https://github.com/tremor021) ([#5839](https://github.com/community-scripts/ProxmoxVE/pull/5839))

  - #### 🐞 Bug Fixes

    - Ollama: fix update script [@lucacome](https://github.com/lucacome) ([#5819](https://github.com/community-scripts/ProxmoxVE/pull/5819))

  - #### ✨ New Features

    - tools.func: add ffmpeg + minor improvement [@MickLesk](https://github.com/MickLesk) ([#5834](https://github.com/community-scripts/ProxmoxVE/pull/5834))

  - #### 🔧 Refactor

    - Refactor: ErsatzTV [@MickLesk](https://github.com/MickLesk) ([#5835](https://github.com/community-scripts/ProxmoxVE/pull/5835))

## 2025-07-07

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Fix/stirling pdf script [@JcMinarro](https://github.com/JcMinarro) ([#5803](https://github.com/community-scripts/ProxmoxVE/pull/5803))
    - gitea-mirror: update repo-url [@CrazyWolf13](https://github.com/CrazyWolf13) ([#5794](https://github.com/community-scripts/ProxmoxVE/pull/5794))
    - Fix unbound var in pulse.sh [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#5807](https://github.com/community-scripts/ProxmoxVE/pull/5807))
    - Bookstack: Fix PHP Issue & Bump to PHP 8.3 [@MickLesk](https://github.com/MickLesk) ([#5779](https://github.com/community-scripts/ProxmoxVE/pull/5779))

  - #### ✨ New Features

    - Refactor: Threadfin (+ updatable) [@MickLesk](https://github.com/MickLesk) ([#5783](https://github.com/community-scripts/ProxmoxVE/pull/5783))
    - tools.func: better handling when unpacking tarfiles in prebuild mode [@MickLesk](https://github.com/MickLesk) ([#5781](https://github.com/community-scripts/ProxmoxVE/pull/5781))
    - tools.func: add AVX check for MongoDB [@MickLesk](https://github.com/MickLesk) ([#5780](https://github.com/community-scripts/ProxmoxVE/pull/5780))

  - #### 🔧 Refactor

    - Refactor: Docmost [@tremor021](https://github.com/tremor021) ([#5806](https://github.com/community-scripts/ProxmoxVE/pull/5806))
    - Refactor: Baby Buddy [@tremor021](https://github.com/tremor021) ([#5769](https://github.com/community-scripts/ProxmoxVE/pull/5769))
    - Refactor: Changed the way we install BunkerWeb by leveraging the brand new install-bunkerweb.sh [@TheophileDiot](https://github.com/TheophileDiot) ([#5707](https://github.com/community-scripts/ProxmoxVE/pull/5707))

### 🌐 Website

  - #### 📝 Script Information

    - PBS: add hint for advanced installs [@MickLesk](https://github.com/MickLesk) ([#5788](https://github.com/community-scripts/ProxmoxVE/pull/5788))
    - EMQX: Add warning to website [@tremor021](https://github.com/tremor021) ([#5770](https://github.com/community-scripts/ProxmoxVE/pull/5770))

## 2025-07-06

### 🚀 Updated Scripts

  - Refactor: Barcodebuddy [@tremor021](https://github.com/tremor021) ([#5735](https://github.com/community-scripts/ProxmoxVE/pull/5735))

  - #### 🐞 Bug Fixes

    - Fix update script for Mafl: ensure directory is removed recursively [@jonalbr](https://github.com/jonalbr) ([#5759](https://github.com/community-scripts/ProxmoxVE/pull/5759))
    - BookStack: Typo fix [@tremor021](https://github.com/tremor021) ([#5746](https://github.com/community-scripts/ProxmoxVE/pull/5746))
    - Resolves incorrect URL at end of Pocket ID script [@johnsturgeon](https://github.com/johnsturgeon) ([#5743](https://github.com/community-scripts/ProxmoxVE/pull/5743))

  - #### ✨ New Features

    - [Feature] Add option to expose Docker via TCP port (alpine docker) [@oformaniuk](https://github.com/oformaniuk) ([#5716](https://github.com/community-scripts/ProxmoxVE/pull/5716))

  - #### 🔧 Refactor

    - Refactor: Bitmagnet [@tremor021](https://github.com/tremor021) ([#5733](https://github.com/community-scripts/ProxmoxVE/pull/5733))
    - Refactor: Baikal [@tremor021](https://github.com/tremor021) ([#5736](https://github.com/community-scripts/ProxmoxVE/pull/5736))

## 2025-07-05

### 🚀 Updated Scripts

  - #### 🔧 Refactor

    - Refactor: BookStack [@tremor021](https://github.com/tremor021) ([#5732](https://github.com/community-scripts/ProxmoxVE/pull/5732))
    - Refactor: Authelia [@tremor021](https://github.com/tremor021) ([#5722](https://github.com/community-scripts/ProxmoxVE/pull/5722))
    - Refactor: Dashy [@tremor021](https://github.com/tremor021) ([#5723](https://github.com/community-scripts/ProxmoxVE/pull/5723))
    - Refactor: CryptPad [@tremor021](https://github.com/tremor021) ([#5724](https://github.com/community-scripts/ProxmoxVE/pull/5724))
    - Refactor: ByteStash [@tremor021](https://github.com/tremor021) ([#5725](https://github.com/community-scripts/ProxmoxVE/pull/5725))
    - Refactor: AgentDVR [@tremor021](https://github.com/tremor021) ([#5726](https://github.com/community-scripts/ProxmoxVE/pull/5726))

## 2025-07-04

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Refactor: Mafl [@tremor021](https://github.com/tremor021) ([#5702](https://github.com/community-scripts/ProxmoxVE/pull/5702))
    - Outline: Fix sed command for v0.85.0 [@tremor021](https://github.com/tremor021) ([#5688](https://github.com/community-scripts/ProxmoxVE/pull/5688))
    - Komodo: Update Script to use FerretDB / remove psql & sqlite options [@MickLesk](https://github.com/MickLesk) ([#5690](https://github.com/community-scripts/ProxmoxVE/pull/5690))
    - ESPHome: Fix Linking issue to prevent version mismatch [@MickLesk](https://github.com/MickLesk) ([#5685](https://github.com/community-scripts/ProxmoxVE/pull/5685))
    - Cloudflare-DDNS: fix unvisible read command at install [@MickLesk](https://github.com/MickLesk) ([#5682](https://github.com/community-scripts/ProxmoxVE/pull/5682))

  - #### ✨ New Features

    - Core layer refactor: centralized error traps and msg_* consistency [@MickLesk](https://github.com/MickLesk) ([#5705](https://github.com/community-scripts/ProxmoxVE/pull/5705))

  - #### 💥 Breaking Changes

    - Update Iptag [@DesertGamer](https://github.com/DesertGamer) ([#5677](https://github.com/community-scripts/ProxmoxVE/pull/5677))

### 🌐 Website

  - #### 📝 Script Information

    - MySQL phpMyAdmin Access Information [@austinpilz](https://github.com/austinpilz) ([#5679](https://github.com/community-scripts/ProxmoxVE/pull/5679))

## 2025-07-03

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Zipline: Fix typo in uploads directory path [@tremor021](https://github.com/tremor021) ([#5662](https://github.com/community-scripts/ProxmoxVE/pull/5662))

  - #### ✨ New Features

    - Improve asset matching in fetch_and_deploy_gh_release for prebuild and singlefile modes [@MickLesk](https://github.com/MickLesk) ([#5669](https://github.com/community-scripts/ProxmoxVE/pull/5669))

  - #### 🔧 Refactor

    - Refactor: Trilium [@MickLesk](https://github.com/MickLesk) ([#5665](https://github.com/community-scripts/ProxmoxVE/pull/5665))

### 🌐 Website

  - #### 📝 Script Information

    - Bump Icons to selfhst repo | switch svg to webp [@MickLesk](https://github.com/MickLesk) ([#5659](https://github.com/community-scripts/ProxmoxVE/pull/5659))

## 2025-07-02

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Changedetection: Base64 encode the launch options [@tremor021](https://github.com/tremor021) ([#5640](https://github.com/community-scripts/ProxmoxVE/pull/5640))

  - #### 🔧 Refactor

    - Refactor & Bump to Node24: Zigbee2MQTT [@MickLesk](https://github.com/MickLesk) ([#5638](https://github.com/community-scripts/ProxmoxVE/pull/5638))

### 🌐 Website

  - #### 💥 Breaking Changes

    - Remove: Pingvin-Share [@MickLesk](https://github.com/MickLesk) ([#5635](https://github.com/community-scripts/ProxmoxVE/pull/5635))
    - Remove: Readarr [@MickLesk](https://github.com/MickLesk) ([#5636](https://github.com/community-scripts/ProxmoxVE/pull/5636))

## 2025-07-01

### 🆕 New Scripts

  - Librespeed Rust ([#5614](https://github.com/community-scripts/ProxmoxVE/pull/5614))
- ITSM-NG ([#5615](https://github.com/community-scripts/ProxmoxVE/pull/5615))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Open WebUI: Fix Ollama update procedure [@tremor021](https://github.com/tremor021) ([#5601](https://github.com/community-scripts/ProxmoxVE/pull/5601))

  - #### ✨ New Features

    - [tools]: increase fetch_and_deploy with dns pre check [@MickLesk](https://github.com/MickLesk) ([#5608](https://github.com/community-scripts/ProxmoxVE/pull/5608))

### 🌐 Website

  - #### 📝 Script Information

    - Jellyfin GPU Passthrough NVIDIA Note [@austinpilz](https://github.com/austinpilz) ([#5625](https://github.com/community-scripts/ProxmoxVE/pull/5625))

## 2025-06-30

### 🆕 New Scripts

  - Alpine Syncthing [@MickLesk](https://github.com/MickLesk) ([#5586](https://github.com/community-scripts/ProxmoxVE/pull/5586))
- Kapowarr ([#5584](https://github.com/community-scripts/ProxmoxVE/pull/5584))

### 🚀 Updated Scripts

  - Fixing Cloudflare DDNS - lack of resources [@meszolym](https://github.com/meszolym) ([#5600](https://github.com/community-scripts/ProxmoxVE/pull/5600))

  - #### 🐞 Bug Fixes

    - Immich: make changes to automatically enable QuickSync [@vhsdream](https://github.com/vhsdream) ([#5560](https://github.com/community-scripts/ProxmoxVE/pull/5560))
    - Apache Guacamole: Install auth-jdbc component that matches release version [@tremor021](https://github.com/tremor021) ([#5563](https://github.com/community-scripts/ProxmoxVE/pull/5563))

  - #### ✨ New Features

    - tools.func: optimize binary installs with fetch_and_deploy helper [@MickLesk](https://github.com/MickLesk) ([#5588](https://github.com/community-scripts/ProxmoxVE/pull/5588))
    - [core]: add ipv6 configuration support [@MickLesk](https://github.com/MickLesk) ([#5575](https://github.com/community-scripts/ProxmoxVE/pull/5575))

## 2025-06-29

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Linkwarden: Add backing up of data folder to the update function [@tremor021](https://github.com/tremor021) ([#5548](https://github.com/community-scripts/ProxmoxVE/pull/5548))

  - #### ✨ New Features

    - Add cron-job api-key env variable to homarr script [@Meierschlumpf](https://github.com/Meierschlumpf) ([#5204](https://github.com/community-scripts/ProxmoxVE/pull/5204))

### 🧰 Maintenance

  - #### 📝 Documentation

    - update readme with valid discord link. other one expired [@BramSuurdje](https://github.com/BramSuurdje) ([#5567](https://github.com/community-scripts/ProxmoxVE/pull/5567))

### 🌐 Website

  - Update script-item.tsx [@ape364](https://github.com/ape364) ([#5549](https://github.com/community-scripts/ProxmoxVE/pull/5549))

  - #### 🐞 Bug Fixes

    - fix bug in tooltip that would always render 'updateable' [@BramSuurdje](https://github.com/BramSuurdje) ([#5552](https://github.com/community-scripts/ProxmoxVE/pull/5552))

## 2025-06-28

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Ollama: Clean up old Ollama files before running update [@tremor021](https://github.com/tremor021) ([#5534](https://github.com/community-scripts/ProxmoxVE/pull/5534))
    - ONLYOFFICE: Update install script to manually create RabbitMQ user [@tremor021](https://github.com/tremor021) ([#5535](https://github.com/community-scripts/ProxmoxVE/pull/5535))

### 🌐 Website

  - #### 📝 Script Information

    - Booklore: Correct documentation and website  [@pieman3000](https://github.com/pieman3000) ([#5528](https://github.com/community-scripts/ProxmoxVE/pull/5528))

## 2025-06-27

### 🆕 New Scripts

  - BookLore ([#5524](https://github.com/community-scripts/ProxmoxVE/pull/5524))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - wizarr: remove unneeded tmp file [@MickLesk](https://github.com/MickLesk) ([#5517](https://github.com/community-scripts/ProxmoxVE/pull/5517))

### 🧰 Maintenance

  - #### 🐞 Bug Fixes

    - Remove npm legacy errors, created single source of truth for ESlint. updated analytics url. updated script background [@BramSuurdje](https://github.com/BramSuurdje) ([#5498](https://github.com/community-scripts/ProxmoxVE/pull/5498))

  - #### 📂 Github

    - New workflow to push to gitea and change links to gitea [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#5510](https://github.com/community-scripts/ProxmoxVE/pull/5510))

### 🌐 Website

  - #### 📝 Script Information

    - Wireguard, Update Link to Documentation. [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#5514](https://github.com/community-scripts/ProxmoxVE/pull/5514))

## 2025-06-26

### 🆕 New Scripts

  - ConvertX ([#5484](https://github.com/community-scripts/ProxmoxVE/pull/5484))

### 🚀 Updated Scripts

  - [tools] Update setup_nodejs function [@tremor021](https://github.com/tremor021) ([#5488](https://github.com/community-scripts/ProxmoxVE/pull/5488))
- [tools] Fix setup_mongodb function [@tremor021](https://github.com/tremor021) ([#5486](https://github.com/community-scripts/ProxmoxVE/pull/5486))

## 2025-06-25

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Docmost: Increase resources [@tremor021](https://github.com/tremor021) ([#5458](https://github.com/community-scripts/ProxmoxVE/pull/5458))

  - #### ✨ New Features

    - tools.func: new helper for imagemagick [@MickLesk](https://github.com/MickLesk) ([#5452](https://github.com/community-scripts/ProxmoxVE/pull/5452))
    - YunoHost: add Update-Function [@MickLesk](https://github.com/MickLesk) ([#5450](https://github.com/community-scripts/ProxmoxVE/pull/5450))

  - #### 🔧 Refactor

    - Refactor: Tailscale  [@MickLesk](https://github.com/MickLesk) ([#5454](https://github.com/community-scripts/ProxmoxVE/pull/5454))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - Update Tooltips component to conditionally display updateable status based on item type [@BramSuurdje](https://github.com/BramSuurdje) ([#5461](https://github.com/community-scripts/ProxmoxVE/pull/5461))
    - Refactor CommandMenu to prevent duplicate scripts across categories [@BramSuurdje](https://github.com/BramSuurdje) ([#5463](https://github.com/community-scripts/ProxmoxVE/pull/5463))

  - #### ✨ New Features

    - Enhance InstallCommand component to support Gitea as an alternative source for installation scripts. [@BramSuurdje](https://github.com/BramSuurdje) ([#5464](https://github.com/community-scripts/ProxmoxVE/pull/5464))

  - #### 📝 Script Information

    - Website: mark VM's and "OS"-LXC's as updatable [@MickLesk](https://github.com/MickLesk) ([#5453](https://github.com/community-scripts/ProxmoxVE/pull/5453))

## 2025-06-24

### 🆕 New Scripts

  - ONLYOFFICE Docs ([#5420](https://github.com/community-scripts/ProxmoxVE/pull/5420))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - GoMFT: tmpl bugfix to work with current version until a new release pushed [@MickLesk](https://github.com/MickLesk) ([#5435](https://github.com/community-scripts/ProxmoxVE/pull/5435))
    - Update all Alpine Scripts to atleast 1GB HDD [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#5418](https://github.com/community-scripts/ProxmoxVE/pull/5418))

  - #### ✨ New Features

    - general: update all alpine scripts to version 3.22 [@MickLesk](https://github.com/MickLesk) ([#5428](https://github.com/community-scripts/ProxmoxVE/pull/5428))
    - Minio: use latest version or latest feature rich version [@MickLesk](https://github.com/MickLesk) ([#5423](https://github.com/community-scripts/ProxmoxVE/pull/5423))
    - [core]: Improve GitHub release fetch robustness with split timeouts and retry logic [@MickLesk](https://github.com/MickLesk) ([#5422](https://github.com/community-scripts/ProxmoxVE/pull/5422))

  - #### 💥 Breaking Changes

    - bump scripts (Installer) from Ubuntu 22.04 to Ubuntu 24.04 (agentdvr, emby, jellyfin, plex, shinobi) [@MickLesk](https://github.com/MickLesk) ([#5434](https://github.com/community-scripts/ProxmoxVE/pull/5434))

  - #### 🔧 Refactor

    - Refactor: MeTube to uv based install [@MickLesk](https://github.com/MickLesk) ([#5411](https://github.com/community-scripts/ProxmoxVE/pull/5411))
    - Refactor: Prometheus PVE Exporter to uv based install [@MickLesk](https://github.com/MickLesk) ([#5412](https://github.com/community-scripts/ProxmoxVE/pull/5412))
    - Refactor: ESPHome to uv based install [@MickLesk](https://github.com/MickLesk) ([#5413](https://github.com/community-scripts/ProxmoxVE/pull/5413))

## 2025-06-23

### 🆕 New Scripts

  - Alpine-Forgejo by @Johann3s-H [@MickLesk](https://github.com/MickLesk) ([#5396](https://github.com/community-scripts/ProxmoxVE/pull/5396))

### 🚀 Updated Scripts

  - [core]: tools.func -> autoupdate npm to newest version on install [@MickLesk](https://github.com/MickLesk) ([#5397](https://github.com/community-scripts/ProxmoxVE/pull/5397))

  - #### 🐞 Bug Fixes

    - PLANKA: Fix the update procedure [@tremor021](https://github.com/tremor021) ([#5391](https://github.com/community-scripts/ProxmoxVE/pull/5391))
    - changed trilium github repo [@miggi92](https://github.com/miggi92) ([#5390](https://github.com/community-scripts/ProxmoxVE/pull/5390))
    - changedetection: fix: hermetic msedge [@CrazyWolf13](https://github.com/CrazyWolf13) ([#5388](https://github.com/community-scripts/ProxmoxVE/pull/5388))

### 🌐 Website

  - #### 📝 Script Information

    - MariaDB: Add information about Adminer on website [@tremor021](https://github.com/tremor021) ([#5400](https://github.com/community-scripts/ProxmoxVE/pull/5400))

## 2025-06-22

### 🚀 Updated Scripts

  - [core]: fix timing issues while template update & timezone setup at create new LXC [@MickLesk](https://github.com/MickLesk) ([#5358](https://github.com/community-scripts/ProxmoxVE/pull/5358))
- alpine: increase hdd to 1gb [@MickLesk](https://github.com/MickLesk) ([#5377](https://github.com/community-scripts/ProxmoxVE/pull/5377))

  - #### 🐞 Bug Fixes

    - fix: casing and naming error after #5254 [@GoetzGoerisch](https://github.com/GoetzGoerisch) ([#5380](https://github.com/community-scripts/ProxmoxVE/pull/5380))
    - fix: install_adminer > setup_adminer [@MickLesk](https://github.com/MickLesk) ([#5356](https://github.com/community-scripts/ProxmoxVE/pull/5356))
    - gitea: Update gitea.sh to stop update failures [@tystuyfzand](https://github.com/tystuyfzand) ([#5361](https://github.com/community-scripts/ProxmoxVE/pull/5361))

  - #### 🔧 Refactor

    - Immich: unpin release; use fetch & deploy function for update [@vhsdream](https://github.com/vhsdream) ([#5355](https://github.com/community-scripts/ProxmoxVE/pull/5355))

## 2025-06-21

## 2025-06-20

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Immich: remove unneeded tmp_file [@MickLesk](https://github.com/MickLesk) ([#5332](https://github.com/community-scripts/ProxmoxVE/pull/5332))
    - Huntarr: Fix duplicate update status messages [@tremor021](https://github.com/tremor021) ([#5336](https://github.com/community-scripts/ProxmoxVE/pull/5336))
    - fix planka Tags [@CrazyWolf13](https://github.com/CrazyWolf13) ([#5311](https://github.com/community-scripts/ProxmoxVE/pull/5311))
    - PLANKA: Better DB password generate [@tremor021](https://github.com/tremor021) ([#5313](https://github.com/community-scripts/ProxmoxVE/pull/5313))
    - Immich: Hotfix for #5299 [@vhsdream](https://github.com/vhsdream) ([#5300](https://github.com/community-scripts/ProxmoxVE/pull/5300))
    - changedetection: add msedge as Browser dependency [@Niklas04](https://github.com/Niklas04) ([#5301](https://github.com/community-scripts/ProxmoxVE/pull/5301))

  - #### ✨ New Features

    - (turnkey) Add OpenLDAP as a TurnKey option [@mhaligowski](https://github.com/mhaligowski) ([#5305](https://github.com/community-scripts/ProxmoxVE/pull/5305))

  - #### 🔧 Refactor

    - [core]: unify misc/*.func scripts with centralized logic from core.func [@MickLesk](https://github.com/MickLesk) ([#5316](https://github.com/community-scripts/ProxmoxVE/pull/5316))
    - Refactor: migrate AdventureLog update to uv and GitHub release logic [@MickLesk](https://github.com/MickLesk) ([#5318](https://github.com/community-scripts/ProxmoxVE/pull/5318))
    - Refactor: migrate Jupyter Notebook to uv-based installation with update support [@MickLesk](https://github.com/MickLesk) ([#5320](https://github.com/community-scripts/ProxmoxVE/pull/5320))

### 🌐 Website

  - #### 📝 Script Information

    - Argus: fix wrong port on website [@MickLesk](https://github.com/MickLesk) ([#5322](https://github.com/community-scripts/ProxmoxVE/pull/5322))

## 2025-06-19

### 🆕 New Scripts

  - Ubuntu 25.04 VM [@MickLesk](https://github.com/MickLesk) ([#5284](https://github.com/community-scripts/ProxmoxVE/pull/5284))
- PLANKA ([#5277](https://github.com/community-scripts/ProxmoxVE/pull/5277))
- Wizarr ([#5273](https://github.com/community-scripts/ProxmoxVE/pull/5273))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - immich-install.sh: restore pgvector module install [@vhsdream](https://github.com/vhsdream) ([#5286](https://github.com/community-scripts/ProxmoxVE/pull/5286))
    - Immich: prepare for v1.135.0 [@vhsdream](https://github.com/vhsdream) ([#5025](https://github.com/community-scripts/ProxmoxVE/pull/5025))

### 🧰 Maintenance

  - #### ✨ New Features

    - [core]: Feature - Check Quorum Status in create_lxc to prevent issues [@MickLesk](https://github.com/MickLesk) ([#5278](https://github.com/community-scripts/ProxmoxVE/pull/5278))
    - [core]: add validation and replace recursion for invalid inputs in adv. settings [@MickLesk](https://github.com/MickLesk) ([#5291](https://github.com/community-scripts/ProxmoxVE/pull/5291))

### 🌐 Website

  - #### 📝 Script Information

    - cloudflare-ddns: fix typo in info-text [@LukaZagar](https://github.com/LukaZagar) ([#5263](https://github.com/community-scripts/ProxmoxVE/pull/5263))

## 2025-06-18

### 🆕 New Scripts

  - FileBrowser Quantum [@MickLesk](https://github.com/MickLesk) ([#5248](https://github.com/community-scripts/ProxmoxVE/pull/5248))
- Huntarr ([#5249](https://github.com/community-scripts/ProxmoxVE/pull/5249))

### 🚀 Updated Scripts

  - tools.func: Standardized and Renamed Setup Functions [@MickLesk](https://github.com/MickLesk) ([#5241](https://github.com/community-scripts/ProxmoxVE/pull/5241))

  - #### 🐞 Bug Fixes

    - Immich: fix prompt clobber issue [@vhsdream](https://github.com/vhsdream) ([#5231](https://github.com/community-scripts/ProxmoxVE/pull/5231))

  - #### 🔧 Refactor

    - Refactor all VM's to same logic & functions [@MickLesk](https://github.com/MickLesk) ([#5254](https://github.com/community-scripts/ProxmoxVE/pull/5254))
    - upgrade old Scriptcalls to new tools.func calls [@MickLesk](https://github.com/MickLesk) ([#5242](https://github.com/community-scripts/ProxmoxVE/pull/5242))

## 2025-06-17

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - gitea-mirror: increase build ressources  [@CrazyWolf13](https://github.com/CrazyWolf13) ([#5235](https://github.com/community-scripts/ProxmoxVE/pull/5235))
    - Immich: ensure in proper working dir when updating [@vhsdream](https://github.com/vhsdream) ([#5227](https://github.com/community-scripts/ProxmoxVE/pull/5227))
    - Update IP-Tag [@DesertGamer](https://github.com/DesertGamer) ([#5226](https://github.com/community-scripts/ProxmoxVE/pull/5226))
    - trilium: fix update function after db changes folder [@tjcomserv](https://github.com/tjcomserv) ([#5207](https://github.com/community-scripts/ProxmoxVE/pull/5207))

  - #### ✨ New Features

    - LibreTranslate: Add .env for easier configuration [@tremor021](https://github.com/tremor021) ([#5216](https://github.com/community-scripts/ProxmoxVE/pull/5216))

### 🌐 Website

  - #### 📝 Script Information

    - IPTag: Better explanation [@MickLesk](https://github.com/MickLesk) ([#5213](https://github.com/community-scripts/ProxmoxVE/pull/5213))

## 2025-06-16

### 🆕 New Scripts

  - Intel NIC offload Fix by @rcastley [@MickLesk](https://github.com/MickLesk) ([#5155](https://github.com/community-scripts/ProxmoxVE/pull/5155))

### 🚀 Updated Scripts

  - [core] Move install_php() from VED to main [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#5182](https://github.com/community-scripts/ProxmoxVE/pull/5182))
- Firefly: Add Data Importer to LXC [@tremor021](https://github.com/tremor021) ([#5159](https://github.com/community-scripts/ProxmoxVE/pull/5159))

  - #### 🐞 Bug Fixes

    - Wastebin: Fix missing dependencies [@tremor021](https://github.com/tremor021) ([#5185](https://github.com/community-scripts/ProxmoxVE/pull/5185))
    - Kasm: Storing Creds Fix [@omiinaya](https://github.com/omiinaya) ([#5162](https://github.com/community-scripts/ProxmoxVE/pull/5162))

  - #### ✨ New Features

    - add optional Cloud-init support to Debian VM script  [@koendiender](https://github.com/koendiender) ([#5137](https://github.com/community-scripts/ProxmoxVE/pull/5137))

  - #### 🔧 Refactor

    - Refactor: 2FAuth [@tremor021](https://github.com/tremor021) ([#5184](https://github.com/community-scripts/ProxmoxVE/pull/5184))

### 🌐 Website

  - Refactor layout and component styles for improved responsiveness [@BramSuurdje](https://github.com/BramSuurdje) ([#5195](https://github.com/community-scripts/ProxmoxVE/pull/5195))

  - #### 🐞 Bug Fixes

    - Refactor ScriptItem and ConfigFile components to conditionally render config file location. Update ConfigFile to accept configPath prop instead of item. [@BramSuurdje](https://github.com/BramSuurdje) ([#5197](https://github.com/community-scripts/ProxmoxVE/pull/5197))
    - Update default image asset in the public directory and update api route to only search for files that end with .json [@BramSuurdje](https://github.com/BramSuurdje) ([#5179](https://github.com/community-scripts/ProxmoxVE/pull/5179))

  - #### ✨ New Features

    - Update default image asset in the public directory [@BramSuurdje](https://github.com/BramSuurdje) ([#5189](https://github.com/community-scripts/ProxmoxVE/pull/5189))

## 2025-06-15

### 🆕 New Scripts

  - LibreTranslate ([#5154](https://github.com/community-scripts/ProxmoxVE/pull/5154))

## 2025-06-14

### 🚀 Updated Scripts

  - [core] Update install_mariadb func [@tremor021](https://github.com/tremor021) ([#5138](https://github.com/community-scripts/ProxmoxVE/pull/5138))

  - #### 🐞 Bug Fixes

    - flowiseai: set NodeJS to Version 20 [@MickLesk](https://github.com/MickLesk) ([#5130](https://github.com/community-scripts/ProxmoxVE/pull/5130))
    - Update dolibarr-install.sh - Get largest version number [@tjcomserv](https://github.com/tjcomserv) ([#5127](https://github.com/community-scripts/ProxmoxVE/pull/5127))

## 2025-06-13

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Zigbee2MQTT: Fix missing directory [@tremor021](https://github.com/tremor021) ([#5120](https://github.com/community-scripts/ProxmoxVE/pull/5120))

### 🌐 Website

  - #### 📝 Script Information

    - Umbrel OS: Fix bad disk size shown on website [@tremor021](https://github.com/tremor021) ([#5125](https://github.com/community-scripts/ProxmoxVE/pull/5125))

## 2025-06-12

### 🆕 New Scripts

  - Manage my Damn Life ([#5100](https://github.com/community-scripts/ProxmoxVE/pull/5100))

### 🚀 Updated Scripts

  - Kasm: Increase Ressources & Hint for Fuse / Swap [@MickLesk](https://github.com/MickLesk) ([#5112](https://github.com/community-scripts/ProxmoxVE/pull/5112))

## 2025-06-11

## 2025-06-10

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Element Synapse: switched from development to production mode and fixed update [@Frankmaaan](https://github.com/Frankmaaan) ([#5066](https://github.com/community-scripts/ProxmoxVE/pull/5066))
    - Tinyauth: Fix creation of service file [@tremor021](https://github.com/tremor021) ([#5090](https://github.com/community-scripts/ProxmoxVE/pull/5090))
    - Dolibarr: Fix typo in SQL command [@tremor021](https://github.com/tremor021) ([#5091](https://github.com/community-scripts/ProxmoxVE/pull/5091))

### 🧰 Maintenance

  - #### 📡 API

    - [core] Prevent API form sending Data when disabled [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#5080](https://github.com/community-scripts/ProxmoxVE/pull/5080))

### 🌐 Website

  - #### 📝 Script Information

    - Immich: Update JSON [@vhsdream](https://github.com/vhsdream) ([#5085](https://github.com/community-scripts/ProxmoxVE/pull/5085))

## 2025-06-09

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Authelia: Fix the URL of the container [@tremor021](https://github.com/tremor021) ([#5064](https://github.com/community-scripts/ProxmoxVE/pull/5064))

### 🌐 Website

  - GoMFT: Remove from website temporarily [@tremor021](https://github.com/tremor021) ([#5065](https://github.com/community-scripts/ProxmoxVE/pull/5065))

## 2025-06-08

### 🆕 New Scripts

  - Minarca ([#5058](https://github.com/community-scripts/ProxmoxVE/pull/5058))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - zot: fix missing var (Dev -> Main) [@MickLesk](https://github.com/MickLesk) ([#5056](https://github.com/community-scripts/ProxmoxVE/pull/5056))

  - #### ✨ New Features

    - karakeep: Add more configuration defaults [@vhsdream](https://github.com/vhsdream) ([#5054](https://github.com/community-scripts/ProxmoxVE/pull/5054))

## 2025-06-07

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - alpine-it-tools fix update [@CrazyWolf13](https://github.com/CrazyWolf13) ([#5039](https://github.com/community-scripts/ProxmoxVE/pull/5039))

### 🧰 Maintenance

  - #### 💾 Core

    - Fix typo in build.func [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#5041](https://github.com/community-scripts/ProxmoxVE/pull/5041))

## 2025-06-06

### 🆕 New Scripts

  - Zot-Registry ([#5016](https://github.com/community-scripts/ProxmoxVE/pull/5016))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - zipline: fix old upload copy from v3 to v4 [@MickLesk](https://github.com/MickLesk) ([#5015](https://github.com/community-scripts/ProxmoxVE/pull/5015))

## 2025-06-05

### 🆕 New Scripts

  - Lyrion Music Server ([#4992](https://github.com/community-scripts/ProxmoxVE/pull/4992))
- gitea-mirror ([#4967](https://github.com/community-scripts/ProxmoxVE/pull/4967))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Zipline: Fix PostgreSQL install [@tremor021](https://github.com/tremor021) ([#4989](https://github.com/community-scripts/ProxmoxVE/pull/4989))
    - Homarr: add nodejs upgrade [@CrazyWolf13](https://github.com/CrazyWolf13) ([#4974](https://github.com/community-scripts/ProxmoxVE/pull/4974))
    - add FUSE to rclone [@Frankmaaan](https://github.com/Frankmaaan) ([#4972](https://github.com/community-scripts/ProxmoxVE/pull/4972))

  - #### ✨ New Features

    - Zitadel: Upgrade Install to PSQL 17 [@MickLesk](https://github.com/MickLesk) ([#5000](https://github.com/community-scripts/ProxmoxVE/pull/5000))

### 🌐 Website

  - #### 📝 Script Information

    - Fix clean-lxcs.sh type categorization [@bitspill](https://github.com/bitspill) ([#4980](https://github.com/community-scripts/ProxmoxVE/pull/4980))

## 2025-06-04

### 🚀 Updated Scripts

  - Pulse: add polkit for sudoless web updates [@rcourtman](https://github.com/rcourtman) ([#4970](https://github.com/community-scripts/ProxmoxVE/pull/4970))
- Pulse: add correct Port for URL output  [@rcourtman](https://github.com/rcourtman) ([#4951](https://github.com/community-scripts/ProxmoxVE/pull/4951))

  - #### 🐞 Bug Fixes

    - [refactor] Seelf [@tremor021](https://github.com/tremor021) ([#4954](https://github.com/community-scripts/ProxmoxVE/pull/4954))

## 2025-06-03

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Kasm: Swap fix [@omiinaya](https://github.com/omiinaya) ([#4937](https://github.com/community-scripts/ProxmoxVE/pull/4937))

### 🌐 Website

  - #### 📝 Script Information

    - netbox: correct website URL  [@theincrediblenoone](https://github.com/theincrediblenoone) ([#4952](https://github.com/community-scripts/ProxmoxVE/pull/4952))

## 2025-06-02

### 🆕 New Scripts

  - PVE-Privilege-Converter [@MickLesk](https://github.com/MickLesk) ([#4906](https://github.com/community-scripts/ProxmoxVE/pull/4906))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - fix(wastebin): use tar asset [@dbeg](https://github.com/dbeg) ([#4934](https://github.com/community-scripts/ProxmoxVE/pull/4934))
    - MySQL/MariaDB: fix create user with password [@MickLesk](https://github.com/MickLesk) ([#4918](https://github.com/community-scripts/ProxmoxVE/pull/4918))
    - Fix alpine-tinyauth env configuration parsing logic [@gokussjx](https://github.com/gokussjx) ([#4901](https://github.com/community-scripts/ProxmoxVE/pull/4901))

  - #### 💥 Breaking Changes

    - make Pulse installation non-interactive [@rcourtman](https://github.com/rcourtman) ([#4848](https://github.com/community-scripts/ProxmoxVE/pull/4848))

### 🧰 Maintenance

  - #### 💾 Core

    - [core] add hw-accelerated for immich, openwebui / remove scrypted [@MickLesk](https://github.com/MickLesk) ([#4927](https://github.com/community-scripts/ProxmoxVE/pull/4927))
    - [core] tools.func: Bugfix old gpg key for mysql & little improvements [@MickLesk](https://github.com/MickLesk) ([#4916](https://github.com/community-scripts/ProxmoxVE/pull/4916))
    - [core] Varius fixes to Config file feature [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4924](https://github.com/community-scripts/ProxmoxVE/pull/4924))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - Display default password even if there isn't a default username [@0risc](https://github.com/0risc) ([#4900](https://github.com/community-scripts/ProxmoxVE/pull/4900))

## 2025-06-01

### 🆕 New Scripts

  - immich ([#4886](https://github.com/community-scripts/ProxmoxVE/pull/4886))

### 🌐 Website

  - #### 📝 Script Information

    - AdventureLog: add login credentials info [@tremor021](https://github.com/tremor021) ([#4887](https://github.com/community-scripts/ProxmoxVE/pull/4887))

## 2025-05-31

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Silverbullet: Fix Installation (wrong path) [@MickLesk](https://github.com/MickLesk) ([#4873](https://github.com/community-scripts/ProxmoxVE/pull/4873))
    - ActualBudget: fix update check (file instead of folder check) [@MickLesk](https://github.com/MickLesk) ([#4874](https://github.com/community-scripts/ProxmoxVE/pull/4874))
    - Omada Controller: Fix libssl url [@tremor021](https://github.com/tremor021) ([#4868](https://github.com/community-scripts/ProxmoxVE/pull/4868))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - Revert "Update package dependencies in package.json and package-lock.json (#4845) [@BramSuurdje](https://github.com/BramSuurdje) ([#4869](https://github.com/community-scripts/ProxmoxVE/pull/4869))

### 💥 Breaking Changes

  - Remove Authentik script [@tremor021](https://github.com/tremor021) ([#4867](https://github.com/community-scripts/ProxmoxVE/pull/4867))

## 2025-05-30

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - slskd: add space in sed command [@vhsdream](https://github.com/vhsdream) ([#4853](https://github.com/community-scripts/ProxmoxVE/pull/4853))
    - Alpine Traefik: Fix working directory and plugins [@tremor021](https://github.com/tremor021) ([#4838](https://github.com/community-scripts/ProxmoxVE/pull/4838))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - Update package dependencies in package.json and package-lock.json [@enough-jainil](https://github.com/enough-jainil) ([#4845](https://github.com/community-scripts/ProxmoxVE/pull/4845))

## 2025-05-29

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - SearXNG fix limiter [@CrazyWolf13](https://github.com/CrazyWolf13) ([#4834](https://github.com/community-scripts/ProxmoxVE/pull/4834))
    - Docmost: add jq before nodejs install [@MickLesk](https://github.com/MickLesk) ([#4831](https://github.com/community-scripts/ProxmoxVE/pull/4831))
    - Alpine Traefik: Fix Dashboard not beign accessible [@tremor021](https://github.com/tremor021) ([#4828](https://github.com/community-scripts/ProxmoxVE/pull/4828))
    - MySQL: Fix Wrong Command [@MickLesk](https://github.com/MickLesk) ([#4820](https://github.com/community-scripts/ProxmoxVE/pull/4820))
    - docs: fix casing of OpenWrt [@GoetzGoerisch](https://github.com/GoetzGoerisch) ([#4805](https://github.com/community-scripts/ProxmoxVE/pull/4805))

  - #### ✨ New Features

    - Docker-VM: set individual Hostname / Disk-Space formatting [@MickLesk](https://github.com/MickLesk) ([#4821](https://github.com/community-scripts/ProxmoxVE/pull/4821))

## 2025-05-28

### 🆕 New Scripts

  - Umbrel-OS [@MickLesk](https://github.com/MickLesk) ([#4788](https://github.com/community-scripts/ProxmoxVE/pull/4788))
- oauth2-proxy ([#4784](https://github.com/community-scripts/ProxmoxVE/pull/4784))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Habitica: Use Node20 [@MickLesk](https://github.com/MickLesk) ([#4796](https://github.com/community-scripts/ProxmoxVE/pull/4796))
    - Alpine-Node-RED: add service to rc [@MickLesk](https://github.com/MickLesk) ([#4783](https://github.com/community-scripts/ProxmoxVE/pull/4783))

  - #### ✨ New Features

    - Pulse: use prebuild tarball file / remove unneeded npm actions [@MickLesk](https://github.com/MickLesk) ([#4776](https://github.com/community-scripts/ProxmoxVE/pull/4776))

  - #### 💥 Breaking Changes

    - Refactor: Linkwarden + OS Upgrade [@MickLesk](https://github.com/MickLesk) ([#4756](https://github.com/community-scripts/ProxmoxVE/pull/4756))

  - #### 🔧 Refactor

    - refactor: use binary and randomize credentials in tinyauth [@steveiliop56](https://github.com/steveiliop56) ([#4632](https://github.com/community-scripts/ProxmoxVE/pull/4632))
    - MariaDB CLI Update, Go Install Helper & Minor Cleanup [@MickLesk](https://github.com/MickLesk) ([#4793](https://github.com/community-scripts/ProxmoxVE/pull/4793))
    - Refactor: Remove redundant dependencies & unify unzip usage [@MickLesk](https://github.com/MickLesk) ([#4780](https://github.com/community-scripts/ProxmoxVE/pull/4780))
    - Refactor: Remove gpg / gnupg from script base [@MickLesk](https://github.com/MickLesk) ([#4775](https://github.com/community-scripts/ProxmoxVE/pull/4775))

### 🌐 Website

  - #### 📝 Script Information

    - pulse: correct url in note [@xb00tt](https://github.com/xb00tt) ([#4809](https://github.com/community-scripts/ProxmoxVE/pull/4809))

## 2025-05-27

### 🆕 New Scripts

  - Backrest ([#4766](https://github.com/community-scripts/ProxmoxVE/pull/4766))
- Pulse ([#4728](https://github.com/community-scripts/ProxmoxVE/pull/4728))

### 🚀 Updated Scripts

  - Alpine-Vaultwarden: Increase min disk requirements to 1GB [@neyzm](https://github.com/neyzm) ([#4764](https://github.com/community-scripts/ProxmoxVE/pull/4764))

  - #### 🐞 Bug Fixes

    - lldap: fix update-check [@MickLesk](https://github.com/MickLesk) ([#4742](https://github.com/community-scripts/ProxmoxVE/pull/4742))

  - #### ✨ New Features

    - Big NodeJS Update: Use Helper Function on all Install-Scripts [@MickLesk](https://github.com/MickLesk) ([#4744](https://github.com/community-scripts/ProxmoxVE/pull/4744))

  - #### 🔧 Refactor

    - merge MariaDB to tools.func Installer [@MickLesk](https://github.com/MickLesk) ([#4753](https://github.com/community-scripts/ProxmoxVE/pull/4753))
    - merge PostgreSQL to tools.func Installer [@MickLesk](https://github.com/MickLesk) ([#4752](https://github.com/community-scripts/ProxmoxVE/pull/4752))

### 🌐 Website

  - #### 📝 Script Information

    - Increase default RAM allocation for BunkerWeb to 8192MB [@TheophileDiot](https://github.com/TheophileDiot) ([#4762](https://github.com/community-scripts/ProxmoxVE/pull/4762))

## 2025-05-26

### 🆕 New Scripts

  - Argus ([#4717](https://github.com/community-scripts/ProxmoxVE/pull/4717))
- Kasm ([#4716](https://github.com/community-scripts/ProxmoxVE/pull/4716))

### 🚀 Updated Scripts

  - Excalidraw: increase HDD to 10GB [@MickLesk](https://github.com/MickLesk) ([#4718](https://github.com/community-scripts/ProxmoxVE/pull/4718))

  - #### 🐞 Bug Fixes

    - BREAKING CHANGE: Fix PocketID for v1.0.0 [@vhsdream](https://github.com/vhsdream) ([#4711](https://github.com/community-scripts/ProxmoxVE/pull/4711))
    - InspIRCd: Fix release name in release url [@tremor021](https://github.com/tremor021) ([#4720](https://github.com/community-scripts/ProxmoxVE/pull/4720))

## 2025-05-25

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Pelican-panel: back-up database if using sqlite [@bvdberg01](https://github.com/bvdberg01) ([#4700](https://github.com/community-scripts/ProxmoxVE/pull/4700))

  - #### 🔧 Refactor

    - Pterodactyl panel read typo [@bvdberg01](https://github.com/bvdberg01) ([#4701](https://github.com/community-scripts/ProxmoxVE/pull/4701))

## 2025-05-24

## 2025-05-23

### 🚀 Updated Scripts

  - #### 🔧 Refactor

    - TYPO: Fix nexcloud to nextcloud (VM) [@Stoufiler](https://github.com/Stoufiler) ([#4670](https://github.com/community-scripts/ProxmoxVE/pull/4670))

### 🌐 Website

  - #### 📝 Script Information

    - Update Icons to selfhst/icons (FreePBX & Configarr) [@MickLesk](https://github.com/MickLesk) ([#4680](https://github.com/community-scripts/ProxmoxVE/pull/4680))

### 💥 Breaking Changes

  - Remove rtsptoweb (deprecated) [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4686](https://github.com/community-scripts/ProxmoxVE/pull/4686))

## 2025-05-22

### 🆕 New Scripts

  - FreePBX ([#4648](https://github.com/community-scripts/ProxmoxVE/pull/4648))
- cloudflare-ddns ([#4647](https://github.com/community-scripts/ProxmoxVE/pull/4647))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - slskd: fix #4649 [@vhsdream](https://github.com/vhsdream) ([#4651](https://github.com/community-scripts/ProxmoxVE/pull/4651))

  - #### ✨ New Features

    - Paperless-AI: Add RAG chat [@tremor021](https://github.com/tremor021) ([#4635](https://github.com/community-scripts/ProxmoxVE/pull/4635))

### 🧰 Maintenance

  - #### 📂 Github

    - [gh]: Feature: Header-Generation for vm | tools | addon [@MickLesk](https://github.com/MickLesk) ([#4643](https://github.com/community-scripts/ProxmoxVE/pull/4643))

### 🌐 Website

  - #### 📝 Script Information

    - Commafeed: move to Documents category [@diemade](https://github.com/diemade) ([#4665](https://github.com/community-scripts/ProxmoxVE/pull/4665))

## 2025-05-21

### 🆕 New Scripts

  - configarr ([#4620](https://github.com/community-scripts/ProxmoxVE/pull/4620))
- babybuddy ([#4619](https://github.com/community-scripts/ProxmoxVE/pull/4619))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Alpine-Node-RED: Update Service File [@MickLesk](https://github.com/MickLesk) ([#4628](https://github.com/community-scripts/ProxmoxVE/pull/4628))
    - RustDesk Server: Fix update for older installs [@tremor021](https://github.com/tremor021) ([#4612](https://github.com/community-scripts/ProxmoxVE/pull/4612))

  - #### ✨ New Features

    - Tandoor Recipes: Capture version information when installing [@jbolla](https://github.com/jbolla) ([#4633](https://github.com/community-scripts/ProxmoxVE/pull/4633))

## 2025-05-20

### 🚀 Updated Scripts

  - [tools.func]: Update fetch_and_deploy_gh_release function [@tremor021](https://github.com/tremor021) ([#4605](https://github.com/community-scripts/ProxmoxVE/pull/4605))
- [core] New Features for Config File function [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4601](https://github.com/community-scripts/ProxmoxVE/pull/4601))

### 🌐 Website

  - #### 📝 Script Information

    - Website: harmonize all Logos | use jsDelivr CDN links for icons from selfhst/icons repo [@MickLesk](https://github.com/MickLesk) ([#4603](https://github.com/community-scripts/ProxmoxVE/pull/4603))

## 2025-05-19

### 🆕 New Scripts

  - rclone ([#4579](https://github.com/community-scripts/ProxmoxVE/pull/4579))

### 🚀 Updated Scripts

  - increase ressources of Homarr (3 vCPU / 6GB RAM) [@MickLesk](https://github.com/MickLesk) ([#4583](https://github.com/community-scripts/ProxmoxVE/pull/4583))

  - #### 🐞 Bug Fixes

    - Various unrelated fixes to kimai update script [@jamezpolley](https://github.com/jamezpolley) ([#4549](https://github.com/community-scripts/ProxmoxVE/pull/4549))

  - #### ✨ New Features

    - RustDesk Server: Add WebUI [@tremor021](https://github.com/tremor021) ([#4590](https://github.com/community-scripts/ProxmoxVE/pull/4590))

## 2025-05-18

### 🚀 Updated Scripts

  - tools.func - Add function to create self-signed certificates [@tremor021](https://github.com/tremor021) ([#4562](https://github.com/community-scripts/ProxmoxVE/pull/4562))

  - #### 🐞 Bug Fixes

    - Homarr: fix the build [@CrazyWolf13](https://github.com/CrazyWolf13) ([#4569](https://github.com/community-scripts/ProxmoxVE/pull/4569))

### 🌐 Website

  - #### 📝 Script Information

    - Fix Dashy Config Path on Frontend [@CrazyWolf13](https://github.com/CrazyWolf13) ([#4570](https://github.com/community-scripts/ProxmoxVE/pull/4570))

## 2025-05-17

## 2025-05-16

### 🧰 Maintenance

  - #### 💾 Core

    - [core] Refactor Config File function [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4528](https://github.com/community-scripts/ProxmoxVE/pull/4528))
    - [core] Fix Bridge detection in Advanced Mode [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4522](https://github.com/community-scripts/ProxmoxVE/pull/4522))
    - [core] Enable SSH_KEY and SSH without password [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4523](https://github.com/community-scripts/ProxmoxVE/pull/4523))

  - #### 📂 Github

    - Updates to contributor docs/guide [@tremor021](https://github.com/tremor021) ([#4518](https://github.com/community-scripts/ProxmoxVE/pull/4518))

### 🌐 Website

  - Remove bolt.diy script [@tremor021](https://github.com/tremor021) ([#4541](https://github.com/community-scripts/ProxmoxVE/pull/4541))

## 2025-05-15

### 🆕 New Scripts

  - bitmagnet ([#4493](https://github.com/community-scripts/ProxmoxVE/pull/4493))

### 🚀 Updated Scripts

  - core: Add TAB3 formatting var to core [@tremor021](https://github.com/tremor021) ([#4496](https://github.com/community-scripts/ProxmoxVE/pull/4496))
- Update scripts that use "read -p" to properly indent text [@tremor021](https://github.com/tremor021) ([#4498](https://github.com/community-scripts/ProxmoxVE/pull/4498))

  - #### ✨ New Features

    - tools.func: fix some things & add ruby default function [@MickLesk](https://github.com/MickLesk) ([#4507](https://github.com/community-scripts/ProxmoxVE/pull/4507))

### 🧰 Maintenance

  - #### 💾 Core

    - core: fix bridge detection for OVS  [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4495](https://github.com/community-scripts/ProxmoxVE/pull/4495))

## 2025-05-14

### 🆕 New Scripts

  - odoo ([#4477](https://github.com/community-scripts/ProxmoxVE/pull/4477))
- asterisk ([#4468](https://github.com/community-scripts/ProxmoxVE/pull/4468))

### 🚀 Updated Scripts

  - fix: fetch_release_and_deploy function [@CrazyWolf13](https://github.com/CrazyWolf13) ([#4478](https://github.com/community-scripts/ProxmoxVE/pull/4478))
- Website: re-add documenso & some little bugfixes [@MickLesk](https://github.com/MickLesk) ([#4456](https://github.com/community-scripts/ProxmoxVE/pull/4456))

  - #### 🐞 Bug Fixes

    - Add make installation dependency to Actual Budget script [@maciejmatczak](https://github.com/maciejmatczak) ([#4485](https://github.com/community-scripts/ProxmoxVE/pull/4485))
    - Bookstack: fix copy of themes/uploads/storage [@MickLesk](https://github.com/MickLesk) ([#4457](https://github.com/community-scripts/ProxmoxVE/pull/4457))
    - Alpine-Rclone: Fix location of passwords file [@tremor021](https://github.com/tremor021) ([#4465](https://github.com/community-scripts/ProxmoxVE/pull/4465))

  - #### ✨ New Features

    - monitor-all: improvements - tag based filtering [@grizmin](https://github.com/grizmin) ([#4437](https://github.com/community-scripts/ProxmoxVE/pull/4437))

### 🧰 Maintenance

  - #### 📂 Github

    - Add Github app for auto PR merge [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4461](https://github.com/community-scripts/ProxmoxVE/pull/4461))

## 2025-05-13

### 🆕 New Scripts

  - gatus ([#4443](https://github.com/community-scripts/ProxmoxVE/pull/4443))
- alpine-gatus ([#4442](https://github.com/community-scripts/ProxmoxVE/pull/4442))

### 🚀 Updated Scripts

  - update some improvements from dev (tools.func) [@MickLesk](https://github.com/MickLesk) ([#4430](https://github.com/community-scripts/ProxmoxVE/pull/4430))

  - #### 🐞 Bug Fixes

    - openhab: use zulu17-jdk [@moodyblue](https://github.com/moodyblue) ([#4438](https://github.com/community-scripts/ProxmoxVE/pull/4438))

  - #### 🔧 Refactor

    - openhab. correct some typos [@moodyblue](https://github.com/moodyblue) ([#4448](https://github.com/community-scripts/ProxmoxVE/pull/4448))

### 🧰 Maintenance

  - #### 💾 Core

    - fix: improve bridge detection in all network interface configuration files [@filippolauria](https://github.com/filippolauria) ([#4413](https://github.com/community-scripts/ProxmoxVE/pull/4413))

### 🌐 Website

  - #### 📝 Script Information

    - Jellyfin Media Server: Update configuration path [@tremor021](https://github.com/tremor021) ([#4434](https://github.com/community-scripts/ProxmoxVE/pull/4434))
    - Pingvin Share: Added explanation on how to add/edit environment variables [@tremor021](https://github.com/tremor021) ([#4432](https://github.com/community-scripts/ProxmoxVE/pull/4432))
    - pingvin.json: fix typo [@warmbo](https://github.com/warmbo) ([#4426](https://github.com/community-scripts/ProxmoxVE/pull/4426))

## 2025-05-12

### 🆕 New Scripts

  - Alpine-Traefik [@MickLesk](https://github.com/MickLesk) ([#4412](https://github.com/community-scripts/ProxmoxVE/pull/4412))

### 🚀 Updated Scripts

  - Alpine: Use onliner for updates [@tremor021](https://github.com/tremor021) ([#4414](https://github.com/community-scripts/ProxmoxVE/pull/4414))

  - #### 🐞 Bug Fixes

    - homarr: fetch versions dynamically from source repo [@CrazyWolf13](https://github.com/CrazyWolf13) ([#4409](https://github.com/community-scripts/ProxmoxVE/pull/4409))

  - #### ✨ New Features

    - Feature: LXC-Delete (pve helper): add "all items" [@MickLesk](https://github.com/MickLesk) ([#4296](https://github.com/community-scripts/ProxmoxVE/pull/4296))

### 🧰 Maintenance

  - #### 💾 Core

    - Config file Function in build.func [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4411](https://github.com/community-scripts/ProxmoxVE/pull/4411))

### 🌐 Website

  - #### 📝 Script Information

    - Navidrome - Fix config path (use /etc/ instead of /var/lib) [@quake1508](https://github.com/quake1508) ([#4406](https://github.com/community-scripts/ProxmoxVE/pull/4406))

## 2025-05-11

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Zammad: Enable ElasticSearch service [@tremor021](https://github.com/tremor021) ([#4391](https://github.com/community-scripts/ProxmoxVE/pull/4391))

## 2025-05-10

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - (fix) Documenso: fix build failures [@vhsdream](https://github.com/vhsdream) ([#4382](https://github.com/community-scripts/ProxmoxVE/pull/4382))
    - Jellyseerr: better handling of node and pnpm [@MickLesk](https://github.com/MickLesk) ([#4365](https://github.com/community-scripts/ProxmoxVE/pull/4365))

## 2025-05-09

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Authentik: change install to UV & increase resources to 10GB RAM [@MickLesk](https://github.com/MickLesk) ([#4364](https://github.com/community-scripts/ProxmoxVE/pull/4364))

  - #### ✨ New Features

    - HomeAssistant-Core: update script for 2025.5+ [@MickLesk](https://github.com/MickLesk) ([#4363](https://github.com/community-scripts/ProxmoxVE/pull/4363))
    - Feature: autologin for Alpine [@MickLesk](https://github.com/MickLesk) ([#4344](https://github.com/community-scripts/ProxmoxVE/pull/4344))

### 🧰 Maintenance

  - #### 💾 Core

    - fix: detect all bridge types, not just vmbr prefix [@filippolauria](https://github.com/filippolauria) ([#4351](https://github.com/community-scripts/ProxmoxVE/pull/4351))

  - #### 📂 Github

    - Add a Repo check to all Workflows [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4339](https://github.com/community-scripts/ProxmoxVE/pull/4339))
    - Auto-Merge Automatic PR [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4343](https://github.com/community-scripts/ProxmoxVE/pull/4343))

## 2025-05-08

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - SearXNG: fix to resolve yaml dependency error [@Biendeo](https://github.com/Biendeo) ([#4322](https://github.com/community-scripts/ProxmoxVE/pull/4322))
    - Bugfix: Mikrotik & Pimox HAOS VM (NEXTID) [@MickLesk](https://github.com/MickLesk) ([#4313](https://github.com/community-scripts/ProxmoxVE/pull/4313))

### 🧰 Maintenance

  - #### 💾 Core

    - build.func Change the menu for Bridge Selection [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4326](https://github.com/community-scripts/ProxmoxVE/pull/4326))

### 🌐 Website

  - FAQ: Explanation "updatable" [@tremor021](https://github.com/tremor021) ([#4300](https://github.com/community-scripts/ProxmoxVE/pull/4300))

## 2025-05-07

### 🚀 Updated Scripts

  - Alpine scripts: Set minimum disk space to 0.5GB [@tremor021](https://github.com/tremor021) ([#4288](https://github.com/community-scripts/ProxmoxVE/pull/4288))

  - #### 🐞 Bug Fixes

    - SuwayomiServer: Bump Java to v21, code formating [@tremor021](https://github.com/tremor021) ([#3987](https://github.com/community-scripts/ProxmoxVE/pull/3987))

  - #### ✨ New Features

    - Feature: get correct next VMID [@MickLesk](https://github.com/MickLesk) ([#4292](https://github.com/community-scripts/ProxmoxVE/pull/4292))

### 🌐 Website

  - #### 📝 Script Information

    - OpenWebUI: Update docs link [@tremor021](https://github.com/tremor021) ([#4298](https://github.com/community-scripts/ProxmoxVE/pull/4298))

## 2025-05-06

### 🆕 New Scripts

  - alpine-transmission ([#4277](https://github.com/community-scripts/ProxmoxVE/pull/4277))
- streamlink-webui ([#4262](https://github.com/community-scripts/ProxmoxVE/pull/4262))
- Fumadocs ([#4263](https://github.com/community-scripts/ProxmoxVE/pull/4263))
- alpine-rclone ([#4265](https://github.com/community-scripts/ProxmoxVE/pull/4265))
- alpine-tinyauth ([#4264](https://github.com/community-scripts/ProxmoxVE/pull/4264))
- Re-Add: ActualBudget [@MickLesk](https://github.com/MickLesk) ([#4228](https://github.com/community-scripts/ProxmoxVE/pull/4228))

### 🧰 Maintenance

  - #### 🐞 Bug Fixes

    - whiptail menu - cancel button now exists the advanced menu [@MickLesk](https://github.com/MickLesk) ([#4259](https://github.com/community-scripts/ProxmoxVE/pull/4259))

## 2025-05-05

### 🆕 New Scripts

  - Alpine-Komodo [@MickLesk](https://github.com/MickLesk) ([#4234](https://github.com/community-scripts/ProxmoxVE/pull/4234))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Docker VM: Fix variable doublequoting [@tremor021](https://github.com/tremor021) ([#4245](https://github.com/community-scripts/ProxmoxVE/pull/4245))
    - Alpine-Vaultwarden: Fix sed and better cert generation [@tremor021](https://github.com/tremor021) ([#4232](https://github.com/community-scripts/ProxmoxVE/pull/4232))
    - Apache Guacamole: Fix Version Grepping [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4229](https://github.com/community-scripts/ProxmoxVE/pull/4229))

  - #### ✨ New Features

    - Docker-VM: Add Disk Size choice [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4241](https://github.com/community-scripts/ProxmoxVE/pull/4241))

  - #### 🔧 Refactor

    - Refactor: Komodo update logic [@MickLesk](https://github.com/MickLesk) ([#4231](https://github.com/community-scripts/ProxmoxVE/pull/4231))

### 🧰 Maintenance

  - #### 💾 Core

    - tools.func: better function handling + gs as new helper [@MickLesk](https://github.com/MickLesk) ([#4238](https://github.com/community-scripts/ProxmoxVE/pull/4238))

## 2025-05-04

### 🌐 Website

  - Code Server: Update misleading name, description and icon. [@ArmainAP](https://github.com/ArmainAP) ([#4211](https://github.com/community-scripts/ProxmoxVE/pull/4211))

## 2025-05-03

### 🚀 Updated Scripts

  - Vaultwarden: Enable HTTPS by default [@tremor021](https://github.com/tremor021) ([#4197](https://github.com/community-scripts/ProxmoxVE/pull/4197))

  - #### 🐞 Bug Fixes

    - Vaultwarden: Fix access URL [@tremor021](https://github.com/tremor021) ([#4199](https://github.com/community-scripts/ProxmoxVE/pull/4199))

### 🌐 Website

  - #### 📝 Script Information

    - SFTPGo: Switch updatable to true on website [@tremor021](https://github.com/tremor021) ([#4186](https://github.com/community-scripts/ProxmoxVE/pull/4186))

## 2025-05-02

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - NetBox: Fix typo in sed command, preventing install [@tremor021](https://github.com/tremor021) ([#4179](https://github.com/community-scripts/ProxmoxVE/pull/4179))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - Changed the random script button to be the same as all the other buttons [@BramSuurdje](https://github.com/BramSuurdje) ([#4183](https://github.com/community-scripts/ProxmoxVE/pull/4183))

  - #### 📝 Script Information

    - Habitica: correct config path [@DrDonoso](https://github.com/DrDonoso) ([#4181](https://github.com/community-scripts/ProxmoxVE/pull/4181))

## 2025-05-01

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Readeck: Fix release crawling [@tremor021](https://github.com/tremor021) ([#4172](https://github.com/community-scripts/ProxmoxVE/pull/4172))

  - #### ✨ New Features

    - homepage: Add build time var [@burgerga](https://github.com/burgerga) ([#4167](https://github.com/community-scripts/ProxmoxVE/pull/4167))

### 🌐 Website

  - Bump vite from 6.2.6 to 6.3.4 in /frontend [@dependabot[bot]](https://github.com/dependabot[bot]) ([#4159](https://github.com/community-scripts/ProxmoxVE/pull/4159))

  - #### 📝 Script Information

    - Grafana: add config path & documentation  [@JamborJan](https://github.com/JamborJan) ([#4162](https://github.com/community-scripts/ProxmoxVE/pull/4162))

## 2025-04-30

### 🚀 Updated Scripts

  - Refactor: Matterbridge [@MickLesk](https://github.com/MickLesk) ([#4148](https://github.com/community-scripts/ProxmoxVE/pull/4148))
- Refactor: Ollama & Adding to Website [@MickLesk](https://github.com/MickLesk) ([#4147](https://github.com/community-scripts/ProxmoxVE/pull/4147))

### 🌐 Website

  - #### 📝 Script Information

    - mark Caddy as updateable [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4154](https://github.com/community-scripts/ProxmoxVE/pull/4154))
    - Website: Add missing docs and config paths [@tremor021](https://github.com/tremor021) ([#4131](https://github.com/community-scripts/ProxmoxVE/pull/4131))

## 2025-04-29

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Umlautadaptarr Service File [@MickLesk](https://github.com/MickLesk) ([#4124](https://github.com/community-scripts/ProxmoxVE/pull/4124))
    - CheckMK added filter to not install beta versions [@briodan](https://github.com/briodan) ([#4118](https://github.com/community-scripts/ProxmoxVE/pull/4118))

  - #### 🔧 Refactor

    - Refactor: sabnzbd [@MickLesk](https://github.com/MickLesk) ([#4127](https://github.com/community-scripts/ProxmoxVE/pull/4127))
    - Refactor: Navidrome [@MickLesk](https://github.com/MickLesk) ([#4120](https://github.com/community-scripts/ProxmoxVE/pull/4120))

### 🧰 Maintenance

  - #### ✨ New Features

    - core: add setup_uv() function to automate installation and updating of uv [@MickLesk](https://github.com/MickLesk) ([#4129](https://github.com/community-scripts/ProxmoxVE/pull/4129))
    - core: persist /usr/local/bin via profile.d helper [@MickLesk](https://github.com/MickLesk) ([#4133](https://github.com/community-scripts/ProxmoxVE/pull/4133))

  - #### 📝 Documentation

    - SECURITY.md: add pve 8.4 as supported [@MickLesk](https://github.com/MickLesk) ([#4123](https://github.com/community-scripts/ProxmoxVE/pull/4123))

### 🌐 Website

  - #### ✨ New Features

    - Feat: Random Script picker for Website [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4090](https://github.com/community-scripts/ProxmoxVE/pull/4090))

## 2025-04-28

### 🆕 New Scripts

  - umlautadaptarr ([#4093](https://github.com/community-scripts/ProxmoxVE/pull/4093))
- documenso ([#4080](https://github.com/community-scripts/ProxmoxVE/pull/4080))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Install rsync in ct/commafeed.sh [@mzhaodev](https://github.com/mzhaodev) ([#4086](https://github.com/community-scripts/ProxmoxVE/pull/4086))
    - fstrim: cancel/no whiptail support [@PonyXplosion](https://github.com/PonyXplosion) ([#4101](https://github.com/community-scripts/ProxmoxVE/pull/4101))
    - clean-lxc.sh: cancel/no whiptail support [@PonyXplosion](https://github.com/PonyXplosion) ([#4102](https://github.com/community-scripts/ProxmoxVE/pull/4102))

  - #### ✨ New Features

    - karakeep: add cli and mcp build commands [@vhsdream](https://github.com/vhsdream) ([#4112](https://github.com/community-scripts/ProxmoxVE/pull/4112))
    - Make apt-cacher-ng a client of its own server [@pgcudahy](https://github.com/pgcudahy) ([#4092](https://github.com/community-scripts/ProxmoxVE/pull/4092))

### 🧰 Maintenance

  - #### ✨ New Features

    - Add: tools.func [@MickLesk](https://github.com/MickLesk) ([#4100](https://github.com/community-scripts/ProxmoxVE/pull/4100))

  - #### 💾 Core

    - core: remove unneeded logging [@MickLesk](https://github.com/MickLesk) ([#4103](https://github.com/community-scripts/ProxmoxVE/pull/4103))

### 🌐 Website

  - Website: Fix frontend path in footer [@tremor021](https://github.com/tremor021) ([#4108](https://github.com/community-scripts/ProxmoxVE/pull/4108))

  - #### 📝 Script Information

    - GoMFT: Move configuration info into config_path [@tremor021](https://github.com/tremor021) ([#4106](https://github.com/community-scripts/ProxmoxVE/pull/4106))

## 2025-04-27

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Re-Add DeamonSync Package [@MickLesk](https://github.com/MickLesk) ([#4079](https://github.com/community-scripts/ProxmoxVE/pull/4079))

### 🌐 Website

  - #### 📝 Script Information

    - add default configuration file location for Caddy LXC  [@aly-yvette](https://github.com/aly-yvette) ([#4074](https://github.com/community-scripts/ProxmoxVE/pull/4074))

## 2025-04-26

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Element Synapse: Fix install script cd command error [@thegeorgeliu](https://github.com/thegeorgeliu) ([#4066](https://github.com/community-scripts/ProxmoxVE/pull/4066))

## 2025-04-25

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Element Synapse: Fix update for older versions [@tremor021](https://github.com/tremor021) ([#4050](https://github.com/community-scripts/ProxmoxVE/pull/4050))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - Only show update source when app is marked updateable [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4059](https://github.com/community-scripts/ProxmoxVE/pull/4059))

  - #### 📝 Script Information

    - Filebrowser: Add Category Files & Donwloads [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4055](https://github.com/community-scripts/ProxmoxVE/pull/4055))

### 💥 Breaking Changes

  - Removal of Seafile due to recurring problems [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4058](https://github.com/community-scripts/ProxmoxVE/pull/4058))

## 2025-04-24

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Element Synapse: Fix Admin UI install and update procedure [@tremor021](https://github.com/tremor021) ([#4041](https://github.com/community-scripts/ProxmoxVE/pull/4041))
    - SLSKD: always check for soularr update [@vhsdream](https://github.com/vhsdream) ([#4012](https://github.com/community-scripts/ProxmoxVE/pull/4012))

  - #### ✨ New Features

    - Element Synapse: Add Synapse-Admin web UI to manage Matrix [@tremor021](https://github.com/tremor021) ([#4010](https://github.com/community-scripts/ProxmoxVE/pull/4010))
    - Pi-Hole: Fix Unbound update [@CrazyWolf13](https://github.com/CrazyWolf13) ([#4026](https://github.com/community-scripts/ProxmoxVE/pull/4026))

### 🌐 Website

  - #### ✨ New Features

    - Feat: Add config path to website [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4005](https://github.com/community-scripts/ProxmoxVE/pull/4005))

  - #### 📝 Script Information

    - Jellyfin: Mark as updateable [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4029](https://github.com/community-scripts/ProxmoxVE/pull/4029))
    - Prepare JSON files for new website feature [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#4004](https://github.com/community-scripts/ProxmoxVE/pull/4004))

## 2025-04-23

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Zipline: Add new ENV Variable and Change Update [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3997](https://github.com/community-scripts/ProxmoxVE/pull/3997))
    - karakeep: use nightly channel for yt-dlp [@vhsdream](https://github.com/vhsdream) ([#3992](https://github.com/community-scripts/ProxmoxVE/pull/3992))

### 🧰 Maintenance

  - #### 📂 Github

    - Fix Workflow to close discussions [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3999](https://github.com/community-scripts/ProxmoxVE/pull/3999))

## 2025-04-22

### 🆕 New Scripts

  - reactive-resume ([#3980](https://github.com/community-scripts/ProxmoxVE/pull/3980))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - wger: Fix a bug in update procedure and general code maintenance [@tremor021](https://github.com/tremor021) ([#3974](https://github.com/community-scripts/ProxmoxVE/pull/3974))

### 🧰 Maintenance

  - #### 📂 Github

    - Add workflow to close ttek Repo relatate issues [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3981](https://github.com/community-scripts/ProxmoxVE/pull/3981))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - Fix Turnkey Source Link in Button Component [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3978](https://github.com/community-scripts/ProxmoxVE/pull/3978))

  - #### 📝 Script Information

    - qBittorrent: Update web page [@tremor021](https://github.com/tremor021) ([#3969](https://github.com/community-scripts/ProxmoxVE/pull/3969))

## 2025-04-19

### 🆕 New Scripts

  - LXC Iptag [@DesertGamer](https://github.com/DesertGamer) ([#3531](https://github.com/community-scripts/ProxmoxVE/pull/3531))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - seelf: Add missing gpg dependency [@tremor021](https://github.com/tremor021) ([#3953](https://github.com/community-scripts/ProxmoxVE/pull/3953))

### 🌐 Website

  - #### 📝 Script Information

    - Tailscale: Clarify tailscale script instruction on website [@tremor021](https://github.com/tremor021) ([#3952](https://github.com/community-scripts/ProxmoxVE/pull/3952))

## 2025-04-18

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Changedetection: Increase connection timeout for older systems [@tremor021](https://github.com/tremor021) ([#3935](https://github.com/community-scripts/ProxmoxVE/pull/3935))

### 🌐 Website

  - #### 📝 Script Information

    - VaultWarden: Update json with additonal information [@uSlackr](https://github.com/uSlackr) ([#3929](https://github.com/community-scripts/ProxmoxVE/pull/3929))

## 2025-04-17

### 🚀 Updated Scripts

  - fix minor grammatical error in several scripts [@jordanpatton](https://github.com/jordanpatton) ([#3921](https://github.com/community-scripts/ProxmoxVE/pull/3921))

  - #### 🐞 Bug Fixes

    - PeaNUT: Fix tar command [@tremor021](https://github.com/tremor021) ([#3925](https://github.com/community-scripts/ProxmoxVE/pull/3925))
    - GoMFT: Fix install and update process (final time) [@tremor021](https://github.com/tremor021) ([#3922](https://github.com/community-scripts/ProxmoxVE/pull/3922))

## 2025-04-15

### 🚀 Updated Scripts

  - [core] remove unneeded vars from shellcheck [@MickLesk](https://github.com/MickLesk) ([#3899](https://github.com/community-scripts/ProxmoxVE/pull/3899))

  - #### 🐞 Bug Fixes

    - Outline: Installation and update fixes [@tremor021](https://github.com/tremor021) ([#3895](https://github.com/community-scripts/ProxmoxVE/pull/3895))
    - SABnzbd: Fix update error caused by externaly managed message [@tremor021](https://github.com/tremor021) ([#3892](https://github.com/community-scripts/ProxmoxVE/pull/3892))

### 🧰 Maintenance

  - #### 📡 API

    - Bump golang.org/x/crypto from 0.32.0 to 0.35.0 in /api [@dependabot[bot]](https://github.com/dependabot[bot]) ([#3887](https://github.com/community-scripts/ProxmoxVE/pull/3887))

  - #### 📂 Github

    - shrink & minimalize report templates [@MickLesk](https://github.com/MickLesk) ([#3902](https://github.com/community-scripts/ProxmoxVE/pull/3902))

## 2025-04-14

### 🆕 New Scripts

  - openziti-controller ([#3880](https://github.com/community-scripts/ProxmoxVE/pull/3880))
- Alpine-AdGuardHome [@MickLesk](https://github.com/MickLesk) ([#3875](https://github.com/community-scripts/ProxmoxVE/pull/3875))

### 🚀 Updated Scripts

  - Paymenter: bump php to 8.3 [@opastorello](https://github.com/opastorello) ([#3825](https://github.com/community-scripts/ProxmoxVE/pull/3825))

  - #### 🐞 Bug Fixes

    - Neo4j: Add Java dependency [@tremor021](https://github.com/tremor021) ([#3871](https://github.com/community-scripts/ProxmoxVE/pull/3871))

  - #### 🔧 Refactor

    - Refactor Cockpit update_script part [@MickLesk](https://github.com/MickLesk) ([#3878](https://github.com/community-scripts/ProxmoxVE/pull/3878))

## 2025-04-12

### 🌐 Website

  - #### ✨ New Features

    - Add "Not Updateable" tooltip to scripts [@BramSuurdje](https://github.com/BramSuurdje) ([#3852](https://github.com/community-scripts/ProxmoxVE/pull/3852))

## 2025-04-11

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - slskd: fix missing -o for curl [@MickLesk](https://github.com/MickLesk) ([#3828](https://github.com/community-scripts/ProxmoxVE/pull/3828))
    - 2FAuth: Fix php dependencies [@tremor021](https://github.com/tremor021) ([#3820](https://github.com/community-scripts/ProxmoxVE/pull/3820))
    - Komodo: Update Repository link [@sendyputra](https://github.com/sendyputra) ([#3823](https://github.com/community-scripts/ProxmoxVE/pull/3823))

### 🧰 Maintenance

  - #### 💾 Core

    - Enlarge the size of the menu in build.func [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3833](https://github.com/community-scripts/ProxmoxVE/pull/3833))

### 🌐 Website

  - Bump vite from 6.2.5 to 6.2.6 in /frontend [@dependabot[bot]](https://github.com/dependabot[bot]) ([#3842](https://github.com/community-scripts/ProxmoxVE/pull/3842))

  - #### 📝 Script Information

    - SQLServer: fix some typos in notes [@stiny861](https://github.com/stiny861) ([#3838](https://github.com/community-scripts/ProxmoxVE/pull/3838))
    - Radicale: move to misc category [@tremor021](https://github.com/tremor021) ([#3830](https://github.com/community-scripts/ProxmoxVE/pull/3830))

## 2025-04-10

### 🆕 New Scripts

  - openproject ([#3637](https://github.com/community-scripts/ProxmoxVE/pull/3637))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Fix: NodeJS Check (Tianji/Docmost) [@MickLesk](https://github.com/MickLesk) ([#3813](https://github.com/community-scripts/ProxmoxVE/pull/3813))

  - #### ✨ New Features

    - change var in ct files to new standard [@MickLesk](https://github.com/MickLesk) ([#3804](https://github.com/community-scripts/ProxmoxVE/pull/3804))

### 🧰 Maintenance

  - #### 💾 Core

    - New Feature: Config File [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3808](https://github.com/community-scripts/ProxmoxVE/pull/3808))

### 💥 Breaking Changes

  - Remove Actualbudget [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3801](https://github.com/community-scripts/ProxmoxVE/pull/3801))

## 2025-04-09

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Paperless-NGX: Extend Granian Service Env [@MickLesk](https://github.com/MickLesk) ([#3790](https://github.com/community-scripts/ProxmoxVE/pull/3790))
    - Paperless-NGX: remove gunicorn, use python3 for webserver [@MickLesk](https://github.com/MickLesk) ([#3785](https://github.com/community-scripts/ProxmoxVE/pull/3785))
    - HomeAssistantOS: allow Proxmox version 8.4 [@quentinvnk](https://github.com/quentinvnk) ([#3773](https://github.com/community-scripts/ProxmoxVE/pull/3773))
    - Tandoor: Add xmlsec as dependency [@tremor021](https://github.com/tremor021) ([#3762](https://github.com/community-scripts/ProxmoxVE/pull/3762))

  - #### 🔧 Refactor

    - harmonize pve versions check & vm vars [@MickLesk](https://github.com/MickLesk) ([#3779](https://github.com/community-scripts/ProxmoxVE/pull/3779))

### 🧰 Maintenance

  - #### 💥 Breaking Changes

    - core: Removal of OS/Version Selection from Advanced Settings [@MickLesk](https://github.com/MickLesk) ([#3771](https://github.com/community-scripts/ProxmoxVE/pull/3771))
    - core: move misc scripts to structured addon/pve paths | Refactor JSON Editor & Script Mapping [@MickLesk](https://github.com/MickLesk) ([#3765](https://github.com/community-scripts/ProxmoxVE/pull/3765))

## 2025-04-08

### 🆕 New Scripts

  - Alpine-PostgreSQL [@MickLesk](https://github.com/MickLesk) ([#3751](https://github.com/community-scripts/ProxmoxVE/pull/3751))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Alpine-Wireguard: Fix for sysctl and ip_forward [@juronja](https://github.com/juronja) ([#3744](https://github.com/community-scripts/ProxmoxVE/pull/3744))
    - TriliumNext: fix dump-db [@MickLesk](https://github.com/MickLesk) ([#3741](https://github.com/community-scripts/ProxmoxVE/pull/3741))
    - Actual: Reduce RAM to 4GB and old space to 3072MB  [@dannyellis](https://github.com/dannyellis) ([#3730](https://github.com/community-scripts/ProxmoxVE/pull/3730))

  - #### ✨ New Features

    - Alpine-MariaDB: better handling of adminer installation [@MickLesk](https://github.com/MickLesk) ([#3739](https://github.com/community-scripts/ProxmoxVE/pull/3739))
    - Paperless-GPT: Add logging to service file [@tremor021](https://github.com/tremor021) ([#3738](https://github.com/community-scripts/ProxmoxVE/pull/3738))

### 🌐 Website

  - #### 📝 Script Information

    - Meilisearch: Fix Typo [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3749](https://github.com/community-scripts/ProxmoxVE/pull/3749))

## 2025-04-07

### 🆕 New Scripts

  - Breaking: Hoarder > Karakeep [@MickLesk](https://github.com/MickLesk) ([#3699](https://github.com/community-scripts/ProxmoxVE/pull/3699))

### 🚀 Updated Scripts

  - Actual: Increase RAM and add heap-space var for nodejs [@MickLesk](https://github.com/MickLesk) ([#3713](https://github.com/community-scripts/ProxmoxVE/pull/3713))

  - #### 🐞 Bug Fixes

    - Alpine-MariaDB: Fix Install Service startup [@MickLesk](https://github.com/MickLesk) ([#3701](https://github.com/community-scripts/ProxmoxVE/pull/3701))
    - Zitadel: Fix release tarball crawling [@tremor021](https://github.com/tremor021) ([#3716](https://github.com/community-scripts/ProxmoxVE/pull/3716))

  - #### ✨ New Features

    - Kimai: bump php to 8.4 [@MickLesk](https://github.com/MickLesk) ([#3724](https://github.com/community-scripts/ProxmoxVE/pull/3724))

  - #### 🔧 Refactor

    - Refactor: Zabbix, get always latest version [@MickLesk](https://github.com/MickLesk) ([#3720](https://github.com/community-scripts/ProxmoxVE/pull/3720))

### 🌐 Website

  - #### 📝 Script Information

    - Changed the category of Channels DVR and NextPVR [@johnsturgeon](https://github.com/johnsturgeon) ([#3729](https://github.com/community-scripts/ProxmoxVE/pull/3729))

## 2025-04-06

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Actual: Add git dependency & change yarn commands [@MickLesk](https://github.com/MickLesk) ([#3703](https://github.com/community-scripts/ProxmoxVE/pull/3703))
    - Pelican-Panel: Fix PHP 8.4 Repository [@MickLesk](https://github.com/MickLesk) ([#3700](https://github.com/community-scripts/ProxmoxVE/pull/3700))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - Implement FAQ component and integrate it into the main page [@BramSuurdje](https://github.com/BramSuurdje) ([#3709](https://github.com/community-scripts/ProxmoxVE/pull/3709))

## 2025-04-05

### 🌐 Website

  - Bump vite from 6.2.4 to 6.2.5 in /frontend [@dependabot[bot]](https://github.com/dependabot[bot]) ([#3668](https://github.com/community-scripts/ProxmoxVE/pull/3668))

## 2025-04-04

### 🆕 New Scripts

  - meilisearch [@MickLesk](https://github.com/MickLesk) ([#3638](https://github.com/community-scripts/ProxmoxVE/pull/3638))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Pelican Panel: Bump php to 8.4 [@bvdberg01](https://github.com/bvdberg01) ([#3669](https://github.com/community-scripts/ProxmoxVE/pull/3669))
    - Pterodactyl: Bump php to 8.4 [@MickLesk](https://github.com/MickLesk) ([#3655](https://github.com/community-scripts/ProxmoxVE/pull/3655))

  - #### ✨ New Features

    - Caddy: add git for xcaddy [@MickLesk](https://github.com/MickLesk) ([#3657](https://github.com/community-scripts/ProxmoxVE/pull/3657))

### 🧰 Maintenance

  - #### 💾 Core

    - core: fix raw path  [@MickLesk](https://github.com/MickLesk) ([#3656](https://github.com/community-scripts/ProxmoxVE/pull/3656))

## 2025-04-03

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Prowlarr: Fix Typo in URL (update_function) [@ribera96](https://github.com/ribera96) ([#3640](https://github.com/community-scripts/ProxmoxVE/pull/3640))
    - Prowlarr: Fix typo in release URL [@tremor021](https://github.com/tremor021) ([#3636](https://github.com/community-scripts/ProxmoxVE/pull/3636))
    - GoMFT: Fix the node_modules deletion command [@tremor021](https://github.com/tremor021) ([#3624](https://github.com/community-scripts/ProxmoxVE/pull/3624))
    - BookStack: Fix path to downloaded release file [@tremor021](https://github.com/tremor021) ([#3627](https://github.com/community-scripts/ProxmoxVE/pull/3627))

  - #### ✨ New Features

    - VM: show progress bar while downloading [@MickLesk](https://github.com/MickLesk) ([#3634](https://github.com/community-scripts/ProxmoxVE/pull/3634))
    - *Arr: Move Arr apps to github release crawling and provide update functionality [@tremor021](https://github.com/tremor021) ([#3625](https://github.com/community-scripts/ProxmoxVE/pull/3625))

### 🧰 Maintenance

  - #### 📂 Github

    - Correct URL in contributing docs [@verbumfeit](https://github.com/verbumfeit) ([#3648](https://github.com/community-scripts/ProxmoxVE/pull/3648))

### 🌐 Website

  - Bump next from 15.2.3 to 15.2.4 in /frontend [@dependabot[bot]](https://github.com/dependabot[bot]) ([#3628](https://github.com/community-scripts/ProxmoxVE/pull/3628))

  - #### 📝 Script Information

    - slskd: fix typo for config note [@MickLesk](https://github.com/MickLesk) ([#3633](https://github.com/community-scripts/ProxmoxVE/pull/3633))

## 2025-04-02

### 🆕 New Scripts

  - openziti-tunnel [@emoscardini](https://github.com/emoscardini) ([#3610](https://github.com/community-scripts/ProxmoxVE/pull/3610))
- Alpine-Wireguard [@MickLesk](https://github.com/MickLesk) ([#3611](https://github.com/community-scripts/ProxmoxVE/pull/3611))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Authelia: fix incorrect rights for email.txt [@MickLesk](https://github.com/MickLesk) ([#3612](https://github.com/community-scripts/ProxmoxVE/pull/3612))
    - Photoprism: harmonize curl  [@MickLesk](https://github.com/MickLesk) ([#3601](https://github.com/community-scripts/ProxmoxVE/pull/3601))
    - Fix link in clean-lxcs.sh [@thalatamsainath](https://github.com/thalatamsainath) ([#3593](https://github.com/community-scripts/ProxmoxVE/pull/3593))
    - Fileflows: Add ImageMagick dependecy [@tremor021](https://github.com/tremor021) ([#3589](https://github.com/community-scripts/ProxmoxVE/pull/3589))
    - General fixes for several scripts [@tremor021](https://github.com/tremor021) ([#3587](https://github.com/community-scripts/ProxmoxVE/pull/3587))

### 🧰 Maintenance

  - #### 💾 Core

    - UI-Fix: verbose without useless space in header [@MickLesk](https://github.com/MickLesk) ([#3598](https://github.com/community-scripts/ProxmoxVE/pull/3598))

## 2025-04-01

### 🆕 New Scripts

  - Alpine Prometheus [@MickLesk](https://github.com/MickLesk) ([#3547](https://github.com/community-scripts/ProxmoxVE/pull/3547))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Flaresolverr: Fix curl command [@tremor021](https://github.com/tremor021) ([#3583](https://github.com/community-scripts/ProxmoxVE/pull/3583))
    - Authentik - Fix YQ_LATEST regex [@ceres-c](https://github.com/ceres-c) ([#3565](https://github.com/community-scripts/ProxmoxVE/pull/3565))
    - Fileflows: Fix update dependencies [@tremor021](https://github.com/tremor021) ([#3577](https://github.com/community-scripts/ProxmoxVE/pull/3577))
    - CheckMK: Increase Disk size [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3559](https://github.com/community-scripts/ProxmoxVE/pull/3559))
    - switch arr lxc's (lidarr,-prowlarr,-radarr,-readarr,-whisparr) to curl -fsSL [@MickLesk](https://github.com/MickLesk) ([#3554](https://github.com/community-scripts/ProxmoxVE/pull/3554))

  - #### 💥 Breaking Changes

    - Replace wget with curl -fsSL, normalize downloads, and prep for IPv6 [@MickLesk](https://github.com/MickLesk) ([#3455](https://github.com/community-scripts/ProxmoxVE/pull/3455))

  - #### 🔧 Refactor

    - Fixes and standard enforcement [@tremor021](https://github.com/tremor021) ([#3564](https://github.com/community-scripts/ProxmoxVE/pull/3564))

### 🌐 Website

  - Update metadata inside layout.tsx for better SEO [@BramSuurdje](https://github.com/BramSuurdje) ([#3570](https://github.com/community-scripts/ProxmoxVE/pull/3570))
- Bump vite from 5.4.14 to 5.4.16 in /frontend [@dependabot[bot]](https://github.com/dependabot[bot]) ([#3549](https://github.com/community-scripts/ProxmoxVE/pull/3549))

  - #### ✨ New Features

    - Refactor ScriptItem and Buttons components to enhance layout and integrate dropdown for links. Update InterFaces component for improved styling and structure. [@BramSuurdje](https://github.com/BramSuurdje) ([#3567](https://github.com/community-scripts/ProxmoxVE/pull/3567))

## 2025-03-31

### 🆕 New Scripts

  - slskd [@vhsdream](https://github.com/vhsdream) ([#3516](https://github.com/community-scripts/ProxmoxVE/pull/3516))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - The Lounge: Fix sqlite3 failing to build [@tremor021](https://github.com/tremor021) ([#3542](https://github.com/community-scripts/ProxmoxVE/pull/3542))
    - 2FAuth: Update PHP to 8.3 [@BrockHumblet](https://github.com/BrockHumblet) ([#3510](https://github.com/community-scripts/ProxmoxVE/pull/3510))
    - GoMFT: Update Curl Path [@MickLesk](https://github.com/MickLesk) ([#3537](https://github.com/community-scripts/ProxmoxVE/pull/3537))
    - slskd: fix broken curl for soularr [@MickLesk](https://github.com/MickLesk) ([#3533](https://github.com/community-scripts/ProxmoxVE/pull/3533))
    - Docmost: Bump NodeJS to 22 & fixed pnpm [@MickLesk](https://github.com/MickLesk) ([#3521](https://github.com/community-scripts/ProxmoxVE/pull/3521))
    - Tianji: Bump NodeJS to V22 [@MickLesk](https://github.com/MickLesk) ([#3519](https://github.com/community-scripts/ProxmoxVE/pull/3519))

  - #### ✨ New Features

    - NPMPlus: update function & better create handling (user/password) [@MickLesk](https://github.com/MickLesk) ([#3520](https://github.com/community-scripts/ProxmoxVE/pull/3520))

  - #### 🔧 Refactor

    - Remove old `.jar` versions of Stirling-PDF [@JcMinarro](https://github.com/JcMinarro) ([#3512](https://github.com/community-scripts/ProxmoxVE/pull/3512))

### 🧰 Maintenance

  - #### 💾 Core

    - core: fix empty header if header in repo exist [@MickLesk](https://github.com/MickLesk) ([#3536](https://github.com/community-scripts/ProxmoxVE/pull/3536))

### 🌐 Website

  - #### ✨ New Features

    - Change Frontend Version Info [@MickLesk](https://github.com/MickLesk) ([#3527](https://github.com/community-scripts/ProxmoxVE/pull/3527))

  - #### 📝 Script Information

    - HomeAssistant (Container): Better Portainer explanation [@MickLesk](https://github.com/MickLesk) ([#3518](https://github.com/community-scripts/ProxmoxVE/pull/3518))

## 2025-03-30

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Open WebUI: Fix Ollama update logic [@tremor021](https://github.com/tremor021) ([#3506](https://github.com/community-scripts/ProxmoxVE/pull/3506))
    - GoMFT: Add frontend build procedure [@tremor021](https://github.com/tremor021) ([#3499](https://github.com/community-scripts/ProxmoxVE/pull/3499))

  - #### ✨ New Features

    - Open WebUI: Add Ollama update check [@tremor021](https://github.com/tremor021) ([#3478](https://github.com/community-scripts/ProxmoxVE/pull/3478))

## 2025-03-29

### 🆕 New Scripts

  - Alpine MariaDB [@MickLesk](https://github.com/MickLesk) ([#3456](https://github.com/community-scripts/ProxmoxVE/pull/3456))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Komodo: Fix wrong sed text [@tremor021](https://github.com/tremor021) ([#3491](https://github.com/community-scripts/ProxmoxVE/pull/3491))
    - GoMFT: Fix release archive naming [@tremor021](https://github.com/tremor021) ([#3483](https://github.com/community-scripts/ProxmoxVE/pull/3483))
    - Homepage: Fix release parsing [@tremor021](https://github.com/tremor021) ([#3484](https://github.com/community-scripts/ProxmoxVE/pull/3484))
    - Netdata: Fix debian-keyring dependency missing [@tremor021](https://github.com/tremor021) ([#3477](https://github.com/community-scripts/ProxmoxVE/pull/3477))
    - ErsatzTV: Fix temp file reference [@tremor021](https://github.com/tremor021) ([#3476](https://github.com/community-scripts/ProxmoxVE/pull/3476))
    - Komodo: Fix compose.env [@tremor021](https://github.com/tremor021) ([#3466](https://github.com/community-scripts/ProxmoxVE/pull/3466))

## 2025-03-28

### 🆕 New Scripts

  - Alpine Node-RED [@MickLesk](https://github.com/MickLesk) ([#3457](https://github.com/community-scripts/ProxmoxVE/pull/3457))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - GoMFT: Fix release grep [@tremor021](https://github.com/tremor021) ([#3462](https://github.com/community-scripts/ProxmoxVE/pull/3462))
    - ErsatzTV: Fix path in update function [@tremor021](https://github.com/tremor021) ([#3463](https://github.com/community-scripts/ProxmoxVE/pull/3463))

## 2025-03-27

### 🚀 Updated Scripts

  - [core]: add functions for Alpine (update / core deps) [@MickLesk](https://github.com/MickLesk) ([#3437](https://github.com/community-scripts/ProxmoxVE/pull/3437))

### 🧰 Maintenance

  - #### 💾 Core

    - [core]: Refactor Spinner/MSG Function (support now alpine / performance / handling) [@MickLesk](https://github.com/MickLesk) ([#3436](https://github.com/community-scripts/ProxmoxVE/pull/3436))

## 2025-03-26

### 🆕 New Scripts

  - Alpine: Gitea [@MickLesk](https://github.com/MickLesk) ([#3424](https://github.com/community-scripts/ProxmoxVE/pull/3424))

### 🚀 Updated Scripts

  - FlowiseAI: Fix dependencies [@tremor021](https://github.com/tremor021) ([#3427](https://github.com/community-scripts/ProxmoxVE/pull/3427))

  - #### 🐞 Bug Fixes

    - fluid-calendar: Fix failed build during updates [@vhsdream](https://github.com/vhsdream) ([#3417](https://github.com/community-scripts/ProxmoxVE/pull/3417))

### 🧰 Maintenance

  - #### 📂 Github

    - Remove coredeps in CONTRIBUTOR_AND_GUIDES [@bvdberg01](https://github.com/bvdberg01) ([#3420](https://github.com/community-scripts/ProxmoxVE/pull/3420))

## 2025-03-25

### 🧰 Maintenance

  - #### 📂 Github

    - Discord invite link updated [@MickLesk](https://github.com/MickLesk) ([#3412](https://github.com/community-scripts/ProxmoxVE/pull/3412))

## 2025-03-24

### 🆕 New Scripts

  - fileflows [@kkroboth](https://github.com/kkroboth) ([#3392](https://github.com/community-scripts/ProxmoxVE/pull/3392))
- wazuh [@omiinaya](https://github.com/omiinaya) ([#3381](https://github.com/community-scripts/ProxmoxVE/pull/3381))
- yt-dlp-webui [@CrazyWolf13](https://github.com/CrazyWolf13) ([#3364](https://github.com/community-scripts/ProxmoxVE/pull/3364))
- Extension/New Script: Redis Alpine Installation [@MickLesk](https://github.com/MickLesk) ([#3367](https://github.com/community-scripts/ProxmoxVE/pull/3367))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Extend HOME Env for Kubo [@MickLesk](https://github.com/MickLesk) ([#3397](https://github.com/community-scripts/ProxmoxVE/pull/3397))

  - #### ✨ New Features

    - [core] Rebase Scripts (formatting, highlighting & remove old deps) [@MickLesk](https://github.com/MickLesk) ([#3378](https://github.com/community-scripts/ProxmoxVE/pull/3378))

  - #### 🔧 Refactor

    - qBittorrent: Switch to static builds for faster updating/upgrading [@tremor021](https://github.com/tremor021) ([#3405](https://github.com/community-scripts/ProxmoxVE/pull/3405))
    - Refactor: ErsatzTV Script [@MickLesk](https://github.com/MickLesk) ([#3365](https://github.com/community-scripts/ProxmoxVE/pull/3365))

### 🧰 Maintenance

  - #### ✨ New Features

    - [core] install core deps (debian / ubuntu) [@MickLesk](https://github.com/MickLesk) ([#3366](https://github.com/community-scripts/ProxmoxVE/pull/3366))

  - #### 💾 Core

    - [core] extend hardware transcoding for fileflows #3392 [@MickLesk](https://github.com/MickLesk) ([#3396](https://github.com/community-scripts/ProxmoxVE/pull/3396))

  - #### 📂 Github

    - Refactor Changelog Workflow [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3371](https://github.com/community-scripts/ProxmoxVE/pull/3371))

### 🌐 Website

  - Update siteConfig.tsx to use new analytics code [@BramSuurdje](https://github.com/BramSuurdje) ([#3389](https://github.com/community-scripts/ProxmoxVE/pull/3389))

  - #### 🐞 Bug Fixes

    - Better Text for Version Date [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3388](https://github.com/community-scripts/ProxmoxVE/pull/3388))

## 2025-03-23

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - GoMFT: Check if build-essential is present before updating, if not then install it [@tremor021](https://github.com/tremor021) ([#3358](https://github.com/community-scripts/ProxmoxVE/pull/3358))

## 2025-03-22

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - revealjs: Fix update process [@tremor021](https://github.com/tremor021) ([#3341](https://github.com/community-scripts/ProxmoxVE/pull/3341))
    - Cronicle: add missing gnupg package [@MickLesk](https://github.com/MickLesk) ([#3323](https://github.com/community-scripts/ProxmoxVE/pull/3323))

  - #### ✨ New Features

    - Update nextcloud-vm.sh to 18.1 ISO [@0xN0BADC0FF33](https://github.com/0xN0BADC0FF33) ([#3333](https://github.com/community-scripts/ProxmoxVE/pull/3333))

## 2025-03-21

### 🚀 Updated Scripts

  - Omada jdk to jre [@bvdberg01](https://github.com/bvdberg01) ([#3319](https://github.com/community-scripts/ProxmoxVE/pull/3319))

  - #### 🐞 Bug Fixes

    - Omada zulu 8 to 21 [@bvdberg01](https://github.com/bvdberg01) ([#3318](https://github.com/community-scripts/ProxmoxVE/pull/3318))
    - MySQL: Correctly add repo to mysql.list [@tremor021](https://github.com/tremor021) ([#3315](https://github.com/community-scripts/ProxmoxVE/pull/3315))
    - GoMFT: Fix build dependencies [@tremor021](https://github.com/tremor021) ([#3313](https://github.com/community-scripts/ProxmoxVE/pull/3313))
    - GoMFT: Don't rely on binaries from github [@tremor021](https://github.com/tremor021) ([#3303](https://github.com/community-scripts/ProxmoxVE/pull/3303))

### 🧰 Maintenance

  - #### 💾 Core

    - Clarify MTU in advanced Settings. [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3296](https://github.com/community-scripts/ProxmoxVE/pull/3296))

### 🌐 Website

  - Bump next from 15.1.3 to 15.2.3 in /frontend [@dependabot[bot]](https://github.com/dependabot[bot]) ([#3316](https://github.com/community-scripts/ProxmoxVE/pull/3316))

  - #### 📝 Script Information

    - Proxmox, rather than Promox [@gringocl](https://github.com/gringocl) ([#3293](https://github.com/community-scripts/ProxmoxVE/pull/3293))
    - Audiobookshelf: Fix category on website [@jaykup26](https://github.com/jaykup26) ([#3304](https://github.com/community-scripts/ProxmoxVE/pull/3304))
    - Threadfin: add port for website [@MickLesk](https://github.com/MickLesk) ([#3295](https://github.com/community-scripts/ProxmoxVE/pull/3295))

## 2025-03-20

### 🚀 Updated Scripts

  - #### ✨ New Features

    - Netdata: Update to newer deb File [@MickLesk](https://github.com/MickLesk) ([#3276](https://github.com/community-scripts/ProxmoxVE/pull/3276))

### 🧰 Maintenance

  - #### ✨ New Features

    - [core] add gitignore to prevent big pulls [@MickLesk](https://github.com/MickLesk) ([#3278](https://github.com/community-scripts/ProxmoxVE/pull/3278))

## 2025-03-19

### 🚀 Updated Scripts

  - License url VED to VE [@bvdberg01](https://github.com/bvdberg01) ([#3258](https://github.com/community-scripts/ProxmoxVE/pull/3258))

  - #### 🐞 Bug Fixes

    - Snipe-IT: Remove composer update & add no interaction for install [@MickLesk](https://github.com/MickLesk) ([#3256](https://github.com/community-scripts/ProxmoxVE/pull/3256))
    - Fluid-Calendar: Remove unneeded $STD in update [@MickLesk](https://github.com/MickLesk) ([#3250](https://github.com/community-scripts/ProxmoxVE/pull/3250))

  - #### 💥 Breaking Changes

    - FluidCalendar: Switch to safer DB operations [@vhsdream](https://github.com/vhsdream) ([#3270](https://github.com/community-scripts/ProxmoxVE/pull/3270))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - JSON editor note fix [@bvdberg01](https://github.com/bvdberg01) ([#3260](https://github.com/community-scripts/ProxmoxVE/pull/3260))

## 2025-03-18

### 🆕 New Scripts

  - CryptPad [@MickLesk](https://github.com/MickLesk) ([#3205](https://github.com/community-scripts/ProxmoxVE/pull/3205))
- GoMFT [@tremor021](https://github.com/tremor021) ([#3157](https://github.com/community-scripts/ProxmoxVE/pull/3157))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Update omada download url [@bvdberg01](https://github.com/bvdberg01) ([#3245](https://github.com/community-scripts/ProxmoxVE/pull/3245))
    - Wikijs: Remove Dev Message & Performance-Boost [@bvdberg01](https://github.com/bvdberg01) ([#3232](https://github.com/community-scripts/ProxmoxVE/pull/3232))
    - Fix openwebui update script when backup directory already exists [@chrisdoc](https://github.com/chrisdoc) ([#3213](https://github.com/community-scripts/ProxmoxVE/pull/3213))

  - #### 💥 Breaking Changes

    - Tandoor: Extend needed dependencies (Read for Update-Functionality)  [@MickLesk](https://github.com/MickLesk) ([#3207](https://github.com/community-scripts/ProxmoxVE/pull/3207))

### 🧰 Maintenance

  - #### 📂 Github

    - [core] cleanup - remove old backups of workflow files [@MickLesk](https://github.com/MickLesk) ([#3247](https://github.com/community-scripts/ProxmoxVE/pull/3247))
    - Add worflow to crawl APP verisons [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3192](https://github.com/community-scripts/ProxmoxVE/pull/3192))
    - Update pr template and WF [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3200](https://github.com/community-scripts/ProxmoxVE/pull/3200))
    - Update Workflow Context [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3171](https://github.com/community-scripts/ProxmoxVE/pull/3171))
    - Change json path CONTRIBUTING.md [@bvdberg01](https://github.com/bvdberg01) ([#3187](https://github.com/community-scripts/ProxmoxVE/pull/3187))
    - Relocate the Json Files [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3184](https://github.com/community-scripts/ProxmoxVE/pull/3184))
    - Update Workflow to Close Discussion [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3185](https://github.com/community-scripts/ProxmoxVE/pull/3185))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - Move cryptpad files to right folders [@bvdberg01](https://github.com/bvdberg01) ([#3242](https://github.com/community-scripts/ProxmoxVE/pull/3242))
    - Update Frontend Version Logic [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3223](https://github.com/community-scripts/ProxmoxVE/pull/3223))

  - #### ✨ New Features

    - Add Latest Change Date to Frontend [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3231](https://github.com/community-scripts/ProxmoxVE/pull/3231))
    - Show Version Information on Frontend [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3216](https://github.com/community-scripts/ProxmoxVE/pull/3216))

  - #### 📝 Script Information

    - CrowdSec: Add debian only warning to website [@tremor021](https://github.com/tremor021) ([#3210](https://github.com/community-scripts/ProxmoxVE/pull/3210))
    - Debian VM: Update webpage with login info [@tremor021](https://github.com/tremor021) ([#3215](https://github.com/community-scripts/ProxmoxVE/pull/3215))
    - Heimdall Dashboard: Fix missing logo on website [@tremor021](https://github.com/tremor021) ([#3227](https://github.com/community-scripts/ProxmoxVE/pull/3227))
    - Seafile: lowercase slug for Install/Update-Source [@MickLesk](https://github.com/MickLesk) ([#3209](https://github.com/community-scripts/ProxmoxVE/pull/3209))
    - Website: Lowercase Zitadel-Slug [@MickLesk](https://github.com/MickLesk) ([#3222](https://github.com/community-scripts/ProxmoxVE/pull/3222))
    - VictoriaMetrics: Fix Wrong Slug [@MickLesk](https://github.com/MickLesk) ([#3225](https://github.com/community-scripts/ProxmoxVE/pull/3225))
    - Update Pimox Logo [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3233](https://github.com/community-scripts/ProxmoxVE/pull/3233))
    - [AUTOMATIC PR]Update versions.json [@community-scripts-pr-app[bot]](https://github.com/community-scripts-pr-app[bot]) ([#3201](https://github.com/community-scripts/ProxmoxVE/pull/3201))
    - GoMFT: Update Logo [@MickLesk](https://github.com/MickLesk) ([#3188](https://github.com/community-scripts/ProxmoxVE/pull/3188))

## 2025-03-17

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - TriliumNotes: Fix release handling [@tremor021](https://github.com/tremor021) ([#3160](https://github.com/community-scripts/ProxmoxVE/pull/3160))
    - TriliumNext: Fix release file name/path, preventing install and update [@tremor021](https://github.com/tremor021) ([#3152](https://github.com/community-scripts/ProxmoxVE/pull/3152))
    - qBittorrent: Accept legal notice in config file [@tremor021](https://github.com/tremor021) ([#3150](https://github.com/community-scripts/ProxmoxVE/pull/3150))
    - Tandoor: Switch Repo to new Link [@MickLesk](https://github.com/MickLesk) ([#3140](https://github.com/community-scripts/ProxmoxVE/pull/3140))
    - Fixed wrong PHP values to match default part-db size (100M) [@dMopp](https://github.com/dMopp) ([#3143](https://github.com/community-scripts/ProxmoxVE/pull/3143))
    - Kimai: Fix Permission Issue on new Timerecords [@MickLesk](https://github.com/MickLesk) ([#3136](https://github.com/community-scripts/ProxmoxVE/pull/3136))

  - #### ✨ New Features

    - InfluxDB: Add Ports as Info / Script-End [@MickLesk](https://github.com/MickLesk) ([#3141](https://github.com/community-scripts/ProxmoxVE/pull/3141))
    - ByteStash: Add option for multiple accounts and generate JWT secret [@tremor021](https://github.com/tremor021) ([#3132](https://github.com/community-scripts/ProxmoxVE/pull/3132))

### 🌐 Website

  - #### 📝 Script Information

    - Paperless-ngx: Fix example on website [@tremor021](https://github.com/tremor021) ([#3155](https://github.com/community-scripts/ProxmoxVE/pull/3155))

## 2025-03-16

### 🚀 Updated Scripts

  - Typo Enviroment > Environment [@MathijsG](https://github.com/MathijsG) ([#3115](https://github.com/community-scripts/ProxmoxVE/pull/3115))
- Paperless-ngx: Add additional information to website on how to install OCR languages [@tremor021](https://github.com/tremor021) ([#3111](https://github.com/community-scripts/ProxmoxVE/pull/3111))
- Prometheus PVE Exporter: Rightsizing RAM and Disk [@andygrunwald](https://github.com/andygrunwald) ([#3098](https://github.com/community-scripts/ProxmoxVE/pull/3098))

  - #### 🐞 Bug Fixes

    - Jellyseerr: Fix dependencies [@tremor021](https://github.com/tremor021) ([#3125](https://github.com/community-scripts/ProxmoxVE/pull/3125))
    - wger: Fix build.func path [@tremor021](https://github.com/tremor021) ([#3121](https://github.com/community-scripts/ProxmoxVE/pull/3121))
    - Filebrowser: Fix hardcoded port in Debian service file [@Xerovoxx98](https://github.com/Xerovoxx98) ([#3105](https://github.com/community-scripts/ProxmoxVE/pull/3105))

### 🌐 Website

  - #### 📝 Script Information

    - Website: Fix alpine-it-tools "undefined" Link [@CrazyWolf13](https://github.com/CrazyWolf13) ([#3110](https://github.com/community-scripts/ProxmoxVE/pull/3110))

## 2025-03-15

### 🚀 Updated Scripts

  - #### 💥 Breaking Changes

    - Homepage: Bugfix for v1.0.0 [@vhsdream](https://github.com/vhsdream) ([#3092](https://github.com/community-scripts/ProxmoxVE/pull/3092))

## 2025-03-14

### 🚀 Updated Scripts

  - Memos: Increase RAM Usage and max space [@MickLesk](https://github.com/MickLesk) ([#3072](https://github.com/community-scripts/ProxmoxVE/pull/3072))
- Seafile - Minor bug fix: domain.sh script fix [@dave-yap](https://github.com/dave-yap) ([#3046](https://github.com/community-scripts/ProxmoxVE/pull/3046))

  - #### 🐞 Bug Fixes

    - openwrt: fix typo netmask [@qzydustin](https://github.com/qzydustin) ([#3084](https://github.com/community-scripts/ProxmoxVE/pull/3084))

### 🌐 Website

  - #### 📝 Script Information

    - NPMplus: Add info about docker use. [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3085](https://github.com/community-scripts/ProxmoxVE/pull/3085))

## 2025-03-13

### 🆕 New Scripts

  - NPMplus [@MickLesk](https://github.com/MickLesk) ([#3051](https://github.com/community-scripts/ProxmoxVE/pull/3051))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - OpenWebUI check if there are stashed changes before poping [@tremor021](https://github.com/tremor021) ([#3064](https://github.com/community-scripts/ProxmoxVE/pull/3064))
    - Update Fluid Calendar for v1.2.0 [@vhsdream](https://github.com/vhsdream) ([#3053](https://github.com/community-scripts/ProxmoxVE/pull/3053))

### 🧰 Maintenance

  - #### 💾 Core

    - alpine-Install (core) add timezone (tz) check [@MickLesk](https://github.com/MickLesk) ([#3057](https://github.com/community-scripts/ProxmoxVE/pull/3057))

  - #### 📂 Github

    - New Workflow: Close Issues in DEV Repo when new Script is merged [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#3042](https://github.com/community-scripts/ProxmoxVE/pull/3042))

### 🌐 Website

  - Bump @babel/runtime from 7.26.0 to 7.26.10 in /frontend [@dependabot[bot]](https://github.com/dependabot[bot]) ([#3044](https://github.com/community-scripts/ProxmoxVE/pull/3044))

  - #### 📝 Script Information

    - Update Vaultwarden Source [@MickLesk](https://github.com/MickLesk) ([#3036](https://github.com/community-scripts/ProxmoxVE/pull/3036))
    - Website: Fix Alpine "undefined" Link [@MickLesk](https://github.com/MickLesk) ([#3048](https://github.com/community-scripts/ProxmoxVE/pull/3048))

## 2025-03-12

### 🆕 New Scripts

  - Fluid Calendar [@vhsdream](https://github.com/vhsdream) ([#2869](https://github.com/community-scripts/ProxmoxVE/pull/2869))

### 🚀 Updated Scripts

  - #### ✨ New Features

    - Feature: Filebrowser: support now alpine [@MickLesk](https://github.com/MickLesk) ([#2997](https://github.com/community-scripts/ProxmoxVE/pull/2997))

## 2025-03-11

### 🆕 New Scripts

  - Plant-it [@MickLesk](https://github.com/MickLesk) ([#3000](https://github.com/community-scripts/ProxmoxVE/pull/3000))
- Seafile [@dave-yap](https://github.com/dave-yap) ([#2987](https://github.com/community-scripts/ProxmoxVE/pull/2987))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Headscale: Re-enable Service after Update [@Cerothen](https://github.com/Cerothen) ([#3012](https://github.com/community-scripts/ProxmoxVE/pull/3012))
    - SnipeIT: Harmonize composer install to Project-Dockerfile [@MickLesk](https://github.com/MickLesk) ([#3009](https://github.com/community-scripts/ProxmoxVE/pull/3009))
    - Teddycloud: fix update function [@tremor021](https://github.com/tremor021) ([#2996](https://github.com/community-scripts/ProxmoxVE/pull/2996))

### 🧰 Maintenance

  - #### 📂 Github

    - Cleanup Old Project Files (figlet, app-header, images) [@MickLesk](https://github.com/MickLesk) ([#3004](https://github.com/community-scripts/ProxmoxVE/pull/3004))
    - Additions and amends to the CONTIRBUTOR docs [@tremor021](https://github.com/tremor021) ([#2983](https://github.com/community-scripts/ProxmoxVE/pull/2983))

### 🌐 Website

  - #### 📝 Script Information

    - Jellyseer not labeled as updateable even though update function exists [@tremor021](https://github.com/tremor021) ([#2991](https://github.com/community-scripts/ProxmoxVE/pull/2991))
    - Fix Website - Show correct wget path for alpine [@MickLesk](https://github.com/MickLesk) ([#2998](https://github.com/community-scripts/ProxmoxVE/pull/2998))

## 2025-03-10

### 🆕 New Scripts

  - Paperless-GPT [@MickLesk](https://github.com/MickLesk) ([#2965](https://github.com/community-scripts/ProxmoxVE/pull/2965))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Rework SnipeIT: Tarball & Tempfile [@MickLesk](https://github.com/MickLesk) ([#2963](https://github.com/community-scripts/ProxmoxVE/pull/2963))
    - pihole: fix path when accessing pihole using `pct enter` [@CrazyWolf13](https://github.com/CrazyWolf13) ([#2964](https://github.com/community-scripts/ProxmoxVE/pull/2964))
    - Hoarder: v0.23.0 dependency update [@vhsdream](https://github.com/vhsdream) ([#2958](https://github.com/community-scripts/ProxmoxVE/pull/2958))

### 🧰 Maintenance

  - #### 📂 Github

    - Update autolabeler.yml: Set Labels correctly [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2968](https://github.com/community-scripts/ProxmoxVE/pull/2968))

### 🌐 Website

  - Add warnings about externaly sourced scripts [@tremor021](https://github.com/tremor021) ([#2975](https://github.com/community-scripts/ProxmoxVE/pull/2975))

## 2025-03-09

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Fix wikijs update issue while backing up data [@AdelRefaat](https://github.com/AdelRefaat) ([#2950](https://github.com/community-scripts/ProxmoxVE/pull/2950))

### 🧰 Maintenance

  - #### 🐞 Bug Fixes

    - Improve Release-Action (awk function) [@MickLesk](https://github.com/MickLesk) ([#2934](https://github.com/community-scripts/ProxmoxVE/pull/2934))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - Pi-hole interface port in documentation [@la7eralus](https://github.com/la7eralus) ([#2953](https://github.com/community-scripts/ProxmoxVE/pull/2953))

## 2025-03-08

### 🌐 Website

  - #### 🐞 Bug Fixes

    - Update slug to lowercase in pf2etools.json  [@PhoenixEmik](https://github.com/PhoenixEmik) ([#2942](https://github.com/community-scripts/ProxmoxVE/pull/2942))

## 2025-03-07

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - JupyterNotebook: Fix APP Variable [@MickLesk](https://github.com/MickLesk) ([#2924](https://github.com/community-scripts/ProxmoxVE/pull/2924))

  - #### ✨ New Features

    - Beszel: restarting service after update [@C0pywriting](https://github.com/C0pywriting) ([#2915](https://github.com/community-scripts/ProxmoxVE/pull/2915))

  - #### 💥 Breaking Changes

    - ActualBudget: Update Script with new Repo [@MickLesk](https://github.com/MickLesk) ([#2907](https://github.com/community-scripts/ProxmoxVE/pull/2907))

### 🌐 Website

  - #### 📝 Script Information

    - Improve Nextcloud(pi) docu and Name to NextcloudPi [@MickLesk](https://github.com/MickLesk) ([#2930](https://github.com/community-scripts/ProxmoxVE/pull/2930))
    - fix jupyternotebook slug [@MickLesk](https://github.com/MickLesk) ([#2922](https://github.com/community-scripts/ProxmoxVE/pull/2922))
    - Improve Trilium Description and Name to TriliumNext [@MickLesk](https://github.com/MickLesk) ([#2929](https://github.com/community-scripts/ProxmoxVE/pull/2929))
    - Prowlarr icon [@bannert1337](https://github.com/bannert1337) ([#2906](https://github.com/community-scripts/ProxmoxVE/pull/2906))
    - Update Apache Tika icon to SVG [@bannert1337](https://github.com/bannert1337) ([#2904](https://github.com/community-scripts/ProxmoxVE/pull/2904))
    - Update Prometheus Alertmanager Icon [@bannert1337](https://github.com/bannert1337) ([#2905](https://github.com/community-scripts/ProxmoxVE/pull/2905))

## 2025-03-06

### 🆕 New Scripts

  - InvenTree [@tremor021](https://github.com/tremor021) ([#2890](https://github.com/community-scripts/ProxmoxVE/pull/2890))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Homarr: Optional Reboot after update [@CrazyWolf13](https://github.com/CrazyWolf13) ([#2876](https://github.com/community-scripts/ProxmoxVE/pull/2876))
    - Fix Tag "community-scripts" for ArchLinux / OPNSense [@MickLesk](https://github.com/MickLesk) ([#2875](https://github.com/community-scripts/ProxmoxVE/pull/2875))

  - #### ✨ New Features

    - Wastebin: Update Script for Version 3.0.0 [@MickLesk](https://github.com/MickLesk) ([#2885](https://github.com/community-scripts/ProxmoxVE/pull/2885))

## 2025-03-05

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Kimai: Better Handling of Updates (backup var / env / yaml) [@MickLesk](https://github.com/MickLesk) ([#2862](https://github.com/community-scripts/ProxmoxVE/pull/2862))
    - Fix NextcloudPi-Installation [@MickLesk](https://github.com/MickLesk) ([#2853](https://github.com/community-scripts/ProxmoxVE/pull/2853))

## 2025-03-04

### 🆕 New Scripts

  - Reveal.js [@tremor021](https://github.com/tremor021) ([#2806](https://github.com/community-scripts/ProxmoxVE/pull/2806))
- Apache Tomcat [@MickLesk](https://github.com/MickLesk) ([#2797](https://github.com/community-scripts/ProxmoxVE/pull/2797))
- Pterodactyl Wings [@bvdberg01](https://github.com/bvdberg01) ([#2800](https://github.com/community-scripts/ProxmoxVE/pull/2800))
- Pterodactyl Panel [@bvdberg01](https://github.com/bvdberg01) ([#2801](https://github.com/community-scripts/ProxmoxVE/pull/2801))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - reveal.js: Update function now backs up index and config [@tremor021](https://github.com/tremor021) ([#2845](https://github.com/community-scripts/ProxmoxVE/pull/2845))
    - Changedetection: Increase RAM & Disk-Space [@MickLesk](https://github.com/MickLesk) ([#2838](https://github.com/community-scripts/ProxmoxVE/pull/2838))
    - Linkwarden: Optimze RUST Installation [@MickLesk](https://github.com/MickLesk) ([#2817](https://github.com/community-scripts/ProxmoxVE/pull/2817))
    - Nginx: Fix $STD for tar [@MickLesk](https://github.com/MickLesk) ([#2813](https://github.com/community-scripts/ProxmoxVE/pull/2813))

  - #### ✨ New Features

    - Add source to install scripts and make license one line [@bvdberg01](https://github.com/bvdberg01) ([#2842](https://github.com/community-scripts/ProxmoxVE/pull/2842))

### 🧰 Maintenance

  - #### 🐞 Bug Fixes

    - Better handling of create release [@MickLesk](https://github.com/MickLesk) ([#2818](https://github.com/community-scripts/ProxmoxVE/pull/2818))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - Json file update [@bvdberg01](https://github.com/bvdberg01) ([#2824](https://github.com/community-scripts/ProxmoxVE/pull/2824))
    - Prometheus-paperless-ngx-exporter: Fix wrong Interface Port [@schneider-de-com](https://github.com/schneider-de-com) ([#2812](https://github.com/community-scripts/ProxmoxVE/pull/2812))

  - #### ✨ New Features

    - Feature: Update Icons (selfhst repo) [@bannert1337](https://github.com/bannert1337) ([#2834](https://github.com/community-scripts/ProxmoxVE/pull/2834))
    - Website: Add Mikrotik to Network too, OPNSense & OpenWRT to OS [@MickLesk](https://github.com/MickLesk) ([#2823](https://github.com/community-scripts/ProxmoxVE/pull/2823))

## 2025-03-03

### 🆕 New Scripts

  - Habitica [@tremor021](https://github.com/tremor021) ([#2779](https://github.com/community-scripts/ProxmoxVE/pull/2779))

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Zigbee2Mqtt Use fixed pnpm Version 10.4.1 [@MickLesk](https://github.com/MickLesk) ([#2805](https://github.com/community-scripts/ProxmoxVE/pull/2805))
    - Linkwarden: Fix & Update Monolith-Installation [@MickLesk](https://github.com/MickLesk) ([#2787](https://github.com/community-scripts/ProxmoxVE/pull/2787))

  - #### ✨ New Features

    - Feature: MinIO use now static port 9001 [@MickLesk](https://github.com/MickLesk) ([#2786](https://github.com/community-scripts/ProxmoxVE/pull/2786))
    - Feature Template Path for Mountings [@MickLesk](https://github.com/MickLesk) ([#2785](https://github.com/community-scripts/ProxmoxVE/pull/2785))

### 🌐 Website

  - #### ✨ New Features

    - Feature: Website - show default OS [@MickLesk](https://github.com/MickLesk) ([#2790](https://github.com/community-scripts/ProxmoxVE/pull/2790))

  - #### 📝 Script Information

    - Update zigbee2mqtt.json - make sure link is clickable [@gurtjun](https://github.com/gurtjun) ([#2802](https://github.com/community-scripts/ProxmoxVE/pull/2802))

## 2025-03-02

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Fix gpg Repo for nzbget [@flatlinebb](https://github.com/flatlinebb) ([#2774](https://github.com/community-scripts/ProxmoxVE/pull/2774))

## 2025-03-01

### 🚀 Updated Scripts

  - #### 🐞 Bug Fixes

    - Firefly III: FIx Ownership for OAuth Key [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2759](https://github.com/community-scripts/ProxmoxVE/pull/2759))
    - homarr: double restart to fix homarr migration [@CrazyWolf13](https://github.com/CrazyWolf13) ([#2757](https://github.com/community-scripts/ProxmoxVE/pull/2757))

  - #### ✨ New Features

    - ActualBudget: New Installation Script with new Repo [@MickLesk](https://github.com/MickLesk) ([#2770](https://github.com/community-scripts/ProxmoxVE/pull/2770))

  - #### 💥 Breaking Changes

    - Breaking: Remove Update Function for Actual Budget until it fixed [@MickLesk](https://github.com/MickLesk) ([#2768](https://github.com/community-scripts/ProxmoxVE/pull/2768))

### 🧰 Maintenance

  - #### 🐞 Bug Fixes

    - Remove Note on Changelog [@MickLesk](https://github.com/MickLesk) ([#2758](https://github.com/community-scripts/ProxmoxVE/pull/2758))
    - Fix Release Creation if Changelog.md to long [@MickLesk](https://github.com/MickLesk) ([#2752](https://github.com/community-scripts/ProxmoxVE/pull/2752))

## 2025-02-28

### 🧰 Maintenance

  - #### ✨ New Features

    - Shell Format Workflow [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2400](https://github.com/community-scripts/ProxmoxVE/pull/2400))

  - #### 📂 Github

    - Update all Action to new selfhosted Runner Cluster [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2739](https://github.com/community-scripts/ProxmoxVE/pull/2739))
    - Update Script Test Workflow [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2741](https://github.com/community-scripts/ProxmoxVE/pull/2741))

## 2025-02-27

### 🆕 New Scripts

  - web-check [@CrazyWolf13](https://github.com/CrazyWolf13) ([#2662](https://github.com/community-scripts/ProxmoxVE/pull/2662))
- Pelican Panel [@bvdberg01](https://github.com/bvdberg01) ([#2678](https://github.com/community-scripts/ProxmoxVE/pull/2678))
- Pelican Wings [@bvdberg01](https://github.com/bvdberg01) ([#2677](https://github.com/community-scripts/ProxmoxVE/pull/2677))
- ByteStash [@tremor021](https://github.com/tremor021) ([#2680](https://github.com/community-scripts/ProxmoxVE/pull/2680))

### 🚀 Updated Scripts

  - ByteStash: Removed sed, app supports Node v22 now [@tremor021](https://github.com/tremor021) ([#2728](https://github.com/community-scripts/ProxmoxVE/pull/2728))
- Keycloak: Update installation script [@tremor021](https://github.com/tremor021) ([#2714](https://github.com/community-scripts/ProxmoxVE/pull/2714))
- ByteStash: Fix Node 22 compatibility (thanks t2lc) [@tremor021](https://github.com/tremor021) ([#2705](https://github.com/community-scripts/ProxmoxVE/pull/2705))

  - #### 🐞 Bug Fixes

    - EOF not detected [@CrazyWolf13](https://github.com/CrazyWolf13) ([#2726](https://github.com/community-scripts/ProxmoxVE/pull/2726))
    - Zitadel-install.sh: Remove one version file and update to our standard [@bvdberg01](https://github.com/bvdberg01) ([#2710](https://github.com/community-scripts/ProxmoxVE/pull/2710))
    - Outline: Change key to hex32 [@tremor021](https://github.com/tremor021) ([#2709](https://github.com/community-scripts/ProxmoxVE/pull/2709))
    - Typo in update scripts [@bvdberg01](https://github.com/bvdberg01) ([#2707](https://github.com/community-scripts/ProxmoxVE/pull/2707))
    - SFTPGo Remove unneeded RELEASE variable [@MickLesk](https://github.com/MickLesk) ([#2683](https://github.com/community-scripts/ProxmoxVE/pull/2683))

### 🧰 Maintenance

  - #### 🐞 Bug Fixes

    - Update install.func: Change Line Number for Error message. [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2690](https://github.com/community-scripts/ProxmoxVE/pull/2690))

  - #### 📂 Github

    - New Workflow to close Script Request Discussions on PR merge [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2688](https://github.com/community-scripts/ProxmoxVE/pull/2688))
    - Improve Script-Test Workflow [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2712](https://github.com/community-scripts/ProxmoxVE/pull/2712))
    - Switch all actions to self-hosted Runners [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2711](https://github.com/community-scripts/ProxmoxVE/pull/2711))

### 🌐 Website

  - #### ✨ New Features

    - Use HTML button element for copying to clipboard [@scallaway](https://github.com/scallaway) ([#2720](https://github.com/community-scripts/ProxmoxVE/pull/2720))
    - Add basic pagination to Data Viewer [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2715](https://github.com/community-scripts/ProxmoxVE/pull/2715))

  - #### 📝 Script Information

    - wger - Add HTTPS instructions to the website [@tremor021](https://github.com/tremor021) ([#2695](https://github.com/community-scripts/ProxmoxVE/pull/2695))

## 2025-02-26

### 🆕 New Scripts

  - New Script: Outline [@tremor021](https://github.com/tremor021) ([#2653](https://github.com/community-scripts/ProxmoxVE/pull/2653))

### 🚀 Updated Scripts

  - Fix: SABnzbd - Removed few artefacts in the code preventing the update [@tremor021](https://github.com/tremor021) ([#2670](https://github.com/community-scripts/ProxmoxVE/pull/2670))

  - #### 🐞 Bug Fixes

    - Fix: Homarr - Manually correct db-migration wrong-folder [@CrazyWolf13](https://github.com/CrazyWolf13) ([#2676](https://github.com/community-scripts/ProxmoxVE/pull/2676))
    - Kimai: add local.yaml & fix path permissions [@MickLesk](https://github.com/MickLesk) ([#2646](https://github.com/community-scripts/ProxmoxVE/pull/2646))
    - PiHole: Fix Unbound sed for DNS [@MickLesk](https://github.com/MickLesk) ([#2647](https://github.com/community-scripts/ProxmoxVE/pull/2647))
    - Alpine IT-Tools fix typo "unexpected EOF while looking for matching `"' [@MickLesk](https://github.com/MickLesk) ([#2644](https://github.com/community-scripts/ProxmoxVE/pull/2644))

### 🧰 Maintenance

  - #### 📂 Github

    - [gh] Furhter Impove Changelog Workflow [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2655](https://github.com/community-scripts/ProxmoxVE/pull/2655))

### 🌐 Website

  - #### 🐞 Bug Fixes

    - Website: PocketID Change of website and documentation links [@schneider-de-com](https://github.com/schneider-de-com) ([#2643](https://github.com/community-scripts/ProxmoxVE/pull/2643))

  - #### 📝 Script Information

    - Fix: Graylog - Improve application description for website [@tremor021](https://github.com/tremor021) ([#2658](https://github.com/community-scripts/ProxmoxVE/pull/2658))

## 2025-02-25

### Changes

### ✨ New Features

- Update Tailscale: Add Tag when installation is finished [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2633](https://github.com/community-scripts/ProxmoxVE/pull/2633))

### 🚀 Updated Scripts

  #### 🐞 Bug Fixes

  - Fix Omada installer [@JcMinarro](https://github.com/JcMinarro) ([#2625](https://github.com/community-scripts/ProxmoxVE/pull/2625))

### 🌐 Website

- Update Tailscale-lxc Json: Add message for Supported OS [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2629](https://github.com/community-scripts/ProxmoxVE/pull/2629))

### 🧰 Maintenance

- [gh] Updated Changelog Workflow [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2632](https://github.com/community-scripts/ProxmoxVE/pull/2632))

## 2025-02-24

### Changes

### 🆕 New Scripts

- New Script: wger [@tremor021](https://github.com/tremor021) ([#2574](https://github.com/community-scripts/ProxmoxVE/pull/2574))
- New Script: VictoriaMetrics [@tremor021](https://github.com/tremor021) ([#2565](https://github.com/community-scripts/ProxmoxVE/pull/2565))
- New Script: Authelia [@thost96](https://github.com/thost96) ([#2060](https://github.com/community-scripts/ProxmoxVE/pull/2060))
- New Script: Jupyter Notebook [@Dave-code-creater](https://github.com/Dave-code-creater) ([#2561](https://github.com/community-scripts/ProxmoxVE/pull/2561))

### 🐞 Bug Fixes

- Fix Docmost: default upload size and saving data when updating [@bvdberg01](https://github.com/bvdberg01) ([#2598](https://github.com/community-scripts/ProxmoxVE/pull/2598))
- Fix: homarr db migration [@CrazyWolf13](https://github.com/CrazyWolf13) ([#2575](https://github.com/community-scripts/ProxmoxVE/pull/2575))
- Fix: Wireguard - Restart wgdashboard automatically after update [@LostALice](https://github.com/LostALice) ([#2587](https://github.com/community-scripts/ProxmoxVE/pull/2587))
- Fix: Authelia Unbound Variable Argon2id [@MickLesk](https://github.com/MickLesk) ([#2604](https://github.com/community-scripts/ProxmoxVE/pull/2604))
- Fix: Omada check for AVX Support and use the correct MongoDB Version [@MickLesk](https://github.com/MickLesk) ([#2600](https://github.com/community-scripts/ProxmoxVE/pull/2600))
- Fix: Update-Script Firefly III based on their docs [@MickLesk](https://github.com/MickLesk) ([#2534](https://github.com/community-scripts/ProxmoxVE/pull/2534))

### ✨ New Features

- Feature: Template-Check, Better Handling of Downloads, Better Network… [@MickLesk](https://github.com/MickLesk) ([#2592](https://github.com/community-scripts/ProxmoxVE/pull/2592))
- Feature: Possibility to perform updates in silent / verbose (+ logging) [@MickLesk](https://github.com/MickLesk) ([#2583](https://github.com/community-scripts/ProxmoxVE/pull/2583))
- Feature: Use Verbose Mode for all Scripts (removed &>/dev/null) [@MickLesk](https://github.com/MickLesk) ([#2596](https://github.com/community-scripts/ProxmoxVE/pull/2596))

### 🌐 Website

- Fix: Authelia - Make user enter their domain manually [@tremor021](https://github.com/tremor021) ([#2618](https://github.com/community-scripts/ProxmoxVE/pull/2618))
- Website: Change Info for PiHole Password [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2602](https://github.com/community-scripts/ProxmoxVE/pull/2602))
- Fix: Jupyter Json (missing logo & improve name on website) [@MickLesk](https://github.com/MickLesk) ([#2584](https://github.com/community-scripts/ProxmoxVE/pull/2584))

### 🧰 Maintenance

- [gh] Update Script Test Workflow [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2599](https://github.com/community-scripts/ProxmoxVE/pull/2599))
- [gh] Contributor-Guide: Update AppName.md & AppName.sh [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2603](https://github.com/community-scripts/ProxmoxVE/pull/2603))

## 2025-02-23

### Changes

### 🆕 New Scripts

- New Script: Hev socks5 server [@miviro](https://github.com/miviro) ([#2454](https://github.com/community-scripts/ProxmoxVE/pull/2454))
- New Script: bolt.diy [@tremor021](https://github.com/tremor021) ([#2528](https://github.com/community-scripts/ProxmoxVE/pull/2528))

### 🚀 Updated Scripts

- Fix: Wireguard - Remove setting NAT as its already in PostUp/Down [@tremor021](https://github.com/tremor021) ([#2510](https://github.com/community-scripts/ProxmoxVE/pull/2510))

### 🌐 Website

- Fix: Home Assistant Core - fixed wrong text in application description on website [@TMigue](https://github.com/TMigue) ([#2576](https://github.com/community-scripts/ProxmoxVE/pull/2576))

## 2025-02-22

### Changes

### 🌐 Website

- Fix a few broken icon links [@Snarkenfaugister](https://github.com/Snarkenfaugister) ([#2548](https://github.com/community-scripts/ProxmoxVE/pull/2548))

### 🧰 Maintenance

- Fix: URL's in CONTRIBUTING.md [@bvdberg01](https://github.com/bvdberg01) ([#2552](https://github.com/community-scripts/ProxmoxVE/pull/2552))

## 2025-02-21

### Changes

### 🚀 Updated Scripts

- Add ZFS to Podman. Now it works on ZFS! [@jaminmc](https://github.com/jaminmc) ([#2526](https://github.com/community-scripts/ProxmoxVE/pull/2526))
- Fix: Tianji - Downgrade Node [@MickLesk](https://github.com/MickLesk) ([#2530](https://github.com/community-scripts/ProxmoxVE/pull/2530))

### 🧰 Maintenance

- [gh] General Cleanup & Moving Files / Folders [@MickLesk](https://github.com/MickLesk) ([#2532](https://github.com/community-scripts/ProxmoxVE/pull/2532))

## 2025-02-20

### Changes

### 💥 Breaking Changes

- Breaking: Actual Budget Script (HTTPS / DB Migration / New Structure) - Read Description [@MickLesk](https://github.com/MickLesk) ([#2496](https://github.com/community-scripts/ProxmoxVE/pull/2496))
- Pihole & Unbound: Installation for Pihole V6 (read description) [@MickLesk](https://github.com/MickLesk) ([#2505](https://github.com/community-scripts/ProxmoxVE/pull/2505))

### ✨ New Scripts

- New Script: Dolibarr [@tremor021](https://github.com/tremor021) ([#2502](https://github.com/community-scripts/ProxmoxVE/pull/2502))

### 🚀 Updated Scripts

- Fix: Pingvin Share - Update not copying to correct directory [@tremor021](https://github.com/tremor021) ([#2521](https://github.com/community-scripts/ProxmoxVE/pull/2521))
- WikiJS: Prepare for Using PostgreSQL [@MickLesk](https://github.com/MickLesk) ([#2516](https://github.com/community-scripts/ProxmoxVE/pull/2516))

### 🧰 Maintenance

- [gh] better handling of labels [@MickLesk](https://github.com/MickLesk) ([#2517](https://github.com/community-scripts/ProxmoxVE/pull/2517))

## 2025-02-19

### Changes

### 🚀 Updated Scripts

- Fix: file replacement in Watcharr Update Script [@Clusters](https://github.com/Clusters) ([#2498](https://github.com/community-scripts/ProxmoxVE/pull/2498))
- Fix: Kometa - fixed successful setup message and added info to json [@tremor021](https://github.com/tremor021) ([#2495](https://github.com/community-scripts/ProxmoxVE/pull/2495))
- Fix: Actual Budget, add missing .env when updating [@MickLesk](https://github.com/MickLesk) ([#2494](https://github.com/community-scripts/ProxmoxVE/pull/2494))

## 2025-02-18

### Changes

### ✨ New Scripts

- New Script: Docmost [@MickLesk](https://github.com/MickLesk) ([#2472](https://github.com/community-scripts/ProxmoxVE/pull/2472))

### 🚀 Updated Scripts

- Fix: SQL Server 2022 | GPG & Install [@MickLesk](https://github.com/MickLesk) ([#2476](https://github.com/community-scripts/ProxmoxVE/pull/2476))
- Feature: PBS Bare Metal Installation - Allow Microcode [@MickLesk](https://github.com/MickLesk) ([#2477](https://github.com/community-scripts/ProxmoxVE/pull/2477))
- Fix: MagicMirror force Node version and fix backups [@tremor021](https://github.com/tremor021) ([#2468](https://github.com/community-scripts/ProxmoxVE/pull/2468))
- Update BunkerWeb scripts to latest NGINX and specs [@TheophileDiot](https://github.com/TheophileDiot) ([#2466](https://github.com/community-scripts/ProxmoxVE/pull/2466))

## 2025-02-17

### Changes

### 💥 Breaking Changes

- Zipline: Prepare for Version 4.0.0 [@MickLesk](https://github.com/MickLesk) ([#2455](https://github.com/community-scripts/ProxmoxVE/pull/2455))

### 🚀 Updated Scripts

- Fix: Zipline increase SECRET to 42 chars [@V1d1o7](https://github.com/V1d1o7) ([#2444](https://github.com/community-scripts/ProxmoxVE/pull/2444))

## 2025-02-16

### Changes

### 🚀 Updated Scripts

- Fix: Typo in Ubuntu 24.10 VM Script [@PhoenixEmik](https://github.com/PhoenixEmik) ([#2430](https://github.com/community-scripts/ProxmoxVE/pull/2430))
- Fix: Grist update no longer removes previous user data [@cfurrow](https://github.com/cfurrow) ([#2428](https://github.com/community-scripts/ProxmoxVE/pull/2428))

### 🌐 Website

- Debian icon update [@bannert1337](https://github.com/bannert1337) ([#2433](https://github.com/community-scripts/ProxmoxVE/pull/2433))
- Update Graylog icon [@bannert1337](https://github.com/bannert1337) ([#2434](https://github.com/community-scripts/ProxmoxVE/pull/2434))

## 2025-02-15

### Changes

### 🚀 Updated Scripts

- Setup cron in install/freshrss-install.sh [@zimmra](https://github.com/zimmra) ([#2412](https://github.com/community-scripts/ProxmoxVE/pull/2412))
- Fix: Homarr update service files [@CrazyWolf13](https://github.com/CrazyWolf13) ([#2416](https://github.com/community-scripts/ProxmoxVE/pull/2416))
- Update MagicMirror install and update scripts [@tremor021](https://github.com/tremor021) ([#2409](https://github.com/community-scripts/ProxmoxVE/pull/2409))

### 🌐 Website

- Fix RustDesk slug in json [@tremor021](https://github.com/tremor021) ([#2411](https://github.com/community-scripts/ProxmoxVE/pull/2411))

### 🧰 Maintenance

- [GH] Update script-test Workflow [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2415](https://github.com/community-scripts/ProxmoxVE/pull/2415))

## 2025-02-14

### Changes

### 🚀 Updated Scripts

- Fix homarr [@CrazyWolf13](https://github.com/CrazyWolf13) ([#2369](https://github.com/community-scripts/ProxmoxVE/pull/2369))

### 🌐 Website

- RustDesk Server - Added configuration guide to json [@tremor021](https://github.com/tremor021) ([#2389](https://github.com/community-scripts/ProxmoxVE/pull/2389))

### 🧰 Maintenance

- [gh] Update script-test.yml [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2399](https://github.com/community-scripts/ProxmoxVE/pull/2399))
- [gh] Introducing new Issue Github Template Feature (Bug, Feature, Task) [@MickLesk](https://github.com/MickLesk) ([#2394](https://github.com/community-scripts/ProxmoxVE/pull/2394))

### 📡 API

- [API]Add more enpoints to API [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2390](https://github.com/community-scripts/ProxmoxVE/pull/2390))
- [API] Update api.func: Remove unwanted file creation [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2378](https://github.com/community-scripts/ProxmoxVE/pull/2378))

## 2025-02-13

### Changes

### ✨ New Scripts

- Re-Add: Pf2eTools [@MickLesk](https://github.com/MickLesk) ([#2336](https://github.com/community-scripts/ProxmoxVE/pull/2336))
- New Script: Nx Witness [@MickLesk](https://github.com/MickLesk) ([#2350](https://github.com/community-scripts/ProxmoxVE/pull/2350))
- New Script: RustDesk Server [@tremor021](https://github.com/tremor021) ([#2326](https://github.com/community-scripts/ProxmoxVE/pull/2326))
- New Script: MinIO [@MickLesk](https://github.com/MickLesk) ([#2333](https://github.com/community-scripts/ProxmoxVE/pull/2333))

### 🚀 Updated Scripts

- Missing ";" in ct/trilium.sh [@Scorpoon](https://github.com/Scorpoon) ([#2380](https://github.com/community-scripts/ProxmoxVE/pull/2380))
- Fix: Element Synapse - Fixed server listening on both localhost and 0.0.0.0 [@tremor021](https://github.com/tremor021) ([#2376](https://github.com/community-scripts/ProxmoxVE/pull/2376))
- [core] cleanup (remove # App Default Values) [@MickLesk](https://github.com/MickLesk) ([#2356](https://github.com/community-scripts/ProxmoxVE/pull/2356))
- Fix: Kometa - Increase RAM and HDD resources [@tremor021](https://github.com/tremor021) ([#2367](https://github.com/community-scripts/ProxmoxVE/pull/2367))
- [core] cleanup (remove base_settings & unneeded comments) [@MickLesk](https://github.com/MickLesk) ([#2351](https://github.com/community-scripts/ProxmoxVE/pull/2351))
- Fix: Authentik Embedded Outpost Upgrade [@vidonnus](https://github.com/vidonnus) ([#2327](https://github.com/community-scripts/ProxmoxVE/pull/2327))
- Fix HomeAsisstant LXC: Use the latest versions of runlike with --use-volume-id [@genehand](https://github.com/genehand) ([#2325](https://github.com/community-scripts/ProxmoxVE/pull/2325))

### 🌐 Website

- Fix: Zoraxy - now shows application as updateable on the website [@tremor021](https://github.com/tremor021) ([#2352](https://github.com/community-scripts/ProxmoxVE/pull/2352))
- Fix script category name text alignment in ScriptAccordion [@BramSuurdje](https://github.com/BramSuurdje) ([#2342](https://github.com/community-scripts/ProxmoxVE/pull/2342))

### 🧰 Maintenance

- [gh] Remove unwanted output from script test workflow [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2337](https://github.com/community-scripts/ProxmoxVE/pull/2337))
- [gh] Workflow to change date on new json files [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2319](https://github.com/community-scripts/ProxmoxVE/pull/2319))

## 2025-02-12

### Changes

### 💥 Breaking Changes

- Frigate: Use Fixed Version 14 [@MickLesk](https://github.com/MickLesk) ([#2288](https://github.com/community-scripts/ProxmoxVE/pull/2288))

### ✨ New Scripts

- New Script: Kometa [@tremor021](https://github.com/tremor021) ([#2281](https://github.com/community-scripts/ProxmoxVE/pull/2281))
- New Script: Excalidraw [@tremor021](https://github.com/tremor021) ([#2285](https://github.com/community-scripts/ProxmoxVE/pull/2285))
- New Script: Graylog [@tremor021](https://github.com/tremor021) ([#2270](https://github.com/community-scripts/ProxmoxVE/pull/2270))
- New Script: TasmoCompiler [@tremor021](https://github.com/tremor021) ([#2235](https://github.com/community-scripts/ProxmoxVE/pull/2235))
- New script: cross-seed [@jmatraszek](https://github.com/jmatraszek) ([#2186](https://github.com/community-scripts/ProxmoxVE/pull/2186))

### 🚀 Updated Scripts

- FIX: Frigate - remove bad variable [@tremor021](https://github.com/tremor021) ([#2323](https://github.com/community-scripts/ProxmoxVE/pull/2323))
- Fix: Kometa - Fix wrong web site address [@tremor021](https://github.com/tremor021) ([#2318](https://github.com/community-scripts/ProxmoxVE/pull/2318))
- Fix: var_tags instead of TAGS in some CT's [@MickLesk](https://github.com/MickLesk) ([#2310](https://github.com/community-scripts/ProxmoxVE/pull/2310))
- Update ubuntu2410-vm.sh: Fix typo in API call. [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2305](https://github.com/community-scripts/ProxmoxVE/pull/2305))
- Fix: Myspeed Installation (g++) [@MickLesk](https://github.com/MickLesk) ([#2308](https://github.com/community-scripts/ProxmoxVE/pull/2308))
- Fix: Pingvin wrong variable used for version tracking [@alberanid](https://github.com/alberanid) ([#2302](https://github.com/community-scripts/ProxmoxVE/pull/2302))
- Fix: SQL Server 2022 - remove unnecessary sudo [@tremor021](https://github.com/tremor021) ([#2282](https://github.com/community-scripts/ProxmoxVE/pull/2282))
- fix: frigate pin version [@CrazyWolf13](https://github.com/CrazyWolf13) ([#2296](https://github.com/community-scripts/ProxmoxVE/pull/2296))
- Fix changedetection: Correct Browser install [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2277](https://github.com/community-scripts/ProxmoxVE/pull/2277))
- Paperless-AI: add dependency "make" [@MickLesk](https://github.com/MickLesk) ([#2289](https://github.com/community-scripts/ProxmoxVE/pull/2289))
- Fix: Typo OPNsense VM [@chpego](https://github.com/chpego) ([#2291](https://github.com/community-scripts/ProxmoxVE/pull/2291))
- Fix: CraftyControler fix java default [@CrazyWolf13](https://github.com/CrazyWolf13) ([#2286](https://github.com/community-scripts/ProxmoxVE/pull/2286))

### 🌐 Website

- Fix: some jsons (debian instead Debian in OS) [@MickLesk](https://github.com/MickLesk) ([#2311](https://github.com/community-scripts/ProxmoxVE/pull/2311))
- Website: Add After-Install Note for Ubuntu VM 22.04/24.04/24.10 and Debian VM [@MickLesk](https://github.com/MickLesk) ([#2307](https://github.com/community-scripts/ProxmoxVE/pull/2307))
- Fix: duplicate 'VM' name in opnsense-vm.json [@nayzm](https://github.com/nayzm) ([#2293](https://github.com/community-scripts/ProxmoxVE/pull/2293))

## 2025-02-11

### Changes

### ✨ New Scripts

- New Script: Opnsense VM [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2097](https://github.com/community-scripts/ProxmoxVE/pull/2097))
- New Script: Watcharr [@tremor021](https://github.com/tremor021) ([#2243](https://github.com/community-scripts/ProxmoxVE/pull/2243))
- New Script: Suwayomi-Server [@tremor021](https://github.com/tremor021) ([#2139](https://github.com/community-scripts/ProxmoxVE/pull/2139))

### 🚀 Updated Scripts

- Fix Photoprism: Add defaults.yml for CLI Tool [@MickLesk](https://github.com/MickLesk) ([#2261](https://github.com/community-scripts/ProxmoxVE/pull/2261))
- Update Checkmk: include Patch versions in Release grepping [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2264](https://github.com/community-scripts/ProxmoxVE/pull/2264))
- Fix: Apache Guacamole Version Crawling - only latest Version [@MickLesk](https://github.com/MickLesk) ([#2258](https://github.com/community-scripts/ProxmoxVE/pull/2258))

### 🌐 Website

- Update Komodo icon [@bannert1337](https://github.com/bannert1337) ([#2263](https://github.com/community-scripts/ProxmoxVE/pull/2263))

### 🧰 Maintenance

- Add Workflow to test Scripts [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2269](https://github.com/community-scripts/ProxmoxVE/pull/2269))

## 2025-02-10

### Changes

### 💥 Breaking Changes

- [Fix] Filebrowser - Add Static Path for DB [@MickLesk](https://github.com/MickLesk) ([#2207](https://github.com/community-scripts/ProxmoxVE/pull/2207))

### ✨ New Scripts

- New Script: Prometheus Paperless-NGX Exporter [@andygrunwald](https://github.com/andygrunwald) ([#2153](https://github.com/community-scripts/ProxmoxVE/pull/2153))
- New Script: Proxmox Mail Gateway [@thost96](https://github.com/thost96) ([#1906](https://github.com/community-scripts/ProxmoxVE/pull/1906))
- New Script: FreshRSS [@bvdberg01](https://github.com/bvdberg01) ([#2226](https://github.com/community-scripts/ProxmoxVE/pull/2226))
- New Script: Zitadel [@dave-yap](https://github.com/dave-yap) ([#2141](https://github.com/community-scripts/ProxmoxVE/pull/2141))

### 🚀 Updated Scripts

- Feature: Automatic Deletion of choosen LXC's (lxc-delete.sh) [@MickLesk](https://github.com/MickLesk) ([#2228](https://github.com/community-scripts/ProxmoxVE/pull/2228))
- Quickfix: Crafty-Controller remove unnecessary \ [@MickLesk](https://github.com/MickLesk) ([#2233](https://github.com/community-scripts/ProxmoxVE/pull/2233))
- Fix: Crafty-Controller java versions and set default [@CrazyWolf13](https://github.com/CrazyWolf13) ([#2199](https://github.com/community-scripts/ProxmoxVE/pull/2199))
- Feature: Add optional Port for Filebrowser [@MickLesk](https://github.com/MickLesk) ([#2224](https://github.com/community-scripts/ProxmoxVE/pull/2224))
- [core] Prevent double spinner [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2203](https://github.com/community-scripts/ProxmoxVE/pull/2203))

### 🌐 Website

- Website: Fix Zitadel Logo & Created-Date [@MickLesk](https://github.com/MickLesk) ([#2217](https://github.com/community-scripts/ProxmoxVE/pull/2217))
- Fixed URL typo zerotier-one.json [@Divaksh](https://github.com/Divaksh) ([#2206](https://github.com/community-scripts/ProxmoxVE/pull/2206))
- evcc.json Clarify the config file location [@mvdw](https://github.com/mvdw) ([#2193](https://github.com/community-scripts/ProxmoxVE/pull/2193))

### 🧰 Maintenance

- [gh]: Improve Workflows, Templates, Handling [@MickLesk](https://github.com/MickLesk) ([#2214](https://github.com/community-scripts/ProxmoxVE/pull/2214))
- [core] Fix app-header workflow and add API [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2204](https://github.com/community-scripts/ProxmoxVE/pull/2204))
- Fix: "read -p" does not support color formatting [@PhoenixEmik](https://github.com/PhoenixEmik) ([#2191](https://github.com/community-scripts/ProxmoxVE/pull/2191))
- [API] Add API to vms [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2021](https://github.com/community-scripts/ProxmoxVE/pull/2021))

## 2025-02-09

### Changed

### ✨ New Scripts

- New Script: pbs_microcode.sh [@DonPablo1010](https://github.com/DonPablo1010) ([#2166](https://github.com/community-scripts/ProxmoxVE/pull/2166))

### 🚀 Updated Scripts

- Keep the same hass_config volume for Home Assistant [@genehand](https://github.com/genehand) ([#2160](https://github.com/community-scripts/ProxmoxVE/pull/2160))

### 🌐 Website

- Website: Set new Logo for Paperless-AI [@MickLesk](https://github.com/MickLesk) ([#2194](https://github.com/community-scripts/ProxmoxVE/pull/2194))
- Fix: Barcode Buddy Logo & Title [@MickLesk](https://github.com/MickLesk) ([#2183](https://github.com/community-scripts/ProxmoxVE/pull/2183))

## 2025-02-08

### Changed

### ✨ New Scripts

- New script: Barcode Buddy [@bvdberg01](https://github.com/bvdberg01) ([#2167](https://github.com/community-scripts/ProxmoxVE/pull/2167))

### 🚀 Updated Scripts

- Fix: Actualbudget - salvage the `.migrate` file when upgrading [@bourquep](https://github.com/bourquep) ([#2173](https://github.com/community-scripts/ProxmoxVE/pull/2173))

### 🌐 Website

- Update cosmos.json description [@BramSuurdje](https://github.com/BramSuurdje) ([#2162](https://github.com/community-scripts/ProxmoxVE/pull/2162))

### 🧰 Maintenance

- fix typos in CONTRIBUTOR_GUIDE [@thomashondema](https://github.com/thomashondema) ([#2174](https://github.com/community-scripts/ProxmoxVE/pull/2174))

## 2025-02-07 - 10.000 ⭐

### Changed

### 💥 Breaking Changes

- [core]: Enhance LXC template handling and improve error recovery [@MickLesk](https://github.com/MickLesk) ([#2128](https://github.com/community-scripts/ProxmoxVE/pull/2128))

### ✨ New Scripts

- New Script: Cosmos [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2120](https://github.com/community-scripts/ProxmoxVE/pull/2120))
- New Script: SearXNG [@MickLesk](https://github.com/MickLesk) ([#2123](https://github.com/community-scripts/ProxmoxVE/pull/2123))

### 🚀 Updated Scripts

- Fix: Trillium Update Function & Harmonize Installation [@MickLesk](https://github.com/MickLesk) ([#2148](https://github.com/community-scripts/ProxmoxVE/pull/2148))
- Fix: Zerotier-One fixed missing dependency [@tremor021](https://github.com/tremor021) ([#2147](https://github.com/community-scripts/ProxmoxVE/pull/2147))
- Fix: Openwrt Version checking [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2137](https://github.com/community-scripts/ProxmoxVE/pull/2137))
- Fix: PeaNUT Increase HDD & RAM Size [@MickLesk](https://github.com/MickLesk) ([#2127](https://github.com/community-scripts/ProxmoxVE/pull/2127))

### 🌐 Website

- Fix: Zerotier json had a bad script path [@tremor021](https://github.com/tremor021) ([#2144](https://github.com/community-scripts/ProxmoxVE/pull/2144))
- Fix: Cosmos logo doesnt display on website [@MickLesk](https://github.com/MickLesk) ([#2132](https://github.com/community-scripts/ProxmoxVE/pull/2132))
- Fix JSON-Editor [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2121](https://github.com/community-scripts/ProxmoxVE/pull/2121))

### 🧰 Maintenance

- [gh]: Following the trend - add star-history in readme [@MickLesk](https://github.com/MickLesk) ([#2135](https://github.com/community-scripts/ProxmoxVE/pull/2135))

## 2025-02-06

### Changed

### ✨ New Scripts

- New Script: Duplicati [@tremor021](https://github.com/tremor021) ([#2052](https://github.com/community-scripts/ProxmoxVE/pull/2052))
- New Script: Paperless-AI [@MickLesk](https://github.com/MickLesk) ([#2093](https://github.com/community-scripts/ProxmoxVE/pull/2093))
- New Script: Apache Tika [@andygrunwald](https://github.com/andygrunwald) ([#2079](https://github.com/community-scripts/ProxmoxVE/pull/2079))

### 🚀 Updated Scripts

- Fix: Alpine IT-Tools Update [@MickLesk](https://github.com/MickLesk) ([#2067](https://github.com/community-scripts/ProxmoxVE/pull/2067))
- Fix: Pocket-ID Change link to GH Repo [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2082](https://github.com/community-scripts/ProxmoxVE/pull/2082))

### 🌐 Website

- Refactor JSON generator buttons layout for better alignment and consistency [@BramSuurdje](https://github.com/BramSuurdje) ([#2106](https://github.com/community-scripts/ProxmoxVE/pull/2106))
- Website: Refactor Footer for improved layout and styling consistency [@BramSuurdje](https://github.com/BramSuurdje) ([#2107](https://github.com/community-scripts/ProxmoxVE/pull/2107))
- Website: Update Footer for Json-Editor & Api [@MickLesk](https://github.com/MickLesk) ([#2100](https://github.com/community-scripts/ProxmoxVE/pull/2100))
- Website: Add Download for json-editor [@MickLesk](https://github.com/MickLesk) ([#2099](https://github.com/community-scripts/ProxmoxVE/pull/2099))
- Radicale: Provide additional information about configuration [@tremor021](https://github.com/tremor021) ([#2072](https://github.com/community-scripts/ProxmoxVE/pull/2072))

## 2025-02-05

### Changed

### ✨ New Scripts

- New Script: Zerotier Controller [@tremor021](https://github.com/tremor021) ([#1928](https://github.com/community-scripts/ProxmoxVE/pull/1928))
- New Script: Radicale [@tremor021](https://github.com/tremor021) ([#1941](https://github.com/community-scripts/ProxmoxVE/pull/1941))
- New Script: seelf [@tremor021](https://github.com/tremor021) ([#2023](https://github.com/community-scripts/ProxmoxVE/pull/2023))
- New Script: Crafty-Controller [@CrazyWolf13](https://github.com/CrazyWolf13) ([#1926](https://github.com/community-scripts/ProxmoxVE/pull/1926))
- New script: Koillection [@bvdberg01](https://github.com/bvdberg01) ([#2031](https://github.com/community-scripts/ProxmoxVE/pull/2031))

### 🚀 Updated Scripts

- Bugfix: Jellyseerr pnpm Version [@vidonnus](https://github.com/vidonnus) ([#2033](https://github.com/community-scripts/ProxmoxVE/pull/2033))
- Radicale: Fixed missing htpasswd flag [@tremor021](https://github.com/tremor021) ([#2065](https://github.com/community-scripts/ProxmoxVE/pull/2065))
- [API] Update build.func / Improve error messages #2 [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2050](https://github.com/community-scripts/ProxmoxVE/pull/2050))
- [API] Update create-lxc.sh / Improve error messages #1 [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2049](https://github.com/community-scripts/ProxmoxVE/pull/2049))
- Feature: Element Synapse: add option to enter server name during LXC installation [@tremor021](https://github.com/tremor021) ([#2038](https://github.com/community-scripts/ProxmoxVE/pull/2038))

### 🌐 Website

- Paperless NGX: Mark it as updateable [@andygrunwald](https://github.com/andygrunwald) ([#2070](https://github.com/community-scripts/ProxmoxVE/pull/2070))
- Bump vitest from 2.1.6 to 2.1.9 in /frontend [@dependabot[bot]](https://github.com/dependabot[bot]) ([#2042](https://github.com/community-scripts/ProxmoxVE/pull/2042))

### 🧰 Maintenance

- [API] Add API backend code [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2040](https://github.com/community-scripts/ProxmoxVE/pull/2040))
- Update auto-update-app-headers.yml: Enable auto approval [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2057](https://github.com/community-scripts/ProxmoxVE/pull/2057))

## 2025-02-04

### Changed

### 💥 Breaking Changes

- Rename & Optimize: Proxmox Backup Server (Renaming & Update fix) [@thost96](https://github.com/thost96) ([#2012](https://github.com/community-scripts/ProxmoxVE/pull/2012))

### 🚀 Updated Scripts

- Fix: Authentik - Remove deprecated GO-Remove in Footer [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2020](https://github.com/community-scripts/ProxmoxVE/pull/2020))
- Fix: Authentik Fix wrong HDD Size [@thost96](https://github.com/thost96) ([#2001](https://github.com/community-scripts/ProxmoxVE/pull/2001))
- Fix: Tandoor - node Version [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#2010](https://github.com/community-scripts/ProxmoxVE/pull/2010))
- Fix actual update - missing hidden files, downloaded release cleanup [@maciejmatczak](https://github.com/maciejmatczak) ([#2027](https://github.com/community-scripts/ProxmoxVE/pull/2027))
- Fix Script: post-pmg-install.sh [@thost96](https://github.com/thost96) ([#2022](https://github.com/community-scripts/ProxmoxVE/pull/2022))
- Fix Tianji: Add heap-space value for nodejs [@MickLesk](https://github.com/MickLesk) ([#2011](https://github.com/community-scripts/ProxmoxVE/pull/2011))
- Fix: Ghost LXC - Use Node20 [@MickLesk](https://github.com/MickLesk) ([#2006](https://github.com/community-scripts/ProxmoxVE/pull/2006))

### 🌐 Website

- [API] Massive update to api (remove many, optimize website for users) [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1990](https://github.com/community-scripts/ProxmoxVE/pull/1990))

### 🧰 Maintenance

- Fix header comments on contributor templates [@tremor021](https://github.com/tremor021) ([#2029](https://github.com/community-scripts/ProxmoxVE/pull/2029))
- [Fix]: Headername of Proxmox-Datacenter-Manager not in CamelCase [@MickLesk](https://github.com/MickLesk) ([#2017](https://github.com/community-scripts/ProxmoxVE/pull/2017))
- [Fix] Header breaks at long title - add width for figlet github action [@MickLesk](https://github.com/MickLesk) ([#2015](https://github.com/community-scripts/ProxmoxVE/pull/2015))

## 2025-02-03

### Changed

### ✨ New Scripts

- New Script: Element Synapse [@tremor021](https://github.com/tremor021) ([#1955](https://github.com/community-scripts/ProxmoxVE/pull/1955))
- New Script: Privatebin [@opastorello](https://github.com/opastorello) ([#1925](https://github.com/community-scripts/ProxmoxVE/pull/1925))

### 🚀 Updated Scripts

- Fix: Monica Install with nodejs [@MickLesk](https://github.com/MickLesk) ([#1996](https://github.com/community-scripts/ProxmoxVE/pull/1996))
- Element Synapse sed fix [@tremor021](https://github.com/tremor021) ([#1994](https://github.com/community-scripts/ProxmoxVE/pull/1994))
- Fix Hoarder corepack install/update error [@vhsdream](https://github.com/vhsdream) ([#1957](https://github.com/community-scripts/ProxmoxVE/pull/1957))
- [Security & Maintenance] Update NodeJS Repo to 22 for new Installs [@MickLesk](https://github.com/MickLesk) ([#1984](https://github.com/community-scripts/ProxmoxVE/pull/1984))
- [Standardization]: Same Setup for GoLang on all LXC's & Clear Tarball [@MickLesk](https://github.com/MickLesk) ([#1977](https://github.com/community-scripts/ProxmoxVE/pull/1977))
- Feature: urbackupserver Include fuse&nesting features during install [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1968](https://github.com/community-scripts/ProxmoxVE/pull/1968))
- Fix: MSSQL-Server: Better gpg handling [@MickLesk](https://github.com/MickLesk) ([#1962](https://github.com/community-scripts/ProxmoxVE/pull/1962))
- Fix: Grist ran into a heap space during the update [@MickLesk](https://github.com/MickLesk) ([#1964](https://github.com/community-scripts/ProxmoxVE/pull/1964))
- Fix: FS-Trim Cancel / Error-Button [@MickLesk](https://github.com/MickLesk) ([#1965](https://github.com/community-scripts/ProxmoxVE/pull/1965))
- Fix: Increase HDD Space for Hoarder [@MickLesk](https://github.com/MickLesk) ([#1970](https://github.com/community-scripts/ProxmoxVE/pull/1970))
- Feature: Clean Orphan LVM without CEPH [@MickLesk](https://github.com/MickLesk) ([#1974](https://github.com/community-scripts/ProxmoxVE/pull/1974))
- [Standardization] Fix Spelling for "Setup Python3"  [@MickLesk](https://github.com/MickLesk) ([#1975](https://github.com/community-scripts/ProxmoxVE/pull/1975))

### 🌐 Website

- [Website] update data/page.tsx [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1969](https://github.com/community-scripts/ProxmoxVE/pull/1969))
- Prometheus Proxmox VE Exporter: Set correct website slug [@andygrunwald](https://github.com/andygrunwald) ([#1961](https://github.com/community-scripts/ProxmoxVE/pull/1961))

### 🧰 Maintenance

- [API] Remove Hostname, Verbose, SSH and TAGS [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1967](https://github.com/community-scripts/ProxmoxVE/pull/1967))

## 2025-02-02

### Changed

### 🚀 Updated Scripts

- Prometheus PVE Exporter: Add `--default-timeout=300` to pip install commands [@andygrunwald](https://github.com/andygrunwald) ([#1950](https://github.com/community-scripts/ProxmoxVE/pull/1950))
- fix z2m update function to 2.1.0 [@MickLesk](https://github.com/MickLesk) ([#1938](https://github.com/community-scripts/ProxmoxVE/pull/1938))

### 🧰 Maintenance

- VSCode: Add Shellscript Syntax highlighting for *.func files [@andygrunwald](https://github.com/andygrunwald) ([#1948](https://github.com/community-scripts/ProxmoxVE/pull/1948))

## 2025-02-01

### Changed

### 💥 Breaking Changes

- [DCMA] Delete scripts 5etools and pf2etools - Copyright abuse [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1922](https://github.com/community-scripts/ProxmoxVE/pull/1922))

### ✨ New Scripts

- New script: Baïkal [@bvdberg01](https://github.com/bvdberg01) ([#1913](https://github.com/community-scripts/ProxmoxVE/pull/1913))

### 🚀 Updated Scripts

- Bug fix: Paymenter [@opastorello](https://github.com/opastorello) ([#1917](https://github.com/community-scripts/ProxmoxVE/pull/1917))

## 2025-01-31

### Changed

### ✨ New Scripts

- New Script: Paymenter [@opastorello](https://github.com/opastorello) ([#1827](https://github.com/community-scripts/ProxmoxVE/pull/1827))

### 🚀 Updated Scripts

- [Fix] Alpine-IT-Tools, add missing ssh package for root ssh access [@CrazyWolf13](https://github.com/CrazyWolf13) ([#1891](https://github.com/community-scripts/ProxmoxVE/pull/1891))
- [Fix] Change Download of Trilium after there change the tag/release logic [@MickLesk](https://github.com/MickLesk) ([#1892](https://github.com/community-scripts/ProxmoxVE/pull/1892))

### 🌐 Website

- [Website] Enhance DataFetcher with better UI components and add reactive data fetching intervals [@BramSuurdje](https://github.com/BramSuurdje) ([#1902](https://github.com/community-scripts/ProxmoxVE/pull/1902))
- [Website] Update /data/page.tsx [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1900](https://github.com/community-scripts/ProxmoxVE/pull/1900))

## 2025-01-30

### Changed

### ✨ New Scripts

- New Script: IT-Tools [@nicedevil007](https://github.com/nicedevil007) ([#1862](https://github.com/community-scripts/ProxmoxVE/pull/1862))
- New Script: Mattermost [@Dracentis](https://github.com/Dracentis) ([#1856](https://github.com/community-scripts/ProxmoxVE/pull/1856))

### 🚀 Updated Scripts

- Optimize PVE Manager Version-Check [@MickLesk](https://github.com/MickLesk) ([#1866](https://github.com/community-scripts/ProxmoxVE/pull/1866))

### 🌐 Website

- [API] Update build.func to set the status message correct [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1878](https://github.com/community-scripts/ProxmoxVE/pull/1878))
- [Website] Update /data/page.tsx [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1876](https://github.com/community-scripts/ProxmoxVE/pull/1876))
- Fix IT-Tools Website Entry (Default | Alpine)  [@MickLesk](https://github.com/MickLesk) ([#1869](https://github.com/community-scripts/ProxmoxVE/pull/1869))
- fix: remove rounded styles from command primitive [@steveiliop56](https://github.com/steveiliop56) ([#1840](https://github.com/community-scripts/ProxmoxVE/pull/1840))

### 🧰 Maintenance

- [API] Update build.func: add function to see if a script failed or not [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1874](https://github.com/community-scripts/ProxmoxVE/pull/1874))

## 2025-01-29

### Changed

### ✨ New Scripts

- New Script: Prometheus Proxmox VE Exporter [@andygrunwald](https://github.com/andygrunwald) ([#1805](https://github.com/community-scripts/ProxmoxVE/pull/1805))
- New Script: Clean Orphaned LVM [@MickLesk](https://github.com/MickLesk) ([#1838](https://github.com/community-scripts/ProxmoxVE/pull/1838))

### 🌐 Website

- Patch http Url to https in build.func and /data/page.tsx [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1849](https://github.com/community-scripts/ProxmoxVE/pull/1849))
- [Frontend] Add /data to show API results [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1841](https://github.com/community-scripts/ProxmoxVE/pull/1841))
- Update clean-orphaned-lvm.json [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1843](https://github.com/community-scripts/ProxmoxVE/pull/1843))

### 🧰 Maintenance

- Update build.func [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1851](https://github.com/community-scripts/ProxmoxVE/pull/1851))
- [Diagnostic] Introduced optional lxc install diagnostics via API call [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1801](https://github.com/community-scripts/ProxmoxVE/pull/1801))

## 2025-01-28

### Changed

### 💥 Breaking Changes

- Breaking Change: Homarr v1 (Read Guide) [@MickLesk](https://github.com/MickLesk) ([#1825](https://github.com/community-scripts/ProxmoxVE/pull/1825))
- Update PingVin: Fix problem with update und switch to new method of getting files. [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1819](https://github.com/community-scripts/ProxmoxVE/pull/1819))

### ✨ New Scripts

- New script: Monica LXC [@bvdberg01](https://github.com/bvdberg01) ([#1813](https://github.com/community-scripts/ProxmoxVE/pull/1813))
- New Script: NodeBB [@MickLesk](https://github.com/MickLesk) ([#1811](https://github.com/community-scripts/ProxmoxVE/pull/1811))
- New Script: Pocket ID [@Snarkenfaugister](https://github.com/Snarkenfaugister) ([#1779](https://github.com/community-scripts/ProxmoxVE/pull/1779))

### 🚀 Updated Scripts

- Update all Alpine LXC's to 3.21 (Docker, Grafana, Nextcloud, Vaultwarden, Zigbee2Mqtt, Alpine) [@MickLesk](https://github.com/MickLesk) ([#1803](https://github.com/community-scripts/ProxmoxVE/pull/1803))
- [Standardization] Fix Spelling for "Setup Python3" [@MickLesk](https://github.com/MickLesk) ([#1810](https://github.com/community-scripts/ProxmoxVE/pull/1810))

### 🌐 Website

- Filter out duplicate scripts in LatestScripts component and sort by creation date [@BramSuurdje](https://github.com/BramSuurdje) ([#1828](https://github.com/community-scripts/ProxmoxVE/pull/1828))

### 🧰 Maintenance

- [core]: Remove Figlet | Get Headers by Repo & Store Local [@MickLesk](https://github.com/MickLesk) ([#1802](https://github.com/community-scripts/ProxmoxVE/pull/1802))
- [docs] Update AppName.md: Make it clear where to change the URLs [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1809](https://github.com/community-scripts/ProxmoxVE/pull/1809))

## 2025-01-27

### Changed

### ✨ New Scripts

- New Script: Arch Linux VM [@MickLesk](https://github.com/MickLesk) ([#1780](https://github.com/community-scripts/ProxmoxVE/pull/1780))

### 🚀 Updated Scripts

- Increase alpine-vaultwarden default var_disk size [@nayzm](https://github.com/nayzm) ([#1788](https://github.com/community-scripts/ProxmoxVE/pull/1788))
- Added change of the mobile GUI to disable nag request [@GarryG](https://github.com/GarryG) ([#1785](https://github.com/community-scripts/ProxmoxVE/pull/1785))

### 🌐 Website

- Update frontend alpine-vaultwarden hdd size and OS version [@nayzm](https://github.com/nayzm) ([#1789](https://github.com/community-scripts/ProxmoxVE/pull/1789))
- Website: Add Description for Metadata Categories [@MickLesk](https://github.com/MickLesk) ([#1783](https://github.com/community-scripts/ProxmoxVE/pull/1783))
- [Fix] Double "VM" on website (Arch Linux) [@lasharor](https://github.com/lasharor) ([#1782](https://github.com/community-scripts/ProxmoxVE/pull/1782))

## 2025-01-26

### Changed

### 🚀 Updated Scripts

- Fix jellyfin update command [@jcisio](https://github.com/jcisio) ([#1771](https://github.com/community-scripts/ProxmoxVE/pull/1771))
- openHAB - Use https and include doc url [@moodyblue](https://github.com/moodyblue) ([#1766](https://github.com/community-scripts/ProxmoxVE/pull/1766))
- Jellyfin: Fix default logging level [@tremor021](https://github.com/tremor021) ([#1768](https://github.com/community-scripts/ProxmoxVE/pull/1768))
- Calibre-Web: added installation of calibre binaries [@tremor021](https://github.com/tremor021) ([#1763](https://github.com/community-scripts/ProxmoxVE/pull/1763))
- Added environment variable to accept EULA for SQLServer2022 [@tremor021](https://github.com/tremor021) ([#1755](https://github.com/community-scripts/ProxmoxVE/pull/1755))

### 🌐 Website

- The Lounge: Fix the command to create new users [@tremor021](https://github.com/tremor021) ([#1762](https://github.com/community-scripts/ProxmoxVE/pull/1762))

## 2025-01-24

### Changed

### ✨ New Scripts

- New Script: Ubuntu 24.10 VM [@MickLesk](https://github.com/MickLesk) ([#1711](https://github.com/community-scripts/ProxmoxVE/pull/1711))

### 🚀 Updated Scripts

- openHAB - Update to Zulu21 [@moodyblue](https://github.com/moodyblue) ([#1734](https://github.com/community-scripts/ProxmoxVE/pull/1734))
- Feature: Filebrowser Script > Redesign | Update Logic | Remove Logic [@MickLesk](https://github.com/MickLesk) ([#1716](https://github.com/community-scripts/ProxmoxVE/pull/1716))
- Feature: Ubuntu 22.04 VM > Redesign | Optional HDD-Size Prompt [@MickLesk](https://github.com/MickLesk) ([#1712](https://github.com/community-scripts/ProxmoxVE/pull/1712))
- Feature: Ubuntu 24.04 VM > Redesign | Optional HDD-Size Prompt | cifs support [@MickLesk](https://github.com/MickLesk) ([#1714](https://github.com/community-scripts/ProxmoxVE/pull/1714))

### 🧰 Maintenance

- [Core] Better Creation of App Headers for next feature [@MickLesk](https://github.com/MickLesk) ([#1719](https://github.com/community-scripts/ProxmoxVE/pull/1719))

## 2025-01-23

### Changed

### 🚀 Updated Scripts

- Feature: Add Debian Disk Size / Redesign / Increase Disk [@MickLesk](https://github.com/MickLesk) ([#1695](https://github.com/community-scripts/ProxmoxVE/pull/1695))
- Fix: Paperless Service Timings & Optimization: Ghostscript Installation [@MickLesk](https://github.com/MickLesk) ([#1688](https://github.com/community-scripts/ProxmoxVE/pull/1688))

### 🌐 Website

- Refactor ScriptInfoBlocks and siteConfig to properly show the most populair scripts [@BramSuurdje](https://github.com/BramSuurdje) ([#1697](https://github.com/community-scripts/ProxmoxVE/pull/1697))

### 🧰 Maintenance

- Update build.func: Ubuntu advanced settings version [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1701](https://github.com/community-scripts/ProxmoxVE/pull/1701))

## 2025-01-22

### Changed

### 🚀 Updated Scripts

- Tweak: LubeLogger Script Upcoming Changes 1.4.3 [@JcMinarro](https://github.com/JcMinarro) ([#1656](https://github.com/community-scripts/ProxmoxVE/pull/1656))
- Fix: SQL Server 2022 Install [@MickLesk](https://github.com/MickLesk) ([#1669](https://github.com/community-scripts/ProxmoxVE/pull/1669))

### 🌐 Website

- Refactor Sidebar component to display unique scripts count [@BramSuurdje](https://github.com/BramSuurdje) ([#1681](https://github.com/community-scripts/ProxmoxVE/pull/1681))
- Refactor various components and configuration for mobile responsiveness. [@BramSuurdje](https://github.com/BramSuurdje) ([#1679](https://github.com/community-scripts/ProxmoxVE/pull/1679))
- Add Docker-VM to Containers & Docker Category [@thost96](https://github.com/thost96) ([#1667](https://github.com/community-scripts/ProxmoxVE/pull/1667))
- Moving SQL Server 2022 to database category [@CamronBorealis](https://github.com/CamronBorealis) ([#1659](https://github.com/community-scripts/ProxmoxVE/pull/1659))

## 2025-01-21

### Changed

### ✨ New Scripts

- Add new Script: LXC Delete (Proxmox) [@MickLesk](https://github.com/MickLesk) ([#1636](https://github.com/community-scripts/ProxmoxVE/pull/1636))
- New script: ProjectSend [@bvdberg01](https://github.com/bvdberg01) ([#1616](https://github.com/community-scripts/ProxmoxVE/pull/1616))
- New Script: Beszel [@Sinofage](https://github.com/Sinofage) ([#1619](https://github.com/community-scripts/ProxmoxVE/pull/1619))
- New Script: Docker VM [@thost96](https://github.com/thost96) ([#1608](https://github.com/community-scripts/ProxmoxVE/pull/1608))
- New script: SQL Server 2022 [@kris701](https://github.com/kris701) ([#1482](https://github.com/community-scripts/ProxmoxVE/pull/1482))

### 🚀 Updated Scripts

- Fix: Teddycloud Script (install, clean up & update) [@MickLesk](https://github.com/MickLesk) ([#1652](https://github.com/community-scripts/ProxmoxVE/pull/1652))
- Fix: Docker VM deprecated gpg [@MickLesk](https://github.com/MickLesk) ([#1649](https://github.com/community-scripts/ProxmoxVE/pull/1649))
- ActualBudget: Fix Update-Function, Fix Wget Crawling, Add Versionscheck [@MickLesk](https://github.com/MickLesk) ([#1643](https://github.com/community-scripts/ProxmoxVE/pull/1643))
- Fix Photoprism missing folder & environments  [@MickLesk](https://github.com/MickLesk) ([#1639](https://github.com/community-scripts/ProxmoxVE/pull/1639))
- Update MOTD: Add Dynamic IP with profile.d by @JcMinarro [@MickLesk](https://github.com/MickLesk) ([#1633](https://github.com/community-scripts/ProxmoxVE/pull/1633))
- PBS.sh: Fix wrong URL after Setup [@thost96](https://github.com/thost96) ([#1629](https://github.com/community-scripts/ProxmoxVE/pull/1629))

### 🌐 Website

- Bump vite from 6.0.1 to 6.0.11 in /frontend [@dependabot[bot]](https://github.com/dependabot[bot]) ([#1653](https://github.com/community-scripts/ProxmoxVE/pull/1653))
- Update glpi.json [@opastorello](https://github.com/opastorello) ([#1641](https://github.com/community-scripts/ProxmoxVE/pull/1641))
- Fix Docker-VM name on website [@Sinofage](https://github.com/Sinofage) ([#1630](https://github.com/community-scripts/ProxmoxVE/pull/1630))

## 2025-01-20

### Changed

### ✨ New Scripts

- New Script: UrBackup Server [@kris701](https://github.com/kris701) ([#1569](https://github.com/community-scripts/ProxmoxVE/pull/1569))
- New Script: Proxmox Mail Gateway Post Installer [@thost96](https://github.com/thost96) ([#1559](https://github.com/community-scripts/ProxmoxVE/pull/1559))

### 🚀 Updated Scripts

- Update Kimai Dependency: Use PHP 8.3 [@MickLesk](https://github.com/MickLesk) ([#1609](https://github.com/community-scripts/ProxmoxVE/pull/1609))
- Feature: Add xCaddy for external Modules on Caddy-LXC [@MickLesk](https://github.com/MickLesk) ([#1613](https://github.com/community-scripts/ProxmoxVE/pull/1613))
- Fix Pocketbase URL after install [@MickLesk](https://github.com/MickLesk) ([#1597](https://github.com/community-scripts/ProxmoxVE/pull/1597))
- Unifi.sh fix wrong URL after Install [@thost96](https://github.com/thost96) ([#1601](https://github.com/community-scripts/ProxmoxVE/pull/1601))

### 🌐 Website

- Update Website | Add new Categories [@MickLesk](https://github.com/MickLesk) ([#1606](https://github.com/community-scripts/ProxmoxVE/pull/1606))
- Grafana: Mark container as updateable [@andygrunwald](https://github.com/andygrunwald) ([#1603](https://github.com/community-scripts/ProxmoxVE/pull/1603))

### 🧰 Maintenance

- [core] Update build.func: Add defaults to Advanced mode [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1548](https://github.com/community-scripts/ProxmoxVE/pull/1548))
- Update build.func: Fix Advanced Tags (Remove all if empty / overwrite if default cleared) [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1612](https://github.com/community-scripts/ProxmoxVE/pull/1612))
- Add new Check for LXC MaxKeys by @cricalix [@MickLesk](https://github.com/MickLesk) ([#1602](https://github.com/community-scripts/ProxmoxVE/pull/1602))

## 2025-01-19

### Changed

### 🚀 Updated Scripts

- Update Opengist.sh: Fix broken backup function [@bvdberg01](https://github.com/bvdberg01) ([#1572](https://github.com/community-scripts/ProxmoxVE/pull/1572))

## 2025-01-18

### Changed

### 💥 Breaking Changes

- **READ GUIDE FIRST** breaking change: Homeassistant-Core upgrade os and python3 [@MickLesk](https://github.com/MickLesk) ([#1550](https://github.com/community-scripts/ProxmoxVE/pull/1550))
- Update Openwrt: Delete lines that do WAN input and forward accept [@chackl1990](https://github.com/chackl1990) ([#1540](https://github.com/community-scripts/ProxmoxVE/pull/1540))

### 🚀 Updated Scripts

- added cifs support in ubuntu2404-vm.sh [@plonxyz](https://github.com/plonxyz) ([#1461](https://github.com/community-scripts/ProxmoxVE/pull/1461))
- Fix linkwarden update [@burgerga](https://github.com/burgerga) ([#1565](https://github.com/community-scripts/ProxmoxVE/pull/1565))
- [jellyseerr] Update nodejs if not up-to-date [@makstech](https://github.com/makstech) ([#1563](https://github.com/community-scripts/ProxmoxVE/pull/1563))
- Update VM Tags [@oOStroudyOo](https://github.com/oOStroudyOo) ([#1562](https://github.com/community-scripts/ProxmoxVE/pull/1562))
- Update apt-cacher-ng.sh: Typo/Missing $ [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1545](https://github.com/community-scripts/ProxmoxVE/pull/1545))

## 2025-01-16

### Changed

### 💥 Breaking Changes

- Update jellyseerr-install.sh to use Node 22 as required by latest Jellyseerr version [@pedrovieira](https://github.com/pedrovieira) ([#1535](https://github.com/community-scripts/ProxmoxVE/pull/1535))

### ✨ New Scripts

- New script: Dotnet ASP.NET Web Server [@kris701](https://github.com/kris701) ([#1501](https://github.com/community-scripts/ProxmoxVE/pull/1501))
- New script: phpIPAM [@bvdberg01](https://github.com/bvdberg01) ([#1503](https://github.com/community-scripts/ProxmoxVE/pull/1503))

### 🌐 Website

- Add Mobile check for empty icon-url on website [@MickLesk](https://github.com/MickLesk) ([#1532](https://github.com/community-scripts/ProxmoxVE/pull/1532))

### 🧰 Maintenance

- [Workflow]Update autolabeler-config.json [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1525](https://github.com/community-scripts/ProxmoxVE/pull/1525))
- [core]Update update_json_date.yml [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1526](https://github.com/community-scripts/ProxmoxVE/pull/1526))
- [core] Recreate Update JSON Workflow [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1523](https://github.com/community-scripts/ProxmoxVE/pull/1523))

## 2025-01-15

### Changed

### 🚀 Updated Scripts

- Fix: Add FFMPEG for OpenWebUI [@MickLesk](https://github.com/MickLesk) ([#1497](https://github.com/community-scripts/ProxmoxVE/pull/1497))

### 🧰 Maintenance

- [core] build.func&install.func: Fix ssh keynot added error [@dsiebel](https://github.com/dsiebel) ([#1502](https://github.com/community-scripts/ProxmoxVE/pull/1502))

## 2025-01-14

### Changed

### 💥 Breaking Changes

- Update tianji-install.sh: Add OPENAI_API_KEY to .env [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1480](https://github.com/community-scripts/ProxmoxVE/pull/1480))

### ✨ New Scripts

- New Script: Wordpress [@MickLesk](https://github.com/MickLesk) ([#1485](https://github.com/community-scripts/ProxmoxVE/pull/1485))
- New Script: Opengist [@jd-apprentice](https://github.com/jd-apprentice) ([#1429](https://github.com/community-scripts/ProxmoxVE/pull/1429))

### 🚀 Updated Scripts

- Update lazylibrarian-install.sh: Add pypdf libary [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1467](https://github.com/community-scripts/ProxmoxVE/pull/1467))
- Update opengist-install.sh: Add git as dependencie [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1471](https://github.com/community-scripts/ProxmoxVE/pull/1471))

### 🌐 Website

- [website] Update footer text [@rajatdiptabiswas](https://github.com/rajatdiptabiswas) ([#1466](https://github.com/community-scripts/ProxmoxVE/pull/1466))

### 🧰 Maintenance

- Hotfix build.func: Error when tags are empty [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1492](https://github.com/community-scripts/ProxmoxVE/pull/1492))
- [core] Update build.func: Fix bug with advanced tags [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1473](https://github.com/community-scripts/ProxmoxVE/pull/1473))

## 2025-01-13

### Changed

### 💥 Breaking Changes

- Update Hoarder: Improvement .env location (see PR comment for little migration) [@MahrWe](https://github.com/MahrWe) ([#1325](https://github.com/community-scripts/ProxmoxVE/pull/1325))

### 🚀 Updated Scripts

- Fix: tandoor.sh: Call version.py to write current version [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1454](https://github.com/community-scripts/ProxmoxVE/pull/1454))
- Fix inexistent folder on actualbudget update script [@dosten](https://github.com/dosten) ([#1444](https://github.com/community-scripts/ProxmoxVE/pull/1444))

### 🌐 Website

- Update kavita.json: Add info on how to enable folder adding. [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1447](https://github.com/community-scripts/ProxmoxVE/pull/1447))

### 🧰 Maintenance

- GitHub Actions: Fix Shellsheck workflow to only run on changes `*.sh` files [@andygrunwald](https://github.com/andygrunwald) ([#1423](https://github.com/community-scripts/ProxmoxVE/pull/1423))

### ❔ Unlabelled

- feat: allow adding SSH authorized key for root (advanced settings) by @dsiebel [@MickLesk](https://github.com/MickLesk) ([#1456](https://github.com/community-scripts/ProxmoxVE/pull/1456))

## 2025-01-11

### Changed

### 🚀 Updated Scripts

- Prometheus: Fix installation via creating the service file [@andygrunwald](https://github.com/andygrunwald) ([#1416](https://github.com/community-scripts/ProxmoxVE/pull/1416))
- Update prometheus-install.sh: Service creation fix [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1417](https://github.com/community-scripts/ProxmoxVE/pull/1417))
- Update prometheus-alertmanager-install.sh: Service Creation Fix [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1418](https://github.com/community-scripts/ProxmoxVE/pull/1418))
- Fix: LubeLogger CT vehicle tag typo [@kkroboth](https://github.com/kkroboth) ([#1413](https://github.com/community-scripts/ProxmoxVE/pull/1413))

## 2025-01-10

### Changed

### ✨ New Scripts

- New script : Ghost [@fabrice1236](https://github.com/fabrice1236) ([#1361](https://github.com/community-scripts/ProxmoxVE/pull/1361))

### 🚀 Updated Scripts

- Fix user in ghost-cli install command [@fabrice1236](https://github.com/fabrice1236) ([#1408](https://github.com/community-scripts/ProxmoxVE/pull/1408))
- Update Prometheus + Alertmanager: Unify scripts for easier maintenance [@andygrunwald](https://github.com/andygrunwald) ([#1402](https://github.com/community-scripts/ProxmoxVE/pull/1402))
- Update komodo.sh: Fix broken paths in update_script(). [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1403](https://github.com/community-scripts/ProxmoxVE/pull/1403))
- Fix: ActualBudget Update-Function [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1376](https://github.com/community-scripts/ProxmoxVE/pull/1376))
- Fix: bookstack.sh - Ignore empty folder [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1388](https://github.com/community-scripts/ProxmoxVE/pull/1388))
- Fix: checkmk-install.sh: Version crawling. [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1385](https://github.com/community-scripts/ProxmoxVE/pull/1385))

### 🌐 Website

- Change Website-Category of nzbget [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1379](https://github.com/community-scripts/ProxmoxVE/pull/1379))

### 🧰 Maintenance

- Update check_and_update_json_date.yml: Change path to /json [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1399](https://github.com/community-scripts/ProxmoxVE/pull/1399))
- Visual Studio Code: Set Workspace recommended extensions [@andygrunwald](https://github.com/andygrunwald) ([#1398](https://github.com/community-scripts/ProxmoxVE/pull/1398))
- [core]: add support for custom tags [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1384](https://github.com/community-scripts/ProxmoxVE/pull/1384))
- [core]: check json date of new prs & update it [@MickLesk](https://github.com/MickLesk) ([#1395](https://github.com/community-scripts/ProxmoxVE/pull/1395))
- Add initial PR for Contributing & Coding Standard [@MickLesk](https://github.com/MickLesk) ([#920](https://github.com/community-scripts/ProxmoxVE/pull/920))
- [Core] add Github Action for Generate AppHeaders (figlet remove part 1) [@MickLesk](https://github.com/MickLesk) ([#1382](https://github.com/community-scripts/ProxmoxVE/pull/1382))

## 2025-01-09

### Changed

### 💥 Breaking Changes

- Removal calibre-server (no Headless Support) [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1362](https://github.com/community-scripts/ProxmoxVE/pull/1362))

### ✨ New Scripts

- New Script: Prometheus Alertmanager [@andygrunwald](https://github.com/andygrunwald) ([#1272](https://github.com/community-scripts/ProxmoxVE/pull/1272))
- New script: ps5-mqtt [@liecno](https://github.com/liecno) ([#1198](https://github.com/community-scripts/ProxmoxVE/pull/1198))

### 🚀 Updated Scripts

- Fix: AdventureLog: unzip to /opt/ [@JesperDramsch](https://github.com/JesperDramsch) ([#1370](https://github.com/community-scripts/ProxmoxVE/pull/1370))
- Fix: Stirling-PDF > LibreOffice/unoconv Integration Issues  [@m6urns](https://github.com/m6urns) ([#1322](https://github.com/community-scripts/ProxmoxVE/pull/1322))
- Fix: AdventureLog - update script bug [@JesperDramsch](https://github.com/JesperDramsch) ([#1334](https://github.com/community-scripts/ProxmoxVE/pull/1334))
- Install/update ActualBudget based on releases, not latest master [@SpyrosRoum](https://github.com/SpyrosRoum) ([#1254](https://github.com/community-scripts/ProxmoxVE/pull/1254))
- Fix Checkmk: Version grep broken [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1341](https://github.com/community-scripts/ProxmoxVE/pull/1341))

### 🧰 Maintenance

- fix: only validate scripts in validate-scripts workflow [@se-bastiaan](https://github.com/se-bastiaan) ([#1344](https://github.com/community-scripts/ProxmoxVE/pull/1344))

## 2025-01-08

### Changed

### 🌐 Website

- update postgresql json to add post install password setup [@rdiazlugo](https://github.com/rdiazlugo) ([#1318](https://github.com/community-scripts/ProxmoxVE/pull/1318))

### 🧰 Maintenance

- fix(ci): formatting event & chmod +x [@se-bastiaan](https://github.com/se-bastiaan) ([#1335](https://github.com/community-scripts/ProxmoxVE/pull/1335))
- fix: correctly handle pull_request_target event [@se-bastiaan](https://github.com/se-bastiaan) ([#1327](https://github.com/community-scripts/ProxmoxVE/pull/1327))

## 2025-01-07

### Changed

### 🚀 Updated Scripts

- Fix: Folder-Check for Updatescript Zammad [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1309](https://github.com/community-scripts/ProxmoxVE/pull/1309))

### 🧰 Maintenance

- fix: permissions of validate pipelines [@se-bastiaan](https://github.com/se-bastiaan) ([#1316](https://github.com/community-scripts/ProxmoxVE/pull/1316))
- Set Execution Rights for GH-Action: Validate Scripts [@MickLesk](https://github.com/MickLesk) ([#1312](https://github.com/community-scripts/ProxmoxVE/pull/1312))

## 2025-01-06

### Changed

### ✨ New Scripts

- New Script: Typesense [@tlissak](https://github.com/tlissak) ([#1291](https://github.com/community-scripts/ProxmoxVE/pull/1291))
- New script: GLPI [@opastorello](https://github.com/opastorello) ([#1201](https://github.com/community-scripts/ProxmoxVE/pull/1201))

### 🚀 Updated Scripts

- Fix Tag in HyperHDR Script [@MickLesk](https://github.com/MickLesk) ([#1299](https://github.com/community-scripts/ProxmoxVE/pull/1299))
- [Fix]: Fixed rm Bug in pf2etools [@MickLesk](https://github.com/MickLesk) ([#1292](https://github.com/community-scripts/ProxmoxVE/pull/1292))
- Fix: Homebox Update Script  [@MickLesk](https://github.com/MickLesk) ([#1284](https://github.com/community-scripts/ProxmoxVE/pull/1284))
- Add ca-certificates for Install (Frigate) [@MickLesk](https://github.com/MickLesk) ([#1282](https://github.com/community-scripts/ProxmoxVE/pull/1282))
- fix: buffer from base64 in formatting pipeline [@se-bastiaan](https://github.com/se-bastiaan) ([#1285](https://github.com/community-scripts/ProxmoxVE/pull/1285))

### 🧰 Maintenance

- Add reapproval of Changelog-PR [@MickLesk](https://github.com/MickLesk) ([#1279](https://github.com/community-scripts/ProxmoxVE/pull/1279))
- ci: combine header checks into workflow with PR comment [@se-bastiaan](https://github.com/se-bastiaan) ([#1257](https://github.com/community-scripts/ProxmoxVE/pull/1257))
- ci: change filename checks into steps with PR comment [@se-bastiaan](https://github.com/se-bastiaan) ([#1255](https://github.com/community-scripts/ProxmoxVE/pull/1255))
- ci: add pipeline for code formatting checks [@se-bastiaan](https://github.com/se-bastiaan) ([#1239](https://github.com/community-scripts/ProxmoxVE/pull/1239))

## 2025-01-05

### Changed

### 💥 Breaking Changes

- [Breaking] Update Zigbee2mqtt to v.2.0.0 (Read PR Description) [@MickLesk](https://github.com/MickLesk) ([#1221](https://github.com/community-scripts/ProxmoxVE/pull/1221))

### ❔ Unlabelled

- Add RAM and Disk units [@oOStroudyOo](https://github.com/oOStroudyOo) ([#1261](https://github.com/community-scripts/ProxmoxVE/pull/1261))

## 2025-01-04

### Changed

### 🚀 Updated Scripts

- Fix gpg key pf2tools & 5etools [@MickLesk](https://github.com/MickLesk) ([#1242](https://github.com/community-scripts/ProxmoxVE/pull/1242))
- Homarr: Fix missing curl dependency [@MickLesk](https://github.com/MickLesk) ([#1238](https://github.com/community-scripts/ProxmoxVE/pull/1238))
- Homeassistan Core: Fix Python3 and add missing dependencies [@MickLesk](https://github.com/MickLesk) ([#1236](https://github.com/community-scripts/ProxmoxVE/pull/1236))
- Fix: Update Python for HomeAssistant [@MickLesk](https://github.com/MickLesk) ([#1227](https://github.com/community-scripts/ProxmoxVE/pull/1227))
- OneDev: Add git-lfs [@MickLesk](https://github.com/MickLesk) ([#1225](https://github.com/community-scripts/ProxmoxVE/pull/1225))
- Pf2eTools & 5eTools: Fixing npm build [@TheRealVira](https://github.com/TheRealVira) ([#1213](https://github.com/community-scripts/ProxmoxVE/pull/1213))

### 🌐 Website

- Bump next from 15.0.2 to 15.1.3 in /frontend [@dependabot[bot]](https://github.com/dependabot[bot]) ([#1212](https://github.com/community-scripts/ProxmoxVE/pull/1212))

### 🧰 Maintenance

- [GitHub Action] Add filename case check [@quantumryuu](https://github.com/quantumryuu) ([#1228](https://github.com/community-scripts/ProxmoxVE/pull/1228))

## 2025-01-03

### Changed

### 🚀 Updated Scripts

- Improve Homarr Installation [@MickLesk](https://github.com/MickLesk) ([#1208](https://github.com/community-scripts/ProxmoxVE/pull/1208))
- Fix: Zabbix-Update Script [@MickLesk](https://github.com/MickLesk) ([#1205](https://github.com/community-scripts/ProxmoxVE/pull/1205))
- Update Script: Lazylibrarian [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1190](https://github.com/community-scripts/ProxmoxVE/pull/1190))
- Fix: Memos update function [@MickLesk](https://github.com/MickLesk) ([#1207](https://github.com/community-scripts/ProxmoxVE/pull/1207))
- Keep Lubelogger data after update to a new version [@JcMinarro](https://github.com/JcMinarro) ([#1200](https://github.com/community-scripts/ProxmoxVE/pull/1200))

### 🌐 Website

- Update Nextcloud-LXC JSON [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1191](https://github.com/community-scripts/ProxmoxVE/pull/1191))

### 🧰 Maintenance

- Github action to check metadata lines in scripts. [@quantumryuu](https://github.com/quantumryuu) ([#1110](https://github.com/community-scripts/ProxmoxVE/pull/1110))

## 2025-01-02

### Changed

### ✨ New Scripts

- New Script: Pf2eTools [@TheRealVira](https://github.com/TheRealVira) ([#1162](https://github.com/community-scripts/ProxmoxVE/pull/1162))
- New Script: 5etools [@TheRealVira](https://github.com/TheRealVira) ([#1157](https://github.com/community-scripts/ProxmoxVE/pull/1157))

### 🚀 Updated Scripts

- Update config template in blocky-install.sh [@xFichtl1](https://github.com/xFichtl1) ([#1059](https://github.com/community-scripts/ProxmoxVE/pull/1059))

## 2025-01-01

### Changed

### ✨ New Scripts

- New Script: Komodo [@MickLesk](https://github.com/MickLesk) ([#1167](https://github.com/community-scripts/ProxmoxVE/pull/1167))
- New Script: Firefly [@quantumryuu](https://github.com/quantumryuu) ([#616](https://github.com/community-scripts/ProxmoxVE/pull/616))
- New Script: Semaphore [@quantumryuu](https://github.com/quantumryuu) ([#596](https://github.com/community-scripts/ProxmoxVE/pull/596))

### 🚀 Updated Scripts

- Fix Script Homepage: add version during build step [@se-bastiaan](https://github.com/se-bastiaan) ([#1155](https://github.com/community-scripts/ProxmoxVE/pull/1155))
- Happy new Year! Update Copyright to 2025 [@MickLesk](https://github.com/MickLesk) ([#1150](https://github.com/community-scripts/ProxmoxVE/pull/1150))
- Update Kernel-Clean to new Version & Bugfixing [@MickLesk](https://github.com/MickLesk) ([#1147](https://github.com/community-scripts/ProxmoxVE/pull/1147))
- Fix chromium installation for ArchiveBox  [@tkunzfeld](https://github.com/tkunzfeld) ([#1140](https://github.com/community-scripts/ProxmoxVE/pull/1140))

### 🌐 Website

- Fix Category of Semaphore [@MickLesk](https://github.com/MickLesk) ([#1148](https://github.com/community-scripts/ProxmoxVE/pull/1148))

### 🧰 Maintenance

- Correctly check for changed files in Shellcheck workflow [@se-bastiaan](https://github.com/se-bastiaan) ([#1156](https://github.com/community-scripts/ProxmoxVE/pull/1156))

## 2024-12-31 - Happy new Year! 🎉✨

### Changed

### 💥 Breaking Changes

- Add ExecReload to prometheus.service [@BasixKOR](https://github.com/BasixKOR) ([#1131](https://github.com/community-scripts/ProxmoxVE/pull/1131))
- Fix: Figlet Version & Font Check [@MickLesk](https://github.com/MickLesk) ([#1133](https://github.com/community-scripts/ProxmoxVE/pull/1133))

### 🚀 Updated Scripts

- Fix: Copy issue after update in Bookstack LXC [@MickLesk](https://github.com/MickLesk) ([#1137](https://github.com/community-scripts/ProxmoxVE/pull/1137))
- Omada: Switch Base-URL to prevent issues [@MickLesk](https://github.com/MickLesk) ([#1135](https://github.com/community-scripts/ProxmoxVE/pull/1135))
- fix: guacd service not start during Apache-Guacamole script installation process [@PhoenixEmik](https://github.com/PhoenixEmik) ([#1122](https://github.com/community-scripts/ProxmoxVE/pull/1122))
- Fix Homepage-Script: Installation/Update [@MickLesk](https://github.com/MickLesk) ([#1129](https://github.com/community-scripts/ProxmoxVE/pull/1129))
- Netbox: Updating URL to https [@surajsbmn](https://github.com/surajsbmn) ([#1124](https://github.com/community-scripts/ProxmoxVE/pull/1124))

## 2024-12-30

### Changed

### 🚀 Updated Scripts

- [Archivebox] Fix wrong port being printed post install. [@Strana-Mechty](https://github.com/Strana-Mechty) ([#1105](https://github.com/community-scripts/ProxmoxVE/pull/1105))
- fix: add homepage version during build step [@se-bastiaan](https://github.com/se-bastiaan) ([#1107](https://github.com/community-scripts/ProxmoxVE/pull/1107))

### 🌐 Website

- Fix Trilium Website to TriliumNext [@tmkis2](https://github.com/tmkis2) ([#1103](https://github.com/community-scripts/ProxmoxVE/pull/1103))

## 2024-12-29

### Changed

### ✨ New Scripts

- New Script: Grist [@cfurrow](https://github.com/cfurrow) ([#1076](https://github.com/community-scripts/ProxmoxVE/pull/1076))
- New Script: TeddyCloud Server [@dsiebel](https://github.com/dsiebel) ([#1064](https://github.com/community-scripts/ProxmoxVE/pull/1064))

### 🚀 Updated Scripts

- Fix Install / Update on Grist Script [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#1091](https://github.com/community-scripts/ProxmoxVE/pull/1091))

### 🌐 Website

- fix: Update add-lxc-iptag.json warn to warning [@BramSuurdje](https://github.com/BramSuurdje) ([#1094](https://github.com/community-scripts/ProxmoxVE/pull/1094))

### 🧰 Maintenance

- Introduce editorconfig for more consistent formatting [@dsiebel](https://github.com/dsiebel) ([#1073](https://github.com/community-scripts/ProxmoxVE/pull/1073))

## 2024-12-28

### Changed

### 💥 Breaking Changes

- Add Figlet into Repo | Creation of local ASCII Header [@MickLesk](https://github.com/MickLesk) ([#1072](https://github.com/community-scripts/ProxmoxVE/pull/1072))
- Add an IP-Update for MOTD if IP Changed [@MickLesk](https://github.com/MickLesk) ([#1067](https://github.com/community-scripts/ProxmoxVE/pull/1067))

### 🚀 Updated Scripts

- Zabbix: Fix SQL Path for 7.2 [@MickLesk](https://github.com/MickLesk) ([#1069](https://github.com/community-scripts/ProxmoxVE/pull/1069))
- Authentik: added missing port to access url [@TheRealVira](https://github.com/TheRealVira) ([#1065](https://github.com/community-scripts/ProxmoxVE/pull/1065))

## 2024-12-27

### Changed

### ✨ New Scripts

- new scripts for Authentik [@remz1337](https://github.com/remz1337) ([#291](https://github.com/community-scripts/ProxmoxVE/pull/291))

### 🚀 Updated Scripts

- Add 8.0 for MongoDB Installation [@MickLesk](https://github.com/MickLesk) ([#1046](https://github.com/community-scripts/ProxmoxVE/pull/1046))
- Update Zabbix to 7.2. Release [@MickLesk](https://github.com/MickLesk) ([#1048](https://github.com/community-scripts/ProxmoxVE/pull/1048))
- Apache-Guacamole script bug fix [@sannier3](https://github.com/sannier3) ([#1039](https://github.com/community-scripts/ProxmoxVE/pull/1039))

### 🌐 Website

- Updated SAB documentation based on RAM increase [@TheRealVira](https://github.com/TheRealVira) ([#1035](https://github.com/community-scripts/ProxmoxVE/pull/1035))

### ❔ Unlabelled

- Patch Figlet Repo if missing [@MickLesk](https://github.com/MickLesk) ([#1044](https://github.com/community-scripts/ProxmoxVE/pull/1044))
- fix Tags for Advanced Settings [@MickLesk](https://github.com/MickLesk) ([#1042](https://github.com/community-scripts/ProxmoxVE/pull/1042))

## 2024-12-26

### Changed

### ✨ New Scripts

-  New Script: Jenkins [@quantumryuu](https://github.com/quantumryuu) ([#1019](https://github.com/community-scripts/ProxmoxVE/pull/1019))
- New Script: 2FAuth [@jkrgr0](https://github.com/jkrgr0) ([#943](https://github.com/community-scripts/ProxmoxVE/pull/943))

### 🚀 Updated Scripts

- ChangeDetection Update: Update also Browsers [@Niklas04](https://github.com/Niklas04) ([#1027](https://github.com/community-scripts/ProxmoxVE/pull/1027))
- ensure all RFC1918 local Ipv4 addresses are in iptag script [@AskAlice](https://github.com/AskAlice) ([#992](https://github.com/community-scripts/ProxmoxVE/pull/992))
- Fix Proxmox DataCenter: incorrect build.func url [@rbradley0](https://github.com/rbradley0) ([#1013](https://github.com/community-scripts/ProxmoxVE/pull/1013))

### 🧰 Maintenance

- [GitHub Actions] Introduce Shellcheck to check bash code [@andygrunwald](https://github.com/andygrunwald) ([#1018](https://github.com/community-scripts/ProxmoxVE/pull/1018))

## 2024-12-25

### Changed

### ✨ New Scripts

- add: pve-datacenter-manager [@CrazyWolf13](https://github.com/CrazyWolf13) ([#947](https://github.com/community-scripts/ProxmoxVE/pull/947))

### 🚀 Updated Scripts

- Fix Script: Alpine Nextcloud Upload File Size Limit [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#933](https://github.com/community-scripts/ProxmoxVE/pull/933))
- Doubled RAM for SAB [@TheRealVira](https://github.com/TheRealVira) ([#1007](https://github.com/community-scripts/ProxmoxVE/pull/1007))

## 2024-12-23

### Changed

### 🚀 Updated Scripts

- Fix Navidrome Update & Install [@MickLesk](https://github.com/MickLesk) ([#991](https://github.com/community-scripts/ProxmoxVE/pull/991))
- Update emby.sh to correct port [@Rageplant](https://github.com/Rageplant) ([#989](https://github.com/community-scripts/ProxmoxVE/pull/989))

## 2024-12-21

### Changed

### 🚀 Updated Scripts

- update Port in homeassistant-core CT [@fraefel](https://github.com/fraefel) ([#961](https://github.com/community-scripts/ProxmoxVE/pull/961))

## 2024-12-20

### Changed

### ✨ New Scripts

- New Script: Apache Guacamole [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#657](https://github.com/community-scripts/ProxmoxVE/pull/657))
- New Script: silverbullet [@dsiebel](https://github.com/dsiebel) ([#659](https://github.com/community-scripts/ProxmoxVE/pull/659))
- New Script: Zammad [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#640](https://github.com/community-scripts/ProxmoxVE/pull/640))
- New Script: CheckMk [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#926](https://github.com/community-scripts/ProxmoxVE/pull/926))

### 🚀 Updated Scripts

- Fix: Remove PHP Key generation in Bookstack Update [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#948](https://github.com/community-scripts/ProxmoxVE/pull/948))

### 🌐 Website

- Update checkmk description [@BramSuurdje](https://github.com/BramSuurdje) ([#954](https://github.com/community-scripts/ProxmoxVE/pull/954))
- Add Login Note for Checkmk [@MickLesk](https://github.com/MickLesk) ([#940](https://github.com/community-scripts/ProxmoxVE/pull/940))

### ❔ Unlabelled

- Update build.func to display the Proxmox Hostname [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#894](https://github.com/community-scripts/ProxmoxVE/pull/894))

## 2024-12-19

### Changed

### 🚀 Updated Scripts

- Fix: Bookstack Update Function [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#844](https://github.com/community-scripts/ProxmoxVE/pull/844))
- mysql not showing ip after install [@snow2k9](https://github.com/snow2k9) ([#924](https://github.com/community-scripts/ProxmoxVE/pull/924))
- Fix Omada - Crawling latest version [@MickLesk](https://github.com/MickLesk) ([#918](https://github.com/community-scripts/ProxmoxVE/pull/918))

### 🌐 Website

- Fix script path formatting in InstallMethod component [@BramSuurdje](https://github.com/BramSuurdje) ([#909](https://github.com/community-scripts/ProxmoxVE/pull/909))
- Fix Part-DB Docu (cred command) [@EvilBlood](https://github.com/EvilBlood) ([#898](https://github.com/community-scripts/ProxmoxVE/pull/898))
- Enhance Tooltip component by adding CircleHelp icon and fix instructions in script component [@BramSuurdje](https://github.com/BramSuurdje) ([#910](https://github.com/community-scripts/ProxmoxVE/pull/910))

## 2024-12-18

### Changed

### ✨ New Scripts

- New script: Part-DB LXC [@bvdberg01](https://github.com/bvdberg01) ([#591](https://github.com/community-scripts/ProxmoxVE/pull/591))

### 🚀 Updated Scripts

- Fix Kernel-Clean for Proxmox 8.x [@MickLesk](https://github.com/MickLesk) ([#904](https://github.com/community-scripts/ProxmoxVE/pull/904))
- [Frigate] Remove SSE 4.2 from instruction set supporting OpenVino [@remz1337](https://github.com/remz1337) ([#902](https://github.com/community-scripts/ProxmoxVE/pull/902))

### 🌐 Website

- New Metadata Category: "Coding & AI" [@newzealandpaul](https://github.com/newzealandpaul) ([#890](https://github.com/community-scripts/ProxmoxVE/pull/890))
- Moved Webmin to "Server & Networking" [@newzealandpaul](https://github.com/newzealandpaul) ([#891](https://github.com/community-scripts/ProxmoxVE/pull/891))

## 2024-12-17

### Changed

### 🚀 Updated Scripts

- Fix Alpine-Nextcloud: Bump PHP Version to 8.3 [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#865](https://github.com/community-scripts/ProxmoxVE/pull/865))
- Correction of Jellyfin CT Port [@mneten](https://github.com/mneten) ([#884](https://github.com/community-scripts/ProxmoxVE/pull/884))
- fix spinner on lxc-ip-tag [@MickLesk](https://github.com/MickLesk) ([#876](https://github.com/community-scripts/ProxmoxVE/pull/876))
- Fix Keycloak Installation [@MickLesk](https://github.com/MickLesk) ([#874](https://github.com/community-scripts/ProxmoxVE/pull/874))
- Fix ports ressources [@MickLesk](https://github.com/MickLesk) ([#867](https://github.com/community-scripts/ProxmoxVE/pull/867))

### 🧰 Maintenance

- Small Changes to the PR Template [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#862](https://github.com/community-scripts/ProxmoxVE/pull/862))

### ❔ Unlabelled

- calculate terminal size for header_info [@MickLesk](https://github.com/MickLesk) ([#879](https://github.com/community-scripts/ProxmoxVE/pull/879))
- Fix header creation with figlet for alpine [@MickLesk](https://github.com/MickLesk) ([#869](https://github.com/community-scripts/ProxmoxVE/pull/869))

## 2024-12-16

### Changed

### 💥 Breaking Changes

- Massive Update: build.func | install.func | create_lxc.sh (Part 1) [@MickLesk](https://github.com/MickLesk) ([#643](https://github.com/community-scripts/ProxmoxVE/pull/643))
- Update ALL CT's to new default (Part 2) [@MickLesk](https://github.com/MickLesk) ([#710](https://github.com/community-scripts/ProxmoxVE/pull/710))

### ✨ New Scripts

- New Script: LXC IP-Tag [@MickLesk](https://github.com/MickLesk) ([#536](https://github.com/community-scripts/ProxmoxVE/pull/536))

### 🚀 Updated Scripts

- Increase Size | Description & Download-URL of Debian VM [@MickLesk](https://github.com/MickLesk) ([#837](https://github.com/community-scripts/ProxmoxVE/pull/837))
- Update Script: Remove Docker Compose Question [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#847](https://github.com/community-scripts/ProxmoxVE/pull/847))

### 🌐 Website

- Bump nanoid from 3.3.7 to 3.3.8 in /frontend [@dependabot[bot]](https://github.com/dependabot[bot]) ([#845](https://github.com/community-scripts/ProxmoxVE/pull/845))

### ❔ Unlabelled

- Fix SSH root access in install.func [@havardthom](https://github.com/havardthom) ([#858](https://github.com/community-scripts/ProxmoxVE/pull/858))
- Fix variable name for CT_TYPE override [@remz1337](https://github.com/remz1337) ([#855](https://github.com/community-scripts/ProxmoxVE/pull/855))
- Keeps the same style after writing the SEARCH icon [@remz1337](https://github.com/remz1337) ([#851](https://github.com/community-scripts/ProxmoxVE/pull/851))

## 2024-12-13

### Changed

### 🚀 Updated Scripts

- Fix Keycloak Update Function [@MickLesk](https://github.com/MickLesk) ([#762](https://github.com/community-scripts/ProxmoxVE/pull/762))
- Fix config bug in Alpine Vaultwarden [@havardthom](https://github.com/havardthom) ([#775](https://github.com/community-scripts/ProxmoxVE/pull/775))

### 🌐 Website

- Change MISC from red to green [@MickLesk](https://github.com/MickLesk) ([#815](https://github.com/community-scripts/ProxmoxVE/pull/815))
- Update some JSON Files for Website [@MickLesk](https://github.com/MickLesk) ([#812](https://github.com/community-scripts/ProxmoxVE/pull/812))
- Update Notes & Documentation for Proxmox Backup Server [@MickLesk](https://github.com/MickLesk) ([#804](https://github.com/community-scripts/ProxmoxVE/pull/804))

### 🧰 Maintenance

- Github: Optimize Issue Template & PR Template [@MickLesk](https://github.com/MickLesk) ([#802](https://github.com/community-scripts/ProxmoxVE/pull/802))

## 2024-12-12

### Changed

### 🚀 Updated Scripts

- Update jellyfin.sh / Fix infinite loop [@gerpo](https://github.com/gerpo) ([#792](https://github.com/community-scripts/ProxmoxVE/pull/792))

### 🌐 Website

- Fix port and website in nextcloudpi.json [@PhoenixEmik](https://github.com/PhoenixEmik) ([#790](https://github.com/community-scripts/ProxmoxVE/pull/790))
- Add post-install note to mqtt.json [@havardthom](https://github.com/havardthom) ([#783](https://github.com/community-scripts/ProxmoxVE/pull/783))

### 🧰 Maintenance

- Filter pull requests on main branch in changelog-pr.yml [@havardthom](https://github.com/havardthom) ([#793](https://github.com/community-scripts/ProxmoxVE/pull/793))
- Fix Z-Wave JS UI Breaking Change in CHANGELOG.md [@havardthom](https://github.com/havardthom) ([#781](https://github.com/community-scripts/ProxmoxVE/pull/781))

## 2024-12-09

### Changed

### 🚀 Updated Scripts

- Fix PostgreSQL password bug in Umami install [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#750](https://github.com/community-scripts/ProxmoxVE/pull/750))

## 2024-12-08

### Changed

### 🚀 Updated Scripts

- Use MongoDB 4.4 in Unifi for non-AVX users [@havardthom](https://github.com/havardthom) ([#691](https://github.com/community-scripts/ProxmoxVE/pull/691))

### 🌐 Website

- Move homarr to Dashboards section [@CrazyWolf13](https://github.com/CrazyWolf13) ([#740](https://github.com/community-scripts/ProxmoxVE/pull/740))

## 2024-12-07

### Changed

### 🚀 Updated Scripts

- Zigbee2MQTT: Remove dev branch choice until v2.0.0 release [@havardthom](https://github.com/havardthom) ([#702](https://github.com/community-scripts/ProxmoxVE/pull/702))
- Fix Hoarder build failure by installing Chromium stable [@vhsdream](https://github.com/vhsdream) ([#723](https://github.com/community-scripts/ProxmoxVE/pull/723))

### 🌐 Website

- Bugfix: Include script name in website search [@havardthom](https://github.com/havardthom) ([#731](https://github.com/community-scripts/ProxmoxVE/pull/731))

### ❔ Unlabelled

- Fix broken build.func [@havardthom](https://github.com/havardthom) ([#736](https://github.com/community-scripts/ProxmoxVE/pull/736))

## 2024-12-06

### Changed

### 🚀 Updated Scripts

- Fix bugs in Komga update [@DysfunctionalProgramming](https://github.com/DysfunctionalProgramming) ([#717](https://github.com/community-scripts/ProxmoxVE/pull/717))
- Bookstack: Fix Update function composer [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#700](https://github.com/community-scripts/ProxmoxVE/pull/700))

### 🌐 Website

- fix: note component in json-editor getting out of focus when typing and revert theme switch animation [@BramSuurdje](https://github.com/BramSuurdje) ([#706](https://github.com/community-scripts/ProxmoxVE/pull/706))

### 🧰 Maintenance

- Update frontend CI/CD workflow [@havardthom](https://github.com/havardthom) ([#703](https://github.com/community-scripts/ProxmoxVE/pull/703))

## 2024-12-05

### Changed

### 🚀 Updated Scripts

- PostgreSQL: Change authentication method from peer to md5 for UNIX sockets [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#650](https://github.com/community-scripts/ProxmoxVE/pull/650))
- Fix stdout in unifi.sh [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#688](https://github.com/community-scripts/ProxmoxVE/pull/688))
- Fix `rm` bug in Vikunja update [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#692](https://github.com/community-scripts/ProxmoxVE/pull/692))

## 2024-12-04

### Changed

### 🚀 Updated Scripts

- Update Spelling 'Environment' in nginxproxymanager [@MathijsG](https://github.com/MathijsG) ([#676](https://github.com/community-scripts/ProxmoxVE/pull/676))

### 🌐 Website

- Update homepage.json documentation and website links [@patchmonkey](https://github.com/patchmonkey) ([#668](https://github.com/community-scripts/ProxmoxVE/pull/668))

## 2024-12-03

### Changed

### ✨ New Scripts

- New Script: Onedev [@quantumryuu](https://github.com/quantumryuu) ([#612](https://github.com/community-scripts/ProxmoxVE/pull/612))

### 🚀 Updated Scripts

- Script Update: SnipeIT [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#641](https://github.com/community-scripts/ProxmoxVE/pull/641))

## 2024-12-02

### Changed

### ✨ New Scripts

- New Script: Hoarder LXC [@vhsdream](https://github.com/vhsdream) ([#567](https://github.com/community-scripts/ProxmoxVE/pull/567))
- New script: SnipeIT LXC [@michelroegl-brunner](https://github.com/michelroegl-brunner) ([#538](https://github.com/community-scripts/ProxmoxVE/pull/538))
- New Script: Glance [@quantumryuu](https://github.com/quantumryuu) ([#595](https://github.com/community-scripts/ProxmoxVE/pull/595))
- New script: Unbound LXC [@wimb0](https://github.com/wimb0) ([#547](https://github.com/community-scripts/ProxmoxVE/pull/547))
- New script: Mylar3 LXC [@davalanche](https://github.com/davalanche) ([#554](https://github.com/community-scripts/ProxmoxVE/pull/554))

### 🚀 Updated Scripts

- Stirling-PDF: replace dependency for v0.35.0 and add check and fix in stirling-pdf.sh [@vhsdream](https://github.com/vhsdream) ([#614](https://github.com/community-scripts/ProxmoxVE/pull/614))
- qbittorrent: do not override the configuration port in systemd [@zdraganov](https://github.com/zdraganov) ([#618](https://github.com/community-scripts/ProxmoxVE/pull/618))

### 🌐 Website

- chore: Update unbound logo to have only the actual logo [@BramSuurdje](https://github.com/BramSuurdje) ([#648](https://github.com/community-scripts/ProxmoxVE/pull/648))
- fix: vaultwarden info mismatch [@BramSuurdje](https://github.com/BramSuurdje) ([#645](https://github.com/community-scripts/ProxmoxVE/pull/645))
- Wallos json fix [@quantumryuu](https://github.com/quantumryuu) ([#630](https://github.com/community-scripts/ProxmoxVE/pull/630))

## 2024-11-30

### Changed

### 🚀 Updated Scripts

- Convert line endings in the-lounge.sh [@jamezpolley](https://github.com/jamezpolley) ([#599](https://github.com/community-scripts/ProxmoxVE/pull/599))

### 🌐 Website

- add some Information for Monitor-All Script [@MickLesk](https://github.com/MickLesk) ([#605](https://github.com/community-scripts/ProxmoxVE/pull/605))

## 2024-11-29

### Changed

### ✨ New Scripts

- New Script: The Lounge IRC [@quantumryuu](https://github.com/quantumryuu) ([#571](https://github.com/community-scripts/ProxmoxVE/pull/571))
- New Script: LubeLogger [@quantumryuu](https://github.com/quantumryuu) ([#574](https://github.com/community-scripts/ProxmoxVE/pull/574))
- New Script: Inspircd [@quantumryuu](https://github.com/quantumryuu) ([#576](https://github.com/community-scripts/ProxmoxVE/pull/576))

### 🚀 Updated Scripts

- Fix msg_error on zwave-js-ui [@MickLesk](https://github.com/MickLesk) ([#585](https://github.com/community-scripts/ProxmoxVE/pull/585))
- Fix Kimai Apache2 Rights [@MickLesk](https://github.com/MickLesk) ([#577](https://github.com/community-scripts/ProxmoxVE/pull/577))

## 2024-11-28

### Changed

### 💥 Breaking Changes

- Fix Z-Wave JS UI script [@MickLesk](https://github.com/MickLesk) ([#546](https://github.com/community-scripts/ProxmoxVE/pull/546))
  - [Migration guide](https://github.com/community-scripts/ProxmoxVE/discussions/635)

### 🚀 Updated Scripts

- Add vitest, add json validation tests, fix broken json files [@havardthom](https://github.com/havardthom) ([#566](https://github.com/community-scripts/ProxmoxVE/pull/566))
- Add update script to Pocketbase [@dsiebel](https://github.com/dsiebel) ([#535](https://github.com/community-scripts/ProxmoxVE/pull/535))
- Fix MongoDB install in Unifi script [@havardthom](https://github.com/havardthom) ([#564](https://github.com/community-scripts/ProxmoxVE/pull/564))
- Remove changing DISK_REF for zfspool mikrotik-routeros.sh [@tjcomserv](https://github.com/tjcomserv) ([#529](https://github.com/community-scripts/ProxmoxVE/pull/529))

### 🌐 Website

- Show Changelog on Mobile Devices [@MickLesk](https://github.com/MickLesk) ([#558](https://github.com/community-scripts/ProxmoxVE/pull/558))

## 2024-11-27

### Changed

### 💥 Breaking Changes

- Zabbix: Use Agent2 as Default | Update Script added | some other Improvements [@MickLesk](https://github.com/MickLesk) ([#527](https://github.com/community-scripts/ProxmoxVE/pull/527))

### 🚀 Updated Scripts

- Fix: install mosquitto from mosquitto repo [@dsiebel](https://github.com/dsiebel) ([#534](https://github.com/community-scripts/ProxmoxVE/pull/534))
- Patch Netbird Script | Container Boot-Check | Debian/Ubuntu Only [@MickLesk](https://github.com/MickLesk) ([#528](https://github.com/community-scripts/ProxmoxVE/pull/528))
- Install MongoDB 4.2 for non-AVX CPUs in Unifi LXC [@ColinOppenheim](https://github.com/ColinOppenheim) ([#319](https://github.com/community-scripts/ProxmoxVE/pull/319))

### 🌐 Website

- Fix json error in zabbix.json [@havardthom](https://github.com/havardthom) ([#543](https://github.com/community-scripts/ProxmoxVE/pull/543))
- Fix another json error in add-netbird-lxc.json [@havardthom](https://github.com/havardthom) ([#545](https://github.com/community-scripts/ProxmoxVE/pull/545))

## 2024-11-26

### Changed

### 🚀 Updated Scripts

- Fix Vikunja install script to prevent database deletion upon updating [@vhsdream](https://github.com/vhsdream) ([#524](https://github.com/community-scripts/ProxmoxVE/pull/524))

## 2024-11-25

### Changed

### 💥 Breaking Changes

- Remove Scrypted script [@MickLesk](https://github.com/MickLesk) ([#511](https://github.com/community-scripts/ProxmoxVE/pull/511))
  - Because of request from Scrypted maintainer: [#494](https://github.com/community-scripts/ProxmoxVE/issues/494)
  - Official Scrypted script can be used instead: https://docs.scrypted.app/installation.html#proxmox-ve

### 🚀 Updated Scripts

- Fix bugs in Calibre-Web update [@havardthom](https://github.com/havardthom) ([#517](https://github.com/community-scripts/ProxmoxVE/pull/517))
- Fix upload folder in listmonk LXC [@bvdberg01](https://github.com/bvdberg01) ([#515](https://github.com/community-scripts/ProxmoxVE/pull/515))

### 🌐 Website

- Fix website url in Zoraxy documentation [@miggi92](https://github.com/miggi92) ([#506](https://github.com/community-scripts/ProxmoxVE/pull/506))

## 2024-11-24

### Changed

### ✨ New Scripts

- New script: listmonk LXC [@bvdberg01](https://github.com/bvdberg01) ([#442](https://github.com/community-scripts/ProxmoxVE/pull/442))

### 🧰 Maintenance

- Add release title to github-release.yml [@havardthom](https://github.com/havardthom) ([#481](https://github.com/community-scripts/ProxmoxVE/pull/481))

## 2024-11-23

### Changed

### 🚀 Updated Scripts

- Fix Actual Budget install missing build tools [@cour64](https://github.com/cour64) ([#455](https://github.com/community-scripts/ProxmoxVE/pull/455))
- Fix Vikunja Update [@MickLesk](https://github.com/MickLesk) ([#440](https://github.com/community-scripts/ProxmoxVE/pull/440))
- Patch PostInstall-Script to PVE 8.3 | Add PVE 8.3 in Security [@MickLesk](https://github.com/MickLesk) ([#431](https://github.com/community-scripts/ProxmoxVE/pull/431))

### 🌐 Website

- Frontend: fix reported issue with json-editor page and add OS select in installmethod [@BramSuurdje](https://github.com/BramSuurdje) ([#426](https://github.com/community-scripts/ProxmoxVE/pull/426))
- Fixed Typo [@BenBakDev](https://github.com/BenBakDev) ([#441](https://github.com/community-scripts/ProxmoxVE/pull/441))

### 🧰 Maintenance

- Fix newline issue in changelog pr [@havardthom](https://github.com/havardthom) ([#474](https://github.com/community-scripts/ProxmoxVE/pull/474))
- Remove newline in changelog-pr action [@havardthom](https://github.com/havardthom) ([#461](https://github.com/community-scripts/ProxmoxVE/pull/461))
- Add action that creates github release based on CHANGELOG.md [@havardthom](https://github.com/havardthom) ([#462](https://github.com/community-scripts/ProxmoxVE/pull/462))

## 2024-11-21

### Changed

### ✨ New Scripts

- Add new LXC: NextPVR [@MickLesk](https://github.com/MickLesk) ([#391](https://github.com/community-scripts/ProxmoxVE/pull/391))
- Add new LXC: Kimai [@MickLesk](https://github.com/MickLesk) ([#397](https://github.com/community-scripts/ProxmoxVE/pull/397))

### 🚀 Updated Scripts

- Add .env file support for HomeBox [@404invalid-user](https://github.com/404invalid-user) ([#383](https://github.com/community-scripts/ProxmoxVE/pull/383))
- RDTClient Remove .NET 8.0 | Add .NET 9.0 [@MickLesk](https://github.com/MickLesk) ([#413](https://github.com/community-scripts/ProxmoxVE/pull/413))
- Remove old resource message from vaultwarden [@havardthom](https://github.com/havardthom) ([#402](https://github.com/community-scripts/ProxmoxVE/pull/402))

### 🌐 Website

- Add PostInstall Documentation to zigbee2mqtt.json [@MickLesk](https://github.com/MickLesk) ([#411](https://github.com/community-scripts/ProxmoxVE/pull/411))
- Fix incorrect hdd values in json files [@havardthom](https://github.com/havardthom) ([#403](https://github.com/community-scripts/ProxmoxVE/pull/403))
- Website: Add discord link to navbar [@BramSuurdje](https://github.com/BramSuurdje) ([#405](https://github.com/community-scripts/ProxmoxVE/pull/405))

### 🧰 Maintenance

- Use github app in changelog-pr.yml and add auto approval [@havardthom](https://github.com/havardthom) ([#416](https://github.com/community-scripts/ProxmoxVE/pull/416))

## 2024-11-20

### Changed

### 🚀 Updated Scripts

- LinkWarden: Moved PATH into service [@newzealandpaul](https://github.com/newzealandpaul) ([#376](https://github.com/community-scripts/ProxmoxVE/pull/376))

### 🌐 Website

- Replace dash "-" with "/" in metadata [@newzealandpaul](https://github.com/newzealandpaul) ([#374](https://github.com/community-scripts/ProxmoxVE/pull/374))
- Proxmox VE Cron LXC Updater: Add tteck's notes. [@newzealandpaul](https://github.com/newzealandpaul) ([#378](https://github.com/community-scripts/ProxmoxVE/pull/378))

## 2024-11-19

### Changed

### 🚀 Updated Scripts

- Fix Wallos Update [@MickLesk](https://github.com/MickLesk) ([#339](https://github.com/community-scripts/ProxmoxVE/pull/339))
- Linkwarden: Move Secret Key above in install.sh [@MickLesk](https://github.com/MickLesk) ([#356](https://github.com/community-scripts/ProxmoxVE/pull/356))
- Linkwarden: add gnupg to installed dependencies [@erfansamandarian](https://github.com/erfansamandarian) ([#349](https://github.com/community-scripts/ProxmoxVE/pull/349))

### 🌐 Website

- Add *Arr Suite category for Website [@MickLesk](https://github.com/MickLesk) ([#370](https://github.com/community-scripts/ProxmoxVE/pull/370))
- Refactor Buttons component to use a ButtonLink for cleaner code, simplifying the source URL generation and layout [@BramSuurdje](https://github.com/BramSuurdje) ([#371](https://github.com/community-scripts/ProxmoxVE/pull/371))

### 🧰 Maintenance

- [github]: add new Frontend_Report / Issue_Report & optimize config.yml [@MickLesk](https://github.com/MickLesk) ([#226](https://github.com/community-scripts/ProxmoxVE/pull/226))
- [chore] Update FUNDING.yml [@MickLesk](https://github.com/MickLesk) ([#352](https://github.com/community-scripts/ProxmoxVE/pull/352))

## 2024-11-18

### Changed

### 💥 Breaking Changes

- Massive Update - Remove old storage check, add new storage and resource check to all scripts - Remove downscaling with pct set [@MickLesk](https://github.com/MickLesk) ([#333](https://github.com/community-scripts/ProxmoxVE/pull/333))

### ✨ New Scripts

- new scripts for NetBox [@bvdberg01](https://github.com/bvdberg01) ([#308](https://github.com/community-scripts/ProxmoxVE/pull/308))

### 🚀 Updated Scripts

- Support SSE 4.2 in Frigate script [@anishp55](https://github.com/anishp55) ([#328](https://github.com/community-scripts/ProxmoxVE/pull/328))
- Bugfix: Wallos Patch (Cron Log & Media Backup)  [@MickLesk](https://github.com/MickLesk) ([#331](https://github.com/community-scripts/ProxmoxVE/pull/331))
- Linkwarden - Harmonize Script, Add Monolith & Bugfixing [@MickLesk](https://github.com/MickLesk) ([#306](https://github.com/community-scripts/ProxmoxVE/pull/306))
- Fix optional installs in Cockpit LXC [@havardthom](https://github.com/havardthom) ([#317](https://github.com/community-scripts/ProxmoxVE/pull/317))

### 🌐 Website

- Added additional instructions to nginxproxymanager [@newzealandpaul](https://github.com/newzealandpaul) ([#329](https://github.com/community-scripts/ProxmoxVE/pull/329))

### 🧰 Maintenance

- Verify changes before commit in changelog-pr.yml [@havardthom](https://github.com/havardthom) ([#310](https://github.com/community-scripts/ProxmoxVE/pull/310))

## 2024-11-17

### Changed

### ✨ New Scripts

- Add Komga LXC [@DysfunctionalProgramming](https://github.com/DysfunctionalProgramming) ([#275](https://github.com/community-scripts/ProxmoxVE/pull/275))

### 🚀 Updated Scripts

- Tweak: Patch Prometheus for v.3.0.0 [@MickLesk](https://github.com/MickLesk) ([#300](https://github.com/community-scripts/ProxmoxVE/pull/300))
- Wavelog - Small Adjustment [@HB9HIL](https://github.com/HB9HIL) ([#292](https://github.com/community-scripts/ProxmoxVE/pull/292))

### 🌐 Website

- Add Note for Komga Installation (Website)  [@MickLesk](https://github.com/MickLesk) ([#303](https://github.com/community-scripts/ProxmoxVE/pull/303))
- Fix Komga logo [@havardthom](https://github.com/havardthom) ([#298](https://github.com/community-scripts/ProxmoxVE/pull/298))

### 🧰 Maintenance

- Add github workflow for automatic changelog PR  [@havardthom](https://github.com/havardthom) ([#299](https://github.com/community-scripts/ProxmoxVE/pull/299))
- Use website label in autolabeler [@havardthom](https://github.com/havardthom) ([#297](https://github.com/community-scripts/ProxmoxVE/pull/297))

## 2024-11-16

### Changed

- **Recyclarr LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/recyclarr-install.sh)
  - NEW Script
- **Wavelog LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/wavelog-install.sh)
  - NEW Script
- **Vaultwarden LXC:** RAM has now been increased to 6144 MB [(PR)](https://github.com/community-scripts/ProxmoxVE/pull/285)
  - Breaking Change


## 2024-11-05

### Changed

- **Bookstack LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/bookstack-install.sh)
  - NEW Script
- **Vikunja LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/vikunja-install.sh)
  - NEW Script

## 2024-11-04

### Breaking Change
- **Automatic Update of Repository:** The update function now uses the new repository `community-scripts/ProxmoxVE` for Debian/Ubuntu LXC containers.
  
  ```bash
  bash -c "$(curl -fsSL https://github.com/community-scripts/ProxmoxVE/raw/main/misc/update-repo.sh)"

## 2024-10-31

### Changed

- **NZBGet LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/nzbget-install.sh)
  - NEW Script
- **Memos LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/memos-install.sh)
  - NEW Script

## 2024-10-27

### Changed

- **Open WebUI LXC** [(Commit)](https://github.com/community-scripts/ProxmoxVE/commit/8a21f6e7f025a911865395d4c0fa9a001bd0d512)
  - Refactor Script to add an option to install Ollama.

## 2024-10-26

### Changed

- **AdventureLog LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/adventurelog-install.sh)
  - NEW Script

## 2024-10-25

### Changed

- **Zoraxy LXC** [(Commit)](https://github.com/community-scripts/ProxmoxVE/commit/468a5d367ded4cf453a1507452e112ac3e234e2a)
  - Switch built from source to a pre-compiled binary version.
  - Breaking Change

## 2024-10-23

### Changed

- **Wallos LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/wallos-install.sh)
  - NEW Script
- **Open WebUI LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/openwebui-install.sh)
  - NEW Script

## 2024-10-19

### Changed

- **Cockpit LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/cockpit-install.sh)
  - NEW Script
- **Neo4j LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/neo4j-install.sh)
  - NEW Script

## 2024-10-18

### Changed

- **ArchiveBox LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/archivebox-install.sh)
  - NEW Script

## 2024-10-15

### Changed

- **evcc LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/evcc-install.sh)
  - NEW Script

## 2024-10-10

### Changed

- **MySQL LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/mysql-install.sh)
  - NEW Script
- **Tianji LXC** [(Commit)](https://github.com/community-scripts/ProxmoxVE/commit/4c83a790ac9b040da1f11ad2cbe13d3fc5f480e9)
  - Breaking Change
  - Switch from `pm2` process management to `systemd`

## 2024-10-03

### Changed

- **Home Assistant Core LXC** [(Commit)](https://github.com/community-scripts/ProxmoxVE/commit/f2937febe69b2bad8b3a14eb84aa562a8f14cc6a) [(Commit)](https://github.com/community-scripts/ProxmoxVE/commit/f2966ced7f457fd506f865f7f5b70ea12c4b0049)
  - Refactor Code
  - Breaking Change
  - Home Assistant has transitioned to using `uv` for managing the virtual environment and installing additional modules.

## 2024-09-16

### Changed

- **HomeBox LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/homebox-install.sh)
  - NEW Script
- **Zipline LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/zipline-install.sh)
  - NEW Script

## 2024-09-13

### Changed

- **Tianji LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/tianji-install.sh)
  - NEW Script

## 2024-08-21

### Changed

- **WireGuard LXC** [(Commit)](https://github.com/community-scripts/ProxmoxVE/commit/723365a79df7cc0fd29b1af8f7ef200a7e0921b1)
  - Refactor Code
  - Breaking Change

## 2024-08-19

### Changed

- **CommaFeed LXC** [(Commit)](https://github.com/community-scripts/ProxmoxVE/commit/0a33d1739ec3a49011411929bd46a260e92e99f9)
  - Refactor Code
  - Breaking Change

## 2024-08-06

### Changed

- **lldap LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/lldap-install.sh)
  - NEW Script

## 2024-07-26

### Changed

- **Gitea LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/gitea-install.sh)
  - NEW Script

## 2024-06-30

### Changed

- **All Scripts** [(Commit)](https://github.com/community-scripts/ProxmoxVE/commit/39ea1d4a20b83c07d084ebafdc811eec3548f289)
  - Requires Proxmox Virtual Environment version 8.1 or later.

## 2024-06-27

### Changed

- **Kubo LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/kubo-install.sh)
  - NEW Script
- **RabbitMQ LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/rabbitmq-install.sh)
  - NEW Script
- **Scrutiny LXC**
  - Removed from website, broken.

## 2024-06-26

### Changed

- **Scrutiny LXC**
  - NEW Script

## 2024-06-14

### Changed

- **MySpeed LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/myspeed-install.sh)
  - NEW Script

## 2024-06-13

### Changed

- **PeaNUT LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/peanut-install.sh)
  - NEW Script
- **Website**
  - If the Changelog has changed recently, the link on the website will pulse.
- **Spoolman LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/spoolman-install.sh)
  - NEW Script

## 2024-06-12

### Changed

- **MeTube LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/metube-install.sh)
  - NEW Script
- **Matterbridge LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/matterbridge-install.sh)
  - NEW Script
- **Website**
  - Reopen the gh-pages site (https://tteck.github.io/Proxmox/) 

## 2024-06-11

### Changed

- **Zabbix LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/zabbix-install.sh)
  - NEW Script

## 2024-06-06

### Changed

- **Petio LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/petio-install.sh)
  - NEW Script
- **Website**
  - Important notices will now be displayed on the landing page.

## 2024-06-04

### Changed

- **FlareSolverr LXC** [(View Source)](https://github.com/community-scripts/ProxmoxVE/blob/main/install/flaresolverr-install.sh)
  - NEW Script

## 2024-05-31

### Changed

- **Advanced Settings** [(Commit)](https://github.com/community-scripts/ProxmoxVE/commit/fc9dff220b4ea426d3a75178ad8accacae4683ca)
  - Passwords are now masked

## 2024-05-30

### Changed

- **Forgejo LXC**
  - NEW Script

## 2024-05-28

### Changed

- **Notifiarr LXC**
  - NEW Script

## 2024-05-25

### Changed

- **Threadfin LXC**
  - NEW Script

## 2024-05-23

### Changed

- **BunkerWeb LXC**
  - NEW Script

## 2024-05-20

### Changed

- **Traefik LXC**
  - NEW Script

## 2024-05-19

### Changed

- **NetBird**
  - NEW Script
- **Tailscale**
  - Refactor Code

## 2024-05-18

### Changed

- **MongoDB LXC**
  - NEW Script

## 2024-05-17

### Changed

- **New Website**
  - We have officially moved to [Helper-Scripts.com](https://helper-scripts.com)

## 2024-05-16

### Changed

- **iVentoy LXC**
  - NEW Script

## 2024-05-13

### Changed

- **Headscale LXC**
  - NEW Script

## 2024-05-11

### Changed

- **Caddy LXC**
  - NEW Script

## 2024-05-09

### Changed

- **Umami LXC**
  - NEW Script

## 2024-05-08

### Changed

- **Kernel Pin**
  - NEW Script
- **Home Assistant Core LXC**
  - Ubuntu 24.04 ONLY

## 2024-05-07

### Changed

- **Pocketbase LXC**
  - NEW Script

## 2024-05-05

### Changed

- **Fenrus LXC**
  - NEW Script

## 2024-05-02

### Changed

- **OpenMediaVault LXC**
  - Set Debian 12 as default
  - OpenMediaVault 7 (sandworm)

## 2024-04-30

### Changed

- **Tdarr LXC**
  - Default settings are now **Unprivileged**
  - Unprivileged Hardware Acceleration

## 2024-04-29

### Changed

- **ErsatzTV LXC**
  - NEW Script

## 2024-04-28

### Changed

- **Scrypted LXC**
  - Unprivileged Hardware Acceleration
- **Emby LXC**
  - Unprivileged Hardware Acceleration

## 2024-04-27

### Changed

- **Frigate LXC**
  - Unprivileged Hardware Acceleration https://github.com/tteck/Proxmox/discussions/2711#discussioncomment-9244629
- **Ubuntu 24.04 VM**
  - NEW Script

## 2024-04-26

### Changed

- **Glances**
  - NEW Script

## 2024-04-25

### Changed

- **Jellyfin LXC**
  - Default settings are now **Unprivileged**
  - Unprivileged Hardware Acceleration
  - Groups are set automatically
  - Checks for the existence of `/dev/dri/card0` if not found, use `/dev/dri/card1`. Set the GID to `44`
  - Set the GID for `/dev/dri/renderD128` to `104`
  - Not tested <8.1.11
- **Plex LXC**
  - Default settings are now **Unprivileged**
  - Unprivileged Hardware Acceleration
  - Groups are set automatically
  - Checks for the existence of `/dev/dri/card0` if not found, use `/dev/dri/card1`. Set the GID to `44`
  - Set the GID for `/dev/dri/renderD128` to `104`
  - Not tested <8.1.11

## 2024-04-24

### Changed

- **Traccar LXC**
  - NEW Script
- **Calibre-Web LXC**
  - NEW Script

## 2024-04-21

### Changed

- **Aria2 LXC**
  - NEW Script

## 2024-04-15

### Changed

- **Homarr LXC**
  - Add back to website
- **Umbrel LXC**
  - Add back to website
- **OpenMediaVault LXC**
  - Add back to website

## 2024-04-12

### Changed

- **OpenMediaVault LXC**
  - Removed from website

## 2024-04-09

### Changed

- **PairDrop LXC**
  - Add back to website

## 2024-04-05

### Changed

- **Medusa LXC**
  - NEW Script
- **WatchYourLAN LXC**
  - NEW Script

## 2024-04-04

### Changed

- **Actual Budget LXC**
  - NEW Script

## 2024-04-03

### Changed

- **LazyLibrarian LXC**
  - NEW Script

## 2024-04-01

### Changed

- **Frigate LXC**
  - NEW Script

## 2024-03-26

### Changed

- **MediaMTX LXC**
  - NEW Script

## 2024-03-25

### Changed

- **Proxmox VE Post Install**
  - ~Requires Proxmox Virtual Environment Version 8.1.1 or later.~
  - Requires Proxmox Virtual Environment Version 8.0 or later.
- **Proxmox Backup Server LXC**
  - NEW Script

## 2024-03-24

### Changed

- **SmokePing LXC**
  - NEW Script

## 2024-03-13

### Changed

- **FlowiseAI LXC**
  - NEW Script

## 2024-03-11

### Changed

- **Wastebin LXC**
  - NEW Script

## 2024-03-08

### Changed

- **Proxmox VE Post Install**
  - Requires Proxmox Virtual Environment Version 8.1.1 or later.

## 2024-02-26

### Changed

- **Mafl LXC**
  - NEW Script

## 2024-02-23

### Changed

- **Tandoor Recipes LXC**
  - NEW Script (Thanks @MickLesk)

## 2024-02-21

### Changed

- **All scripts**
  - As of today, the scripts require the Bash shell specifically. ([more info](https://github.com/tteck/Proxmox/discussions/2536))

## 2024-02-19

### Changed

- **PairDrop LXC**
  - Removed from the website ([more info](https://github.com/tteck/Proxmox/discussions/2516))

## 2024-02-16

### Changed

- **Proxmox VE LXC Filesystem Trim**
  - NEW Script ([more info](https://github.com/tteck/Proxmox/discussions/2505#discussion-6226037))

## 2024-02-11

### Changed

- **HiveMQ CE LXC**
  - NEW Script
- **Apache-CouchDB LXC**
  - NEW Script

## 2024-02-06

### Changed

- **All Scripts**
  - The scripts will only work with PVE7 Version 7.4-13 or later, or PVE8 Version 8.1.1 or later.

## 2024-02-05

### Changed

- **Gokapi LXC**
  - NEW Script
- **Nginx Proxy Manager LXC**
  - Option to install v2.10.4

## 2024-02-04

### Changed

- **Pi-hole LXC**
  - Option to add Unbound

## 2024-02-02

### Changed

- **Readeck LXC**
  - NEW Script

## 2024-01-25

### Changed

- **PairDrop LXC**
  - NEW Script

## 2024-01-20

### Changed

- **Apache-Cassandra LXC**
  - NEW Script
- **Redis LXC**
  - NEW Script

## 2024-01-17

### Changed

- **ntfy LXC**
  - NEW Script
- **HyperHDR LXC**
  - NEW Script

## 2024-01-16

### Changed

- **Website Improvements**
  - Refine and correct pointers.
  - Change hover colors to intuitively indicate categories/items.
  - Implement opening links in new tabs for better navigation.
  - Enhance the Copy button to better indicate that the command has been successfully copied.
  - Introduce a Clear Search button.
  - While not directly related to the website, it's worth mentioning that the logo in newly created LXC notes now serves as a link to the website, conveniently opening in a new tab.

## 2024-01-12

### Changed

- **Apt-Cacher-NG LXC**
  - NEW Script
- **New Feature**
  - The option to utilize Apt-Cacher-NG (Advanced settings) when creating LXCs. The added functionality is expected to decrease bandwidth usage and expedite package installation and updates. https://github.com/tteck/Proxmox/discussions/2332

## 2024-01-09

### Changed

- **Verbose mode**
  - Only entries with `$STD` will be shown

## 2024-01-07

### Changed

- **Stirling-PDF LXC**
  - NEW Script
- **SFTPGo LXC**
  - NEW Script

## 2024-01-04

### Changed

- **CommaFeed LXC**
  - NEW Script

## 2024-01-03

### Changed

- **Sonarr LXC**
  - Breaking Change
  - Complete recode
  - https://github.com/tteck/Proxmox/discussions/1738#discussioncomment-8005107

## 2024-01-01

### Changed

- **Gotify LXC**
  - NEW Script

## 2023-12-19

### Changed

- **Proxmox VE Netdata**
  - NEW Script

## 2023-12-10

### Changed

- **Homarr LXC**
  - Removed, again.

## 2023-12-02

### Changed

- **Runtipi LXC**
  - NEW Script

## 2023-12-01

### Changed

- **Mikrotik RouterOS VM**
  - Now Mikrotik RouterOS CHR VM
  - code refactoring
  - update to CHR
  - thanks to @NiccyB
- **Channels DVR Server LXC**
  - NEW Script

## 2023-11-19

### Changed

- **Dockge LXC**
  - NEW Script

## 2023-11-18

### Changed

- **Ubuntu 22.04 VM**
  - NEW Script

## 2023-11-14

### Changed

- **TurnKey Nextcloud VM**
  - NEW Script
- **TurnKey ownCloud VM**
  - NEW Script

## 2023-11-11

### Changed

- **Homarr LXC**
  - Returns with v0.14.0 (The authentication update).

## 2023-11-9

### Changed

- **AgentDVR LXC**
  - NEW Script

## 2023-11-8

### Changed

- **Linkwarden LXC**
  - NEW Script

## 2023-11-2

### Changed

- **PhotoPrism LXC**
  - Transitioned to PhotoPrism's latest installation package, featuring Linux binaries.

## 2023-11-1

### Changed

- **Owncast LXC**
  - NEW Script

## 2023-10-31

### Changed

- **Debian 12 VM**
  - NEW Script

## 2023-10-29

### Changed

- **Unmanic LXC**
  - NEW Script

## 2023-10-27

### Changed

- **Webmin**
  - A full code overhaul.

## 2023-10-15

### Changed

- **TasmoAdmin LXC**
  - NEW Script

## 2023-10-14

### Changed

- **Sonarr LXC**
  - Include an option to install v4 (experimental)

## 2023-10-11

### Changed

- **Proxmox VE CPU Scaling Governor**
  - A full code overhaul.
  - Include an option to configure a crontab for ensuring that the CPU Scaling Governor configuration persists across reboots.

## 2023-10-08

### Changed

- **Proxmox VE LXC Updater**
  - Now displays which containers require a reboot.
- **File Browser**
  - Uninstall by re-executing the script
  - Option to use No Authentication

## 2023-10-05

### Changed

- **Pingvin Share LXC**
  - NEW Script

## 2023-09-30

### Changed

- **All Templates**
  - NEW Script

## 2023-09-28

### Changed

- **Alpine Nextcloud Hub LXC**
  - NEW Script (Thanks to @nicedevil007)

## 2023-09-14

### Changed

- **Proxmox VE Processor Microcode**
  - Allow users to select available microcode packages.

## 2023-09-13

### Changed

- **Pi.Alert LXC**
  - NEW Script
- **Proxmox VE Kernel Clean**
  - Code overhaul with a fresh start. This script offers the flexibility to select specific kernels for removal, unlike the previous version, which was an all-or-nothing approach.

## 2023-09-11

### Changed

- **Paperless-ngx LXC**
  - Modify the script to incorporate Redis and PostgreSQL, while also introducing an option to include Adminer during installation.

## 2023-09-10

### Changed

- **TurnKey Game Server LXC**
  - NEW Script

## 2023-09-09

### Changed

- **Proxmox VE Host Backup**
  - Users are now able to specify both the backup path and the directory in which they wish to work.

## 2023-09-07

### Changed

- **Proxmox VE Host Backup**
  - NEW Script

## 2023-09-06

### Changed

- **Proxmox VE LXC Cleaner**
  - Added a new menu that allows you to choose which containers you want to exclude from the clean process.
- **Tailscale**
  - Added a menu that enables you to choose the specific container where you want to install Tailscale.

## 2023-09-05

### Changed

- **Proxmox VE LXC Updater**
  - Added a new menu that allows you to choose which containers you want to exclude from the update process.

## 2023-09-01

### Changed

- **TurnKey Media Server LXC**
  - NEW Script

## 2023-08-31

### Changed

- **TurnKey ZoneMinder LXC**
  - NEW Script
- **TurnKey OpenVPN LXC**
  - NEW Script

## 2023-08-30

### Changed

- **TurnKey**
  - Introducing a **NEW** Category on the Site.
  - My intention is to maintain the TurnKey scripts in their simplest form, contained within a single file, and with minimal options, if any.
- **TurnKey Core LXC**
  - NEW Script
- **TurnKey File Server LXC**
  - NEW Script
- **TurnKey Gitea LXC**
  - NEW Script
- **TurnKey GitLab LXC**
  - NEW Script
- **TurnKey Nextcloud LXC**
  - NEW Script
- **TurnKey Observium LXC**
  - NEW Script
- **TurnKey ownCloud LXC**
  - NEW Script
- **TurnKey Torrent Server LXC**
  - NEW Script
- **TurnKey Wordpress LXC**
  - NEW Script

## 2023-08-24

### Changed

- **qBittorrent LXC**
  - Added back to repository with UPnP disabled and password changed.

## 2023-08-24

### Changed

- **qBittorrent LXC**
  - Removed from this repository for potential malicious hidden code https://github.com/tteck/Proxmox/discussions/1725

## 2023-08-16

### Changed

- **Homarr LXC**
  - NEW Script

## 2023-08-10

### Changed

- **Proxmox VE Processor Microcode**
  - AMD microcode-20230808 Release

## 2023-08-09

### Changed

- **Omada Controller LXC**
  - Update via script
- **Proxmox VE Processor Microcode**
  - [Intel microcode-20230808 Release](https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files/releases/tag/microcode-20230808)

## 2023-08-01

### Changed

- **Overseerr LXC**
  - NEW Script
- **Jellyseerr LXC**
  - NEW Script

## 2023-07-24

### Changed

- **Ombi LXC**
  - NEW Script

## 2023-07-23

### Changed

- **Zoraxy LXC**
  - NEW Script

## 2023-07-18

### Changed

- **Proxmox VE Cron LXC Updater**
  - NEW Script

## 2023-07-11

### Changed

- **Scrypted LXC**
  - Add VAAPI hardware transcoding

## 2023-07-07

### Changed

- **Real-Debrid Torrent Client LXC**
  - NEW Script

## 2023-07-05

### Changed

- There have been more than 110 commits since June 18th, although not all of them are significant, with a majority focused on ensuring compatibility with Proxmox VE 8 and Debian 12.

## 2023-06-18

### Changed

- **OpenObserve LXC**
  - NEW Script

## 2023-06-17

### Changed

- **UniFi Network Application LXC**
  - Now distribution agnostic.
- **Omada Controller LXC**
  - Now distribution agnostic.
## 2023-06-16

### Changed

- **Proxmox VE Monitor-All**
  - Skip instances based on onboot and templates. [8c2a3cc](https://github.com/community-scripts/ProxmoxVE/commit/8c2a3cc4d774fa13d17f695d6bdf9a4deedb1372). 

## 2023-06-12

### Changed

- **Proxmox VE Edge Kernel**
  - Removed, with the Proxmox opt-in kernels and the upcoming Proxmox Virtual Environment 8, edge kernels are no longer needed.
- **Proxmox VE Kernel Clean**
  - Now compatible with PVE8.

## 2023-06-11

### Changed

- **Proxmox VE Post Install**
  - Now compatible with both Proxmox Virtual Environment 7 (PVE7) and Proxmox Virtual Environment 8 (PVE8). 

## 2023-06-02

### Changed

- **Proxmox VE 7 Post Install**
  - In a non-clustered environment, you can choose to disable high availability, which helps save system resources.

## 2023-05-27

### Changed

- **Proxmox VE 7 Post Install**
  - If an Intel N-series processor is detected, ~the script provides options to install both the Proxmox 6.2 kernel and the Intel microcode.~ and using PVE7, recommend using PVE8

## 2023-05-23

### Changed

- **OpenWrt VM**
  - NEW Script

## 2023-05-17

### Changed

- **Alpine-AdGuard Home LXC**
  - Removed, it wasn't installed through the Alpine package manager.
- **Alpine-Whoogle LXC**
  - Removed, it wasn't installed through the Alpine package manager.

## 2023-05-16

### Changed

- **Proxmox VE LXC Updater**
  - Add information about the boot disk, which provides an easy way to determine if you need to expand the disk.
- **Proxmox VE Processor Microcode**
  - [Intel microcode-20230512 Release](https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files/releases/tag/microcode-20230512)

## 2023-05-13

### Changed

- **Tautulli LXC**
  - NEW Script

## 2023-05-12

### Changed

- **Bazarr LXC**
  - NEW Script

## 2023-05-08

### Changed

- **Proxmox VE Intel Processor Microcode**
  - Renamed to **Proxmox VE Processor Microcode**
  - Automatically identifies the processor vendor (Intel/AMD) and installs the appropriate microcode.

## 2023-05-07

### Changed

- **FHEM LXC**
  - NEW Script

## 2023-05-01

### Changed

- **OctoPrint LXC**
  - NEW Script
- **Proxmox VE Intel Processor Microcode**
  - NEW Script

## 2023-04-30

### Changed

- **Proxmox VE Monitor-All**
  - NEW Script
  - Replaces Proxmox VE LXC Monitor

## 2023-04-28

### Changed

- **Proxmox VE LXC Monitor**
  - NEW Script

## 2023-04-26

### Changed

- **The site can now be accessed through a more memorable URL, which is [helper-scripts.com](http://helper-scripts.com).**

## 2023-04-23

### Changed

- **Non-Alpine LXC's**
  - Advanced settings provide the option for users to switch between Debian and Ubuntu distributions. However, some applications or services, such as Deconz, grocy or Omada, may not be compatible with the selected distribution due to dependencies.

## 2023-04-16

### Changed

- **Home Assistant Core LXC**
  - Python 3.11.2

## 2023-04-15

### Changed

- **InfluxDB LXC**
  - Choosing InfluxDB v1 will result in Chronograf being installed automatically.
- **[User Submitted Guides](https://github.com/community-scripts/ProxmoxVE/blob/main/USER_SUBMITTED_GUIDES.md)**
  -  Informative guides that demonstrate how to install various software packages using Proxmox VE Helper Scripts.

## 2023-04-14

### Changed

- **Cloudflared LXC**
  - NEW Script

## 2023-04-05

### Changed

- **Jellyfin LXC**
  - Set Ubuntu 22.04 as default
  - Use the Deb822 format jellyfin.sources configuration (jellyfin.list configuration has been obsoleted)

## 2023-04-02

### Changed

- **Home Assistant OS VM**
  - Include a choice within the "Advanced" settings to configure the CPU model between kvm64 (default) or host.

## 2023-03-31

### Changed

- **Home Assistant OS VM**
  - Include a choice within the "Advanced" settings to configure the disk cache between none (default) or Write Through.

## 2023-03-27

### Changed

- **Removed Alpine-ESPHome LXC**
  - Nonoperational
- **All Scripts**
  - Incorporate code that examines whether SSH is being used and, if yes, offers a suggestion against it without restricting or blocking its usage.

## 2023-03-25

### Changed

- **Alpine-ESPHome LXC**
  - NEW Script
- **Alpine-Whoogle LXC**
  - NEW Script

## 2023-03-22

### Changed

- **The latest iteration of the scripts**
  - Going forward, versioning will no longer be utilized in order to avoid breaking web-links in blogs and YouTube videos.
  - The scripts have been made more legible as the repetitive code has been moved to function files, making it simpler to share among the scripts and hopefully easier to maintain. This also makes it simpler to contribute to the project.
  - When a container is created with privileged mode enabled, the USB passthrough feature is automatically activated.

## 2023-03-18

### Changed

- **Alpine-AdGuard Home LXC** (Thanks @nicedevil007)
  - NEW Script
- **Alpine-Docker LXC**
  - NEW Script
- **Alpine-Zigbee2MQTT LXC**
  - NEW Script

## 2023-03-15

### Changed

- **Alpine-Grafana LXC** (Thanks @nicedevil007)
  - NEW Script

## 2023-03-10

### Changed

- **Proxmox LXC Updater** 
  - You can use the command line to exclude multiple containers simultaneously.

## 2023-03-08

### Changed

- **Proxmox CPU Scaling Governor**
  - Menu options dynamically based on the available scaling governors.

## 2023-03-07

### Changed

- **Alpine-Vaultwarden LXC**
  - NEW Script
- **All LXC Scripts**
  - Retrieve the time zone from Proxmox and configure the container to use the same time zone

## 2023-02-24

### Changed

- **qBittorrent LXC** (Thanks @romka777)
  - NEW Script
- **Jackett LXC** (Thanks @romka777)
  - NEW Script

## 2023-02-23

### Changed

- **Proxmox LXC Updater** 
  - Skip all templates, allowing for the starting, updating, and shutting down of containers to be resumed automatically.
  - Exclude an additional container by adding the CTID at the end of the shell command ( -s 103).

## 2023-02-16

### Changed

- **RSTPtoWEB LXC** 
  - NEW Script
- **go2rtc LXC** 
  - NEW Script

## 2023-02-12

### Changed

- **OliveTin** 
  - NEW Script

## 2023-02-10

### Changed

- **Home Assistant OS VM** 
  - Code Refactoring

## 2023-02-05

### Changed

- **Devuan LXC** 
  - NEW Script

## 2023-02-02

### Changed

- **Audiobookshelf LXC** 
  - NEW Script
- **Rocky Linux LXC** 
  - NEW Script

## 2023-01-28

### Changed

- **LXC Cleaner** 
  - Code refactoring to give the user the option to choose whether cache or logs will be deleted for each app/service.
  - Leaves directory structure intact

## 2023-01-27

### Changed

- **LXC Cleaner** 
  - NEW Script

## 2023-01-26

### Changed

- **ALL LXC's** 
  - Add an option to disable IPv6 (Advanced)

## 2023-01-25

### Changed

- **Home Assistant OS VM** 
  - switch to v5
  - add an option to set MTU size (Advanced)
  - add arch check (no ARM64) (issue from community.home-assistant.io)
  - add check to insure VMID isn't already used before VM creation (Advanced) (issue from forum.proxmox.com)
  - code refactoring
- **PiMox Home Assistant OS VM** 
  - switch to v5
  - add an option to set MTU size (Advanced)
  - add arch check (no AMD64)
  - add pve check (=>7.2)
  - add check to insure VMID isn't already used before VM creation (Advanced)
  - code refactoring
- **All LXC's** 
  - add arch check (no ARM64) (issue from forum.proxmox.com)

## 2023-01-24

### Changed

- **Transmission LXC** 
  - NEW Script

## 2023-01-23

### Changed

- **ALL LXC's** 
  - Add [Midnight Commander (mc)](https://www.linuxcommand.org/lc3_adv_mc.php)

## 2023-01-22

### Changed

- **Autobrr LXC** 
  - NEW Script

## 2023-01-21

### Changed

- **Kavita LXC** 
  - NEW Script

## 2023-01-19

### Changed

- **SABnzbd LXC** 
  - NEW Script

## 2023-01-17

### Changed

- **Homer LXC** 
  - NEW Script

## 2023-01-14

### Changed

- **Tdarr LXC** 
  - NEW Script
- **Deluge LXC** 
  - NEW Script

## 2023-01-13

### Changed

- **Lidarr LXC** 
  - NEW Script
- **Prowlarr LXC** 
  - NEW Script
- **Radarr LXC** 
  - NEW Script
- **Readarr LXC** 
  - NEW Script
- **Sonarr LXC** 
  - NEW Script
- **Whisparr LXC** 
  - NEW Script

## 2023-01-12

### Changed

- **ALL LXC's** 
  - Add an option to set MTU size (Advanced)

## 2023-01-11

### Changed

- **Home Assistant Core LXC** 
  - Auto Initialize
- **Cronicle Primary/Worker LXC** 
  - NEW Script

## 2023-01-09

### Changed

- **ALL LXC's** 
  - v5
- **k0s Kubernetes LXC** 
  - NEW Script
- **Podman LXC** 
  - NEW Script

## 2023-01-04

### Changed

- **YunoHost LXC** 
  - NEW Script

## 2022-12-31

### Changed

- **v5 Scripts** (Testing before moving forward https://github.com/tteck/Proxmox/discussions/881)
  - Adguard Home LXC
  - Docker LXC
  - Home Assistant Core LXC
  - PhotoPrism LXC
  - Shinobi NVR LXC
  - Vaultwarden LXC

## 2022-12-27

### Changed

- **Home Assistant Container LXC** 
  - Add an option to use Fuse Overlayfs (ZFS) (Advanced)

- **Docker LXC** 
  - Add an option to use Fuse Overlayfs (ZFS) (Advanced)
  - If the LXC is created Privileged, the script will automatically set up USB passthrough.

## 2022-12-22

### Changed

- **All LXC's** 
  - Add an option to run the script in Verbose Mode (Advanced)

## 2022-12-20

### Changed

- **Hyperion LXC** 
  - NEW Script

## 2022-12-17

### Changed

- **Home Assistant Core LXC** 
  - Linux D-Bus Message Broker
  - Mariadb & PostgreSQL Ready
  - Bluetooth Ready
  - Fix for Inconsistent Dependency Versions (dbus-fast & bleak)

## 2022-12-16

### Changed

- **Home Assistant Core LXC** 
  - Python 3.10.8

## 2022-12-09

### Changed

- **Change Detection LXC** 
  - NEW Script

## 2022-12-03

### Changed

- **All LXC's** 
  - Add options to set DNS Server IP Address and DNS Search Domain (Advanced)

## 2022-11-27

### Changed

- **Shinobi LXC** 
  - NEW Script

## 2022-11-24

### Changed

- **Home Assistant OS VM** 
  - Add option to set machine type during VM creation (Advanced)

## 2022-11-23

### Changed

- **All LXC's** 
  - Add option to enable root ssh access during LXC creation (Advanced)

## 2022-11-21

### Changed

- **Proxmox LXC Updater** 
  - Now updates Ubuntu, Debian, Devuan, Alpine Linux, CentOS-Rocky-Alma, Fedora, ArchLinux [(@Uruknara)](https://github.com/community-scripts/ProxmoxVE/commits?author=Uruknara)

## 2022-11-13

### Changed

- **All LXC's** 
  - Add option to continue upon Internet NOT Connected

## 2022-11-11

### Changed

- **HA Bluetooth Integration Preparation** 
  - [NEW Script](https://github.com/tteck/Proxmox/discussions/719)

## 2022-11-04

### Changed

- **Scrypted LXC** 
  - NEW Script

## 2022-11-01

### Changed

- **Alpine LXC** 
  - NEW Script
- **Arch LXC** 
  - NEW Script

## 2022-10-27

### Changed

- **Container & Core Restore from Backup** 
  - [NEW Scripts](https://github.com/tteck/Proxmox/discussions/674)

## 2022-10-07

### Changed

- **Home Assistant OS VM** 
  - Add "Latest" Image

## 2022-10-05

### Changed

- **Umbrel LXC** 
  - NEW Script (Docker)
- **Blocky LXC** 
  - NEW Script (Adblocker - DNS)

## 2022-09-29

### Changed

- **Home Assistant Container LXC** 
  - If the LXC is created Privileged, the script will automatically set up USB passthrough.
- **Home Assistant Core LXC** 
  - NEW Script
- **PiMox HAOS VM** 
  - NEW Script

## 2022-09-23

### Changed

- **EMQX LXC** 
  - NEW Script

## 2022-09-22

### Changed

- **NextCloudPi LXC** 
  - NEW Script

## 2022-09-21

### Changed

- **Proxmox Backup Server Post Install** 
  - NEW Script
- **Z-wave JS UI LXC** 
  - NEW Script (and all sub scripts 🤞)
- **Zwave2MQTT LXC** 
  - Bye Bye Script

## 2022-09-20

### Changed

- **OpenMediaVault LXC** 
  - NEW Script

## 2022-09-16

### Changed

- **Paperless-ngx LXC** 
  - NEW Script (Thanks @Donkeykong307)

## 2022-09-11

### Changed

- **Trilium LXC** 
  - NEW Script

## 2022-09-10

### Changed

- **Syncthing LXC** 
  - NEW Script

## 2022-09-09

### Changed

- **CasaOS LXC** 
  - NEW Script
- **Proxmox Kernel Clean** 
  - Now works with Proxmox Backup Server

## 2022-09-08

### Changed

- **Navidrome LXC** 
  - NEW Script
- **Homepage LXC** 
  - NEW Script

## 2022-08-31

### Changed

- **All LXC's** 
  - Add Internet & DNS Check

## 2022-08-22

### Changed

- **Wiki.js LXC** 
  - NEW Script
- **Emby Media Server LXC**
  - NEW Script

## 2022-08-20

### Changed

- **Mikrotik RouterOS VM** 
  - NEW Script

## 2022-08-19

### Changed

- **PhotoPrism LXC** 
  - Fixed .env bug (Thanks @cklam2)

## 2022-08-13

### Changed

- **Home Assistant OS VM** 
  - Option to create VM using Stable, Beta or Dev Image

## 2022-08-11

### Changed

- **Home Assistant OS VM** 
  - Validate Storage

## 2022-08-04

### Changed

- **VS Code Server** 
  - NEW Script

## 2022-08-02

### Changed

- **All LXC/VM** 
  - v4 Script - Whiptail menu's

## 2022-07-26

### Changed

- **Home Assistant OS VM** 
  - Set the real time clock (RTC) to local time.
  - Disable the USB tablet device (save resources / not needed).

## 2022-07-24

### Changed

- **Home Assistant OS VM** 
  - Present the drive to the guest as a solid-state drive rather than a rotational hard disk. There is no requirement that the underlying storage actually be backed by SSD's. 
  - When the VM’s filesystem marks blocks as unused after deleting files, the SCSI controller will relay this information to the storage, which will then shrink the disk image accordingly.
  - 👉 [more info](https://github.com/tteck/Proxmox/discussions/378)

## 2022-07-22

### Changed

- **n8n LXC** (thanks to @cyakimov)
  - NEW Script

## 2022-07-21

### Changed

- **grocy LXC**
  - NEW Script

## 2022-07-17

### Changed

- **Vaultwarden LXC**
  - NEW Vaultwarden Update (post 2022-05-29 installs only) Script
  - NEW Web-vault Update (any) Script

## 2022-07-14

### Changed

- **MagicMirror Server LXC**
  - NEW Script

## 2022-07-13

### Changed

- **Proxmox Edge Kernel Tool**
  - NEW Script

## 2022-07-11

### Changed

- **Home Assistant OS VM**
  - Supports lvmthin, zfspool, nfs, dir and btrfs storage types.

## 2022-07-08

### Changed

- **openHAB LXC**
  - NEW Script

## 2022-07-03

### Changed

- **Tailscale**
  - NEW Script

## 2022-07-01

### Changed

- **Home Assistant OS VM**
  - Allow different storage types (lvmthin, nfs, dir).

## 2022-06-30

### Changed

- **Prometheus LXC**
  - NEW Script

## 2022-06-06

### Changed

- **Whoogle LXC**
  - NEW Script

## 2022-05-29

### Changed

- **Vaultwarden LXC**
  - Code refactoring
- **CrowdSec**
  - NEW Script

## 2022-05-21

### Changed

- **Home Assistant OS VM**
  - Code refactoring

## 2022-05-19

### Changed

- **Keycloak LXC**
  - NEW Script

## 2022-05-18

### Changed

- **File Browser**
  - NEW Script

## 2022-05-13

### Changed

- **PostgreSQL LXC**
  - NEW Script

## 2022-05-10

### Changed

- **deCONZ LXC**
  - NEW Script

## 2022-05-07

### Changed

- **NocoDB LXC**
  - ADD update script

## 2022-05-06

### Changed

- **PhotoPrism LXC**
  - ADD GO Dependencies for full functionality

## 2022-05-05

### Changed

- **Ubuntu LXC**
  - ADD option to define version (18.04 20.04 21.10 22.04)

## 2022-04-28

### Changed

- **v3 Script**
  - Remove Internet Check

## 2022-04-27

### Changed

- **Home Assistant OS VM**
  - ADD Option to set Bridge, VLAN and MAC Address
- **v3 Script**
  - Improve Internet Check (prevent ‼ ERROR 4@57)

## 2022-04-26

### Changed

- **Home Assistant OS VM**
  - Fixed bad path
  - ADD Option to create VM using Latest or Stable image
- **UniFi Network Application LXC**
  - ADD Local Controller Option

## 2022-04-25

### Changed

- **v3 Script**
  - Improve Error Handling

## 2022-04-23

### Changed

- **v3 Script**
  - ADD Internet Connection Check
- **Proxmox VE 7 Post Install**
  - NEW v3 Script
- **Proxmox Kernel Clean**
  - NEW v3 Script

## 2022-04-22

### Changed

- **Omada Controller LXC**
  - Update script to install version 5.1.7
- **Uptime Kuma LXC**
  - ADD Update script

## 2022-04-20

### Changed

- **Ubuntu LXC**
  - ADD option to install version 20.04 or 21.10
- **v3 Script**
  - ADD option to set Bridge

## 2022-04-19

### Changed

- **ALL LXC's**
  - New [V3 Install Script](https://github.com/tteck/Proxmox/issues/162) 
- **ioBroker LXC**
  - New Script V3

## 2022-04-13

### Changed

- **Uptime Kuma LXC**
  - New Script V2

## 2022-04-11

### Changed

- **Proxmox LXC Updater**
  - ADD option to skip stopped containers
- **Proxmox VE 7 Post Install**
  - ADD PVE 7 check

## 2022-04-10

### Changed

- **Debian 11 LXC**
  - ADD An early look at the v3 install script

## 2022-04-09

### Changed

- **NocoDB LXC**
  - New Script V2

## 2022-04-05

### Changed

- **MeshCentral LXC**
  - New Script V2

## 2022-04-01

### Changed

- **Scripts** (V2)
  - FIX Pressing enter without making a selection first would cause an Error 

## 2022-03-28

### Changed

- **Docker LXC**
  - Add Docker Compose Option (@wovalle)

## 2022-03-27

### Changed

- **Heimdall Dashboard LXC**
  - New Update Script

## 2022-03-26

### Changed

- **UniFi Network Application LXC**
  - New Script V2
- **Omada Controller LXC**
  - New Script V2

## 2022-03-25

### Changed

- **Proxmox CPU Scaling Governor**
  - New Script


## 2022-03-24

### Changed

- **Plex Media Server LXC**
  - Switch to Ubuntu 20.04 to support HDR tone mapping
- **Docker LXC**
  - Add Portainer Option

## 2022-03-23

### Changed

- **Heimdall Dashboard LXC**
  - New Script V2

## 2022-03-20

### Changed

- **Scripts** (V2)
  - ADD choose between Automatic or Manual DHCP  

## 2022-03-18

### Changed

- **Technitium DNS LXC**
  - New Script V2
- **WireGuard LXC**
  - Add WGDashboard

## 2022-03-17

### Changed

- **Docker LXC**
  - New Script V2

## 2022-03-16

### Changed

- **PhotoPrism LXC**
  - New Update/Branch Script

## 2022-03-15

### Changed

- **Dashy LXC**
  - New Update Script

## 2022-03-14

### Changed

- **Zwavejs2MQTT LXC**
  - New Update Script

## 2022-03-12

### Changed

- **PhotoPrism LXC**
  - New Script V2

## 2022-03-11

### Changed

- **Vaultwarden LXC**
  - New V2 Install Script

## 2022-03-08

### Changed

- **Scripts** (V2)
  - Choose between Privileged or Unprivileged CT and Automatic or Password Login 
- **ESPHome LXC**
  - New V2 Install Script
- **Zwavejs2MQTT LXC**
  - New V2 Install Script
- **Motioneye LXC**
  - New V2 Install Script
- **Pihole LXC**
  - New V2 Install Script
- **GamUntu LXC**
  - New V2 Install Script

## 2022-03-06

### Changed

- **Zwavejs2MQTT LXC**
  - New GUI script to copy data from one Zwavejs2MQTT LXC to another Zwavejs2MQTT LXC

## 2022-03-05

### Changed

- **Homebridge LXC**
  - New Script V2

## 2022-03-04

### Changed

- **Proxmox Kernel Clean**
  - New Script

## 2022-03-03

### Changed

- **WireGuard LXC**
  - New Script V2

## 2022-03-02

### Changed

- **Proxmox LXC Updater**
  - New Script
- **Dashy LXC**
  - New Script V2
- **Grafana LXC**
  - New Script V2
- **InfluxDB/Telegraf LXC**
  - New Script V2

## 2022-03-01

### Changed

- **Daemon Sync Server LXC**
  - New Script V2

## 2022-02-28

### Changed

- **Vaultwarden LXC**
  - Add Update Script

## 2022-02-24

### Changed

- **Nginx Proxy Manager LXC**
  - New V2 Install Script

## 2022-02-23

### Changed

- **Adguard Home LXC**
  - New V2 Install Script
- **Zigbee2MQTT LXC**
  - New V2 Install Script
- **Home Assistant Container LXC**
  - Update Menu usability improvements

## 2022-02-22

### Changed

- **Home Assistant Container LXC**
  - New V2 Install Script
- **Node-Red LXC**
  - New V2 Install Script
- **Mariadb LXC**
  - New V2 Install Script
- **MQTT LXC**
  - New V2 Install Script
- **Debian 11 LXC**
  - New V2 Install Script
- **Ubuntu 21.10 LXC**
  - New V2 Install Script

## 2022-02-20

### Changed

- **Home Assistant Container LXC**
  - New Script to migrate to the latest Update Menu

## 2022-02-19

### Changed

- **Nginx Proxy Manager LXC**
  - Add Update Script
- **Vaultwarden LXC**
  - Make unattended install & Cleanup Script

## 2022-02-18

### Changed

- **Node-Red LXC**
  - Add Install Themes Script

## 2022-02-16

### Changed

- **Home Assistant Container LXC**
  - Add Options to Update Menu

## 2022-02-14

### Changed

- **Home Assistant Container LXC**
  - Add Update Menu

## 2022-02-13

### Changed

- **Mariadb LXC**
  - Add Adminer (formerly phpMinAdmin), a full-featured database management tool

## 2022-02-12

### Changed

- **Home Assistant Container LXC (Podman)**
  - Add Yacht web interface for managing Podman containers
  - new GUI script to copy data from a **Home Assistant LXC** to a **Podman Home Assistant LXC**
  - Improve documentation for several LXC's

## 2022-02-10

### Changed

- **GamUntu LXC**
  - New Script
- **Jellyfin Media Server LXC**
  - new script to fix [start issue](https://github.com/tteck/Proxmox/issues/29#issue-1127457380)
- **MotionEye NVR LXC**
  - New script

## 2022-02-09

### Changed

- **Zigbee2MQTT LXC**
  - added USB passthrough during installation (no extra script)
  - Improve documentation
- **Zwavejs2MQTT LXC**
  - added USB passthrough during installation (no extra script)
- **Jellyfin Media Server LXC**
  - Moved to testing due to issues. 
  - Changed install method.
- **Home Assistant Container LXC (Podman)** 
  - add script for easy Home Assistant update

## 2022-02-06

### Changed

- **Debian 11 LXC**
  - Add Docker Support
- **Ubuntu 21.10 LXC**
  - Add Docker Support

## 2022-02-05

### Changed

- **Vaultwarden LXC**
  - New script

## 2022-02-01

### Changed

- **All Scripts**
  - Fix issue where some networks were slow to assign a IP address to the container causing scripts to fail.

## 2022-01-30

### Changed

- **Zigbee2MQTT LXC**
  - Clean up / Improve script
  - Improve documentation

## 2022-01-29

### Changed

- **Node-Red LXC**
  - Clean up / Improve script
  - Improve documentation

## 2022-01-25

### Changed

- **Jellyfin Media Server LXC**
  - new script

## 2022-01-24

### Changed

- **Plex Media Server LXC**
  - better Hardware Acceleration Support
  - `va-driver-all` is preinstalled
  - now using Ubuntu 21.10
- **misc**
  - new GUI script to copy data from one Plex Media Server LXC to another Plex Media Server LXC


## Initial Catch up - 2022-01-23
 
### Changed

- **Plex Media Server LXC**
  - add Hardware Acceleration Support
  - add script to install Intel Drivers
- **Zwavejs2MQTT LXC**
  - new script to solve no auto start at boot
- **Nginx Proxy Manager LXC** 
  - new script to use Debian 11
- **Ubuntu 21.10 LXC** 
  - new script
- **Mariadb LXC** 
  - add MariaDB Package Repository
- **MQTT LXC** 
  - add Eclipse Mosquitto Package Repository
- **Home Assistant Container LXC** 
  - change if ZFS filesystem is detected, execute automatic installation of static fuse-overlayfs
  - add script for easy Home Assistant update
- **Home Assistant Container LXC (Podman)** 
  - change if ZFS filesystem is detected, execute automatic installation of static fuse-overlayfs
- **Home Assistant OS VM** 
  - change disk type from SATA to SCSI to follow Proxmox official recommendations of choosing VirtIO-SCSI with SCSI disk
  - clean up
- **Proxmox VE 7 Post Install** 
  - new *No-Nag* method
- **misc**
  - new GUI script to copy data from one Home Assistant LXC to another Home Assistant LXC
  - new GUI script to copy data from one Zigbee2MQTT LXC to another Zigbee2MQTT LXC
