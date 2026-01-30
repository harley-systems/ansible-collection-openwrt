# harley.openwrt.ddns

Dynamic DNS client configuration.

## Description

This role configures the OpenWRT DDNS client:

- Installs ddns-scripts and luci-app-ddns
- Installs provider-specific scripts as needed
- Configures one or more DDNS services
- Supports all major DDNS providers

## Requirements

- OpenWRT 21.02+
- `harley.openwrt.base` role (or Python already installed)

## Role Variables

### Optional Variables

```yaml
# Enable DDNS service
ddns_enabled: false

# Global settings
ddns_date_format: "%F %R"
ddns_log_lines: 250
ddns_allow_private_ip: false

# DDNS services (list)
ddns_services: []
```

### Service Configuration

Each service in `ddns_services` supports:

```yaml
ddns_services:
  - name: my_ddns              # Unique service name
    enabled: true              # Enable this service
    provider: cloudflare.com-v4  # DDNS provider
    domain: vpn.example.com    # Domain to update
    lookup_host: vpn.example.com  # Host to check (default: domain)
    username: "zone_id"        # Provider username/ID
    password: "api_token"      # Provider password/token
    ip_source: interface       # interface, network, web, script
    ip_interface: pppoe-wan    # Interface for IP (if ip_source=interface)
    interface: wan             # Trigger interface
    use_https: true            # Use HTTPS for updates
    use_syslog: true           # Log to syslog
    check_interval: 10         # Check interval
    check_unit: minutes        # minutes, hours, days
    force_interval: 72         # Force update interval
    force_unit: hours          # minutes, hours, days
```

## Supported Providers

Common providers (install additional scripts as needed):

| Provider | service_name | Notes |
|----------|--------------|-------|
| Cloudflare | `cloudflare.com-v4` | Use Zone ID + API Token |
| DynDNS | `dyndns.org` | |
| No-IP | `no-ip.com` | |
| FreeDNS | `freedns.afraid.org` | |
| Namecheap | `namecheap.com` | |
| GoDaddy | `godaddy.com-v1` | |
| AWS Route53 | `route53-v1` | |
| Duck DNS | `duckdns.org` | |

See `opkg list | grep ddns-scripts` for all available provider scripts.

## Dependencies

None, but typically used after `harley.openwrt.base`.

## Example Playbook

### Cloudflare DDNS

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.ddns
      vars:
        ddns_enabled: true
        ddns_services:
          - name: cloudflare_vpn
            enabled: true
            provider: cloudflare.com-v4
            domain: vpn.example.com
            username: "{{ vault_cf_zone_id }}"
            password: "{{ vault_cf_api_token }}"
            ip_source: interface
            ip_interface: pppoe-wan
            interface: wan
```

### Multiple services

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.ddns
      vars:
        ddns_enabled: true
        ddns_services:
          - name: primary_ddns
            provider: cloudflare.com-v4
            domain: home.example.com
            username: "{{ vault_cf_zone_id }}"
            password: "{{ vault_cf_api_token }}"
            ip_interface: pppoe-wan

          - name: backup_ddns
            provider: duckdns.org
            domain: myhome
            password: "{{ vault_duckdns_token }}"
            ip_interface: pppoe-wan
```

### Disabled (install only)

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.ddns
      vars:
        ddns_enabled: false  # Install packages but don't enable
```

## Tags

- `ddns` - All tasks
- `ddns_packages` - Package installation only
- `ddns_config` - Configuration only
- `ddns_service` - Service enable/start only

## License

MIT

## Author

Aharon Haravon
