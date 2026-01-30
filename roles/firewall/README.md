# harley.openwrt.firewall

Configure OpenWRT firewall zones, rules, and forwarding.

## Description

This role configures the OpenWRT firewall (`/etc/config/firewall`):

- Default policies (input, output, forward)
- Firewall zones (lan, wan, custom)
- Zone forwarding rules
- Standard OpenWRT rules (DHCP, ping, ICMPv6)
- IPSec/VPN rules (optional)
- Custom firewall rules

## Requirements

- OpenWRT 21.02+

## Role Variables

### Default Policies

```yaml
firewall_syn_flood: true
firewall_input: ACCEPT
firewall_output: ACCEPT
firewall_forward: REJECT
```

### Zones

```yaml
firewall_zones:
  - name: lan
    input: ACCEPT
    output: ACCEPT
    forward: ACCEPT
    network: lan

  - name: wan
    input: REJECT
    output: ACCEPT
    forward: REJECT
    masq: true
    mtu_fix: true
    network: "wan wan6"

# Additional zones (VPN, guest, etc.)
firewall_extra_zones:
  - name: guest
    input: REJECT
    output: ACCEPT
    forward: REJECT
    network: guest
```

### Zone Options

| Option | Default | Description |
|--------|---------|-------------|
| `name` | - | Zone name (required) |
| `input` | ACCEPT | Default input policy |
| `output` | ACCEPT | Default output policy |
| `forward` | REJECT/ACCEPT | Default forward policy |
| `masq` | false | Enable masquerading (NAT) |
| `mtu_fix` | false | Enable MSS clamping |
| `network` | - | Network interface(s) |
| `devices` | - | List of device patterns |

### Forwarding Rules

```yaml
firewall_forwardings:
  - src: lan
    dest: wan

# Additional forwardings
firewall_extra_forwardings:
  - src: guest
    dest: wan
```

### Standard Rules

```yaml
# Include standard OpenWRT rules (DHCP, ping, ICMPv6)
firewall_include_standard_rules: true
```

### IPSec/VPN Rules

```yaml
# Enable IPSec firewall rules
firewall_ipsec_enabled: false

# VPN zone devices pattern
firewall_ipsec_devices:
  - "vpn-*"

# VPN subnet for forwarding rules
firewall_vpn_subnet: "10.42.0.0/16"
```

### Custom Rules

```yaml
firewall_rules:
  - name: Allow-SSH
    src: wan
    proto: tcp
    dest_port: 22
    target: ACCEPT

  - name: Allow-HTTP
    src: wan
    proto: tcp
    dest_port: 80
    target: ACCEPT

  - name: Block-Subnet
    src: wan
    src_ip: "192.168.100.0/24"
    target: REJECT
    enabled: false
```

### Rule Options

| Option | Description |
|--------|-------------|
| `name` | Rule name (required) |
| `enabled` | Enable/disable rule |
| `src` | Source zone |
| `src_ip` | Source IP/subnet |
| `src_port` | Source port(s) |
| `dest` | Destination zone |
| `dest_ip` | Destination IP/subnet |
| `dest_port` | Destination port(s) |
| `proto` | Protocol (tcp, udp, icmp, etc.) |
| `family` | Address family (ipv4, ipv6) |
| `icmp_type` | ICMP type (string or list) |
| `limit` | Rate limit (e.g., "10/sec") |
| `target` | Action (ACCEPT, REJECT, DROP) |

### Includes

```yaml
# Include custom firewall script
firewall_include_user: true
firewall_user_include: /etc/firewall.user
```

## Dependencies

None.

## Example Playbook

### Basic home router

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.firewall
      vars:
        firewall_zones:
          - name: lan
            input: ACCEPT
            output: ACCEPT
            forward: ACCEPT
            network: lan

          - name: wan
            input: REJECT
            output: ACCEPT
            forward: REJECT
            masq: true
            mtu_fix: true
            network: "wan wan6"

        firewall_forwardings:
          - src: lan
            dest: wan
```

### With guest network

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.firewall
      vars:
        firewall_extra_zones:
          - name: guest
            input: REJECT
            output: ACCEPT
            forward: REJECT
            network: guest

        firewall_extra_forwardings:
          - src: guest
            dest: wan

        firewall_rules:
          - name: Guest-DNS
            src: guest
            proto: "tcp udp"
            dest_port: 53
            target: ACCEPT

          - name: Guest-DHCP
            src: guest
            proto: udp
            dest_port: 67
            target: ACCEPT
```

### With IPSec VPN

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.firewall
      vars:
        firewall_ipsec_enabled: true
        firewall_ipsec_devices:
          - "vpn-*"
        firewall_vpn_subnet: "10.42.0.0/16"
```

### Allow SSH from WAN

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.firewall
      vars:
        firewall_rules:
          - name: Allow-SSH
            src: wan
            proto: tcp
            dest_port: 22
            target: ACCEPT
```

## Tags

- `firewall` - All tasks
- `firewall_config` - Main configuration
- `firewall_user` - User include file

## Notes

- Changes trigger `firewall reload` which briefly interrupts connections
- The `firewall_include_standard_rules` option adds OpenWRT's default rules for DHCP, ping, and IPv6
- IPSec rules automatically create a `vpn` zone and forwarding rules to/from lan and wan

## License

MIT

## Author

Aharon Haravon
