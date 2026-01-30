# harley.openwrt.dhcp_dns

Configure dnsmasq DHCP server and DNS.

## Description

This role configures OpenWRT's dnsmasq for DHCP and local DNS:

- Configure DHCP ranges for LAN/WAN interfaces
- Set local domain name
- Create static DHCP leases
- Create DNS A records for local hosts
- Create DNS CNAME records

## Requirements

- OpenWRT 21.02+
- `harley.openwrt.base` role (or Python already installed)

## Role Variables

### Basic Settings

```yaml
# Local domain name
dhcp_dns_domain: lan

# LAN DHCP settings
dhcp_dns_lan_enabled: true
dhcp_dns_lan_interface: lan
dhcp_dns_lan_start: 100        # First IP offset
dhcp_dns_lan_limit: 150        # Pool size
dhcp_dns_lan_leasetime: 12h

# WAN DHCP (usually disabled)
dhcp_dns_wan_enabled: false
```

### Static DHCP Leases

```yaml
dhcp_dns_static_leases:
  - name: myserver
    mac: "aa:bb:cc:dd:ee:ff"
    ip: "192.168.1.10"
  - name: nas
    mac: "11:22:33:44:55:66"
    ip: "192.168.1.20"
```

### DNS A Records

```yaml
dhcp_dns_hosts:
  - name: myserver
    ip: "192.168.1.10"
  - name: nas
    ip: "192.168.1.20"
  - name: printer
    ip: "192.168.1.30"
```

### DNS CNAME Records

```yaml
dhcp_dns_cnames:
  - alias: www
    target: myserver.lan
  - alias: files
    target: nas.lan
  - alias: git
    target: myserver.lan
```

### Additional DHCP Options

```yaml
dhcp_dns_lan_options:
  - "6,192.168.1.1"      # DNS server
  - "15,home.lan"         # Domain name
  - "3,192.168.1.1"       # Gateway
```

## Dependencies

None, but typically used after `harley.openwrt.base` and `harley.openwrt.network`.

## Example Playbook

### Basic home network

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.dhcp_dns
      vars:
        dhcp_dns_domain: home.lan
        dhcp_dns_lan_start: 100
        dhcp_dns_lan_limit: 100

        dhcp_dns_static_leases:
          - name: server
            mac: "aa:bb:cc:dd:ee:ff"
            ip: "192.168.1.10"

        dhcp_dns_hosts:
          - name: server
            ip: "192.168.1.10"

        dhcp_dns_cnames:
          - alias: git
            target: server.home.lan
          - alias: www
            target: server.home.lan
```

### Using inventory data

```yaml
# In your playbook, transform inventory to role variables:
- hosts: router
  vars:
    # Build lists from inventory
    _static_leases: >-
      {{ groups['all'] | map('extract', hostvars)
         | selectattr('mac_address', 'defined')
         | map(attribute=['inventory_hostname', 'mac_address', 'ip_address'])
         | list }}
  roles:
    - role: harley.openwrt.dhcp_dns
      vars:
        dhcp_dns_domain: "{{ dns_domain }}"
        dhcp_dns_static_leases: "{{ _static_leases }}"
```

### Office network with VLANs

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.dhcp_dns
      vars:
        dhcp_dns_domain: office.local
        dhcp_dns_lan_start: 50
        dhcp_dns_lan_limit: 200
        dhcp_dns_lan_leasetime: 8h

        dhcp_dns_lan_options:
          - "6,192.168.1.1,8.8.8.8"  # Primary + fallback DNS
          - "15,office.local"

        dhcp_dns_static_leases:
          - { name: printer, mac: "00:11:22:33:44:55", ip: "192.168.1.10" }
          - { name: ap1, mac: "aa:bb:cc:dd:ee:01", ip: "192.168.1.11" }
          - { name: ap2, mac: "aa:bb:cc:dd:ee:02", ip: "192.168.1.12" }
```

## Tags

- `dhcp_dns` - All tasks
- `dhcp_wan` - WAN DHCP configuration
- `dhcp_lan` - LAN DHCP configuration
- `dns_domain` - Domain name configuration
- `dhcp_options` - DHCP options
- `dhcp_static` - Static leases
- `dns_hosts` - DNS A records
- `dns_cnames` - DNS CNAME records

## Notes

- OpenWRT's default dnsmasq settings (rebind protection, etc.) are left unchanged
- Static leases automatically register hostnames in DNS
- For complex inventory-based configurations, transform data in your playbook

## License

MIT

## Author

Aharon Haravon
