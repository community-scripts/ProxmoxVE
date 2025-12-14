# alpine-install.func Functions Reference

Alpine Linux-specific installation functions (apk-based, OpenRC).

## Core Functions

### setting_up_container()
Initialize Alpine container setup.

### update_os()
Update Alpine packages via `apk update && apk upgrade`.

### verb_ip6()
Enable IPv6 on Alpine with persistent configuration.

### network_check()
Verify network connectivity in Alpine.

### motd_ssh()
Configure SSH daemon and MOTD on Alpine.

### customize()
Apply Alpine-specific customizations.

### cleanup_lxc()
Final cleanup (Alpine-specific).

---

**Last Updated**: December 2025
