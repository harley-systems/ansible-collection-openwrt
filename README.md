# Ansible Collection: harley.openwrt

Ansible collection for configuring OpenWRT routers in home and office environments.

## Features

- **Base Setup** - Python, pip, SFTP, ansible user creation
- **Network** - WAN (PPPoE, DHCP, static), LAN, WiFi configuration
- **Firewall** - Zone-based firewall with VPN support
- **DHCP/DNS** - Static leases, DNS entries, local domain
- **IPsec VPN** - StrongSwan site-to-site and road-warrior configurations
- **ACME** - Let's Encrypt certificates with DNS-01 challenge (Cloudflare)
- **DDNS** - Dynamic DNS updates (Cloudflare, others)
- **Web UI** - HTTPS configuration for LuCI

## Requirements

- OpenWRT 21.02+ (tested on 23.05)
- Ansible 2.10+
- Python 3 on the control node

## Installation

### From GitHub

```bash
ansible-galaxy collection install git+https://github.com/harley-systems/ansible-collection-openwrt.git
```

### From source

```bash
git clone https://github.com/harley-systems/ansible-collection-openwrt.git
cd ansible-collection-openwrt
ansible-galaxy collection build
ansible-galaxy collection install harley-openwrt-*.tar.gz
```

## Roles

| Role | Description |
|------|-------------|
| `harley.openwrt.base` | Initial setup: Python, pip, SFTP, ansible user |
| `harley.openwrt.network` | WAN, LAN, WiFi configuration |
| `harley.openwrt.firewall` | Firewall zones and rules |
| `harley.openwrt.dhcp_dns` | DHCP server and DNS configuration |
| `harley.openwrt.ipsec` | StrongSwan IPsec VPN |
| `harley.openwrt.acme` | ACME/Let's Encrypt certificates |
| `harley.openwrt.ddns` | Dynamic DNS |
| `harley.openwrt.webui` | LuCI HTTPS configuration |

## Quick Start

```yaml
# playbook.yml
- hosts: router
  collections:
    - harley.openwrt

  roles:
    - role: base
    - role: network
      vars:
        wan_proto: pppoe
        wan_username: "{{ vault_isp_username }}"
        wan_password: "{{ vault_isp_password }}"
        lan_ipaddr: "192.168.1.1"
        lan_netmask: "255.255.255.0"
    - role: firewall
    - role: dhcp_dns
      vars:
        dns_domain: "home.example.com"
    - role: ipsec
      vars:
        ipsec_connections:
          - name: road-warrior
            type: responder
            # ... see role defaults for options
    - role: acme
      vars:
        acme_email: "admin@example.com"
        acme_domain: "*.home.example.com"
        acme_dns_provider: cloudflare
```

## Plugins

### Modules

- `harley.openwrt.uci` - Manage OpenWRT UCI configuration

### Filters

- `host_names_to_ip_addresses` - Convert hostnames to IPs from inventory

## Documentation

See [docs/](docs/) for detailed configuration examples and VPN setup guides.

## License

MIT

## Author

Aharon Haravon ([@aharonh](https://github.com/aharonh))
