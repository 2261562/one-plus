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

  # Core container primitives. Most are already enabled on many Android GKI trees,
  # but we still write them explicitly so Docker builds are deterministic.
  set_config "$file" CONFIG_NAMESPACES y
  set_config "$file" CONFIG_NET_NS y
  set_config "$file" CONFIG_PID_NS y
  set_config "$file" CONFIG_IPC_NS y
  set_config "$file" CONFIG_UTS_NS y
  set_config "$file" CONFIG_USER_NS y

  set_config "$file" CONFIG_CGROUPS y
  set_config "$file" CONFIG_CGROUP_DEVICE y
  set_config "$file" CONFIG_CGROUP_CPUACCT y
  set_config "$file" CONFIG_CGROUP_FREEZER y
  set_config "$file" CONFIG_CGROUP_SCHED y
  set_config "$file" CONFIG_FAIR_GROUP_SCHED y
  set_config "$file" CONFIG_CPUSETS y
  set_config "$file" CONFIG_PROC_PID_CPUSET y
  set_config "$file" CONFIG_MEMCG y
  set_config "$file" CONFIG_MEMCG_KMEM y
  set_config "$file" CONFIG_CGROUP_PIDS y
  set_config "$file" CONFIG_CGROUP_BPF y

  set_config "$file" CONFIG_KEYS y
  set_config "$file" CONFIG_SECCOMP y
  set_config "$file" CONFIG_SECCOMP_FILTER y
  set_config "$file" CONFIG_POSIX_MQUEUE y

  # Docker core networking and storage.
  # Keep the most sensitive drivers as modules on this OnePlus tree to reduce
  # the chance of GKI/KMI runtime breakage.
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

  # nftables / IPVS support is useful for modern Docker stacks and some K8s setups.
  set_config "$file" CONFIG_NF_TABLES y
  set_config "$file" CONFIG_NFT_CT y
  set_config "$file" CONFIG_NFT_MASQ y
  set_config "$file" CONFIG_IP_VS y
  set_config "$file" CONFIG_IP_VS_NFCT y
  set_config "$file" CONFIG_IP_VS_PROTO_TCP y
  set_config "$file" CONFIG_IP_VS_PROTO_UDP y
  set_config "$file" CONFIG_IP_VS_RR y
  set_config "$file" CONFIG_NETFILTER_XT_MATCH_IPVS y

  # These legacy helpers are not needed for Docker itself and previously caused
  # KMI symbol protection failures when built as modules.
  unset_config "$file" CONFIG_NF_CONNTRACK_AMANDA
  unset_config "$file" CONFIG_NF_CONNTRACK_FTP
  unset_config "$file" CONFIG_NF_CONNTRACK_H323
  unset_config "$file" CONFIG_NF_CONNTRACK_IRC
  unset_config "$file" CONFIG_NF_CONNTRACK_NETBIOS_NS
  unset_config "$file" CONFIG_NF_CONNTRACK_PPTP
  unset_config "$file" CONFIG_NF_CONNTRACK_SANE
  unset_config "$file" CONFIG_NF_CONNTRACK_TFTP
  unset_config "$file" CONFIG_NF_NAT_AMANDA
  unset_config "$file" CONFIG_NF_NAT_FTP
  unset_config "$file" CONFIG_NF_NAT_H323
  unset_config "$file" CONFIG_NF_NAT_IRC
  unset_config "$file" CONFIG_NF_NAT_PPTP
  unset_config "$file" CONFIG_NF_NAT_TFTP

  # Keep the OnePlus-specific high-risk cgroup block untouched by default.
  # Enabling these blindly made this tree much more likely to bootloop.
  unset_config "$file" CONFIG_CGROUP_NET_CLASSID
}

for config_file in "$@"; do
  if [ ! -f "$config_file" ]; then
    echo "Error: Config file not found: $config_file" >&2
    exit 1
  fi

  apply_docker_profile "$config_file"
done
