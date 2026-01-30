# Inventory Convention

This document describes the optional inventory convention that enables automatic variable mapping from your Ansible inventory to collection role variables.

## Overview

The collection roles expect specific variable structures (e.g., `dhcp_dns_static_leases` as a list of dicts). You have two options:

1. **Follow the convention** - Define variables in a standard way, use the provided adapters
2. **Custom mapping** - Define variables however you like, write your own mapping logic

## The Convention

### Host Variables

Each host in your inventory should define:

| Variable | Required | Description |
|----------|----------|-------------|
| `ip_address` | Yes | Host's IP address |
| `mac_address` | For DHCP | Host's MAC address (for static leases) |
| `cname` | No | DNS CNAME alias for this host |
| `fqdns_name` | No | Fully qualified domain name (auto-generated if not set) |

### Group Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `dns_domain` | Recommended | Local domain name (e.g., `home.lan`) |

## Example Inventory Structure

```
ansible/
├── development.yml          # Inventory file
├── group_vars/
│   └── all.yml              # dns_domain: home.lan
└── host_vars/
    ├── server1.yml          # ip_address, mac_address
    ├── server2.yml          # ip_address, mac_address, cname: git
    └── router/
        ├── vars.yml         # Router-specific config
        └── vault.yml        # Secrets
```

### Example host_vars/server1.yml

```yaml
ip_address: 192.168.1.10
mac_address: "aa:bb:cc:dd:ee:ff"
```

### Example host_vars/server2.yml

```yaml
ip_address: 192.168.1.20
mac_address: "11:22:33:44:55:66"
cname: git  # Creates DNS alias: git.home.lan -> server2.home.lan
```

### Example group_vars/all.yml

```yaml
dns_domain: home.lan
```

## Using the Adapters

If you follow the convention, include the adapter in your playbook:

```yaml
- hosts: router
  collections:
    - harley.openwrt

  pre_tasks:
    - name: Build dhcp_dns variables from inventory
      ansible.builtin.include_tasks:
        file: "{{ (lookup('ansible.builtin.config', 'COLLECTIONS_PATH') | split(':') | first) }}/ansible_collections/harley/openwrt/playbooks/includes/inventory_to_dhcp_dns.yml"
      tags: [dhcp_dns]

  roles:
    - role: dhcp_dns
      vars:
        dhcp_dns_domain: "{{ dns_domain }}"
      tags: [dhcp_dns]
```

### Limiting to Specific Groups

By default, the adapter processes all hosts in `groups['all']`. To limit to a specific group:

```yaml
pre_tasks:
  - name: Build dhcp_dns variables from inventory
    ansible.builtin.include_tasks:
      file: .../inventory_to_dhcp_dns.yml
    vars:
      inventory_adapter_group: lan  # Only process hosts in 'lan' group
```

## Custom Mapping (Alternative)

If your inventory structure differs, define the variables directly:

```yaml
- hosts: router
  collections:
    - harley.openwrt

  vars:
    dhcp_dns_static_leases:
      - name: server1
        ip: 192.168.1.10
        mac: "aa:bb:cc:dd:ee:ff"
      - name: server2
        ip: 192.168.1.20
        mac: "11:22:33:44:55:66"

    dhcp_dns_hosts:
      - name: server1
        ip: 192.168.1.10
      - name: server2
        ip: 192.168.1.20

    dhcp_dns_cnames:
      - alias: git
        target: server2.home.lan

  roles:
    - role: dhcp_dns
      vars:
        dhcp_dns_domain: home.lan
```

## Available Adapters

| Adapter File | For Role | Variables Produced |
|--------------|----------|-------------------|
| `inventory_to_dhcp_dns.yml` | dhcp_dns | `dhcp_dns_static_leases`, `dhcp_dns_hosts`, `dhcp_dns_cnames` |

More adapters will be added as roles are migrated.
