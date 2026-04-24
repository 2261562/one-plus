#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <defconfig> [<defconfig> ...]" >&2
  exit 1
fi

sed_in_place() {
  local expr="$1"
  local file="$2"

  if sed --version >/dev/null 2>&1; then
    sed -i -e "$expr" "$file"
  else
    sed -i '' -e "$expr" "$file"
  fi
}

set_config() {
  local file="$1"
  local key="$2"
  local value="$3"

  if grep -qE "^${key}=" "$file"; then
    sed_in_place "s|^${key}=.*|${key}=${value}|" "$file"
  elif grep -qE "^# ${key} is not set$" "$file"; then
    sed_in_place "s|^# ${key} is not set$|${key}=${value}|" "$file"
  else
    printf '%s=%s\n' "$key" "$value" >> "$file"
  fi
}

unset_config() {
  local file="$1"
  local key="$2"

  if grep -qE "^${key}=" "$file"; then
    sed_in_place "s|^${key}=.*|# ${key} is not set|" "$file"
  elif ! grep -qE "^# ${key} is not set$" "$file"; then
    printf '# %s is not set\n' "$key" >> "$file"
  fi
}

apply_docker_profile() {
  local file="$1"
  echo "Injecting Docker profile into ${file}"

  # Keep this profile intentionally narrow and close to the previously working
  # "append to gki_defconfig" approach from this repo.
  #
  # We do NOT re-write namespaces / cgroups / ipvs / nftables here because
  # they are already present in the base OnePlus defconfig, and over-touching
  # them made Kleaf / KMI behavior worse on this tree.

  # Basic runtime features.
  set_config "$file" CONFIG_KEYS y
  set_config "$file" CONFIG_SECCOMP y
  set_config "$file" CONFIG_SECCOMP_FILTER y
  set_config "$file" CONFIG_POSIX_MQUEUE y
  set_config "$file" CONFIG_TMPFS_XATTR y
  set_config "$file" CONFIG_TMPFS_POSIX_ACL y

  # Docker core networking and storage.
  # These remain modules to reduce the chance of runtime GKI/KMI breakage.
  set_config "$file" CONFIG_VETH m
  set_config "$file" CONFIG_BRIDGE m
  set_config "$file" CONFIG_BRIDGE_NETFILTER m
  set_config "$file" CONFIG_MACVLAN m
  set_config "$file" CONFIG_IPVLAN m
  set_config "$file" CONFIG_VXLAN m
  set_config "$file" CONFIG_DUMMY m
  set_config "$file" CONFIG_NF_NAT m
  set_config "$file" CONFIG_NETFILTER_XT_MATCH_CONNTRACK m
  set_config "$file" CONFIG_NETFILTER_XT_MATCH_ADDRTYPE m
  set_config "$file" CONFIG_IP_NF_FILTER y
  set_config "$file" CONFIG_IP_NF_NAT m
  set_config "$file" CONFIG_IP_NF_TARGET_MASQUERADE m
  set_config "$file" CONFIG_IP6_NF_NAT m
  set_config "$file" CONFIG_IP6_NF_TARGET_MASQUERADE m
  set_config "$file" CONFIG_OVERLAY_FS m
}

for config_file in "$@"; do
  if [ ! -f "$config_file" ]; then
    echo "Error: Config file not found: $config_file" >&2
    exit 1
  fi

  apply_docker_profile "$config_file"
done
