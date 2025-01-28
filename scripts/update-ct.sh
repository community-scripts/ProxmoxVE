#!/usr/bin/env bash

# for every file in the "ct" directory,
# replace "source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)"
# with "source <(curl -s https://raw.githubusercontent.com/bketelsen/IncusScripts/main/misc/build.func)"

for file in ct/*.sh; do
  sed -i 's|source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)|source <(curl -s https://raw.githubusercontent.com/bketelsen/IncusScripts/main/misc/build.func)|g' "$file"
done

for file in ct/*.sh; do
  sed -i 's|source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/refs/heads/main/misc/build.func)|source <(curl -s https://raw.githubusercontent.com/bketelsen/IncusScripts/main/misc/build.func)|g' "$file"
done
