# cloud-init.func Flowchart

Cloud-init VM provisioning flow.

## Cloud-Init Generation and Application

```
generate_cloud_init()
    ↓
generate_user_data()
    ↓
setup_ssh_keys()
    ↓
Apply to VM
    ↓
VM Boot
    ↓
cloud-init phases
├─ system
├─ config
└─ final
    ↓
VM Ready ✓
```

---

**Last Updated**: December 2025
