# cloud-init.func Usage Examples

Examples for VM cloud-init configuration.

### Example: Basic Cloud-Init

```bash
#!/usr/bin/env bash

generate_cloud_init > cloud-init.yaml
setup_ssh_keys "$VMID" "$SSH_KEY"
apply_cloud_init "$VMID" cloud-init.yaml
```

---

**Last Updated**: December 2025
