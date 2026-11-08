#!/usr/bin/env bash
# Install (or remove) the root half of the Battery plugin: the helper in
# /usr/local/libexec and the polkit action that lets pkexec run it. A user
# plugin cannot install these; the page shows this command until they exist.
#
#   bash scripts/install-helper.sh            # install / update
#   bash scripts/install-helper.sh --remove   # uninstall
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

helper=/usr/local/libexec/omarchy-battery-limit
policy=/usr/share/polkit-1/actions/com.mutex-solutions.battery.limit.policy

if [[ ${1:-} == --remove ]]; then
  sudo rm -f "$helper" "$policy"
  echo "removed $helper and $policy"
  exit 0
fi

# root-owned and not writable by the user: pkexec runs it as root.
sudo install -Dm755 -o root -g root system/omarchy-battery-limit "$helper"
sudo install -Dm644 -o root -g root system/com.mutex-solutions.battery.limit.policy "$policy"
echo "installed $helper and $policy"
