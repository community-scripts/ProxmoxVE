# Fix Plan: llama.cpp CPU Backend Missing

## Problem Summary

The llama.cpp service fails to start with the error:
```
llama_model_load: error loading model: make_cpu_buft_list: no CPU backend found
```

## Root Cause Analysis

### Initial Hypothesis (INCORRECT)
Initially suspected that CPU backend files were missing from the installation.

### Actual Root Cause (CONFIRMED)
The CPU backend files **ARE present** in `/opt/llamacpp/bin/`, but they fail to load due to a **missing dependency**:

```
$ ldd /opt/llamacpp/bin/libggml-cpu-haswell.so
        libgomp.so.1 => not found    <-- MISSING!
```

**`libgomp.so.1`** (GNU OpenMP runtime library) is required by the CPU backend libraries but is not installed in the container.

### Why RPC and Vulkan Backends Load Successfully
- `libggml-rpc.so` - No `libgomp` dependency ✅
- `libggml-vulkan.so` - No `libgomp` dependency ✅
- `libggml-cpu-*.so` - **Requires `libgomp.so.1`** ❌

## Solution

### Fix: Install libgomp1 Package

Add `libgomp1` to the dependencies in [`install/llamacpp-install.sh`](install/llamacpp-install.sh):

```bash
msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  wget \
  ca-certificates \
  vulkan-tools \
  libvulkan1 \
  mesa-vulkan-drivers \
  pciutils \
  libgomp1    # <-- Add this package
msg_ok "Installed Dependencies"
```

### Why This Works
- `libgomp1` provides `libgomp.so.1` (GNU OpenMP runtime)
- CPU backends use OpenMP for parallel processing
- Without this library, the dynamic linker fails to load `libggml-cpu-*.so`

## Verification Steps

After installing `libgomp1`, verify the fix:

```bash
# 1. Verify libgomp is installed
ldd /opt/llamacpp/bin/libggml-cpu-haswell.so | grep gomp
# Expected: libgomp.so.1 => /lib/x86_64-linux-gnu/libgomp.so.1 (0x...)

# 2. Verify CPU backend loads
/opt/llamacpp/bin/llama-server --version
# Expected output should include:
# load_backend: loaded RPC backend from ...
# load_backend: loaded Vulkan backend from ...
# load_backend: loaded CPU backend from .../libggml-cpu-*.so  <-- This should now appear

# 3. Test model loading
systemctl start llamacpp
journalctl -u llamacpp -f
# Should no longer show "no CPU backend found" error
```

## Implementation

### File to Modify
[`install/llamacpp-install.sh`](install/llamacpp-install.sh) - Line 16-23

### Change Required
```diff
  msg_info "Installing Dependencies"
  $STD apt-get install -y \
    curl \
    wget \
    ca-certificates \
    vulkan-tools \
    libvulkan1 \
    mesa-vulkan-drivers \
    pciutils \
+   libgomp1
  msg_ok "Installed Dependencies"
```

## References

- [GitHub Issue #17491: CPU backend loader does not respect LD_LIBRARY_PATH](https://github.com/ggml-org/llama.cpp/issues/17491)
- [GitHub Issue #14691: make_cpu_buft_list: no CPU backend found](https://github.com/ggml-org/llama.cpp/issues/14691)
- [GNU OpenMP (libgomp) Documentation](https://gcc.gnu.org/onlinedocs/libgomp/)
