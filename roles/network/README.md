# harley.openwrt.network

Configure WAN, LAN, and WiFi interfaces.

## Description

This role configures OpenWRT network interfaces:

- WAN interface (PPPoE, DHCP, or static IP)
- LAN interface (static IP, bridge)
- WiFi radios and access points

## Requirements

- OpenWRT 21.02+
- `harley.openwrt.base` role (or Python already installed)

## Role Variables

### WAN Configuration

```yaml
network_wan_enabled: true
network_wan_interface: wan
network_wan_proto: dhcp          # dhcp, pppoe, static

# PPPoE settings
network_wan_username: "user@isp"
network_wan_password: "secret"
network_wan_keepalive: 0

# Static IP settings
network_wan_ipaddr: "203.0.113.10"
network_wan_netmask: "255.255.255.0"
network_wan_gateway: "203.0.113.1"
network_wan_dns: "8.8.8.8 8.8.4.4"

# Physical interface
network_wan_ifname: "eth1.2"

# IPv6
network_wan_ipv6: auto
```

### LAN Configuration

```yaml
network_lan_enabled: true
network_lan_interface: lan
network_lan_proto: static
network_lan_ipaddr: "192.168.1.1"
network_lan_netmask: "255.255.255.0"

# Optional
network_lan_ifname: "eth0.1"
network_lan_type: bridge
network_lan_dns: "192.168.1.1"
```

### WiFi Configuration

```yaml
network_wifi_enabled: true
network_wifi_radios:
  # 5GHz radio
  - name: radio0
    interface: default_radio0
    enabled: true
    country: US
    channel: 36
    htmode: VHT80
    txpower: 20
    ssid: "MyNetwork-5G"
    encryption: psk2
    key: "{{ vault_wifi_password }}"

  # 2.4GHz radio
  - name: radio1
    interface: default_radio1
    enabled: true
    country: US
    channel: 6
    htmode: HT40
    txpower: 20
    legacy_rates: true
    ssid: "MyNetwork"
    encryption: psk2
    key: "{{ vault_wifi_password }}"
```

### WiFi Radio Options

| Option | Default | Description |
|--------|---------|-------------|
| `name` | - | Radio section name (radio0, radio1) |
| `interface` | - | Interface section name |
| `enabled` | true | Enable radio |
| `country` | US | Country code for regulations |
| `channel` | auto | WiFi channel |
| `htmode` | - | Channel width (HT20, VHT80, etc.) |
| `txpower` | 20 | Transmit power in dBm |
| `legacy_rates` | false | Enable legacy rates |
| `distance` | 20 | Distance optimization (meters) |
| `network` | lan | Network to bridge to |
| `mode` | ap | Mode (ap, sta, adhoc) |
| `ssid` | - | Network name |
| `encryption` | psk2 | Encryption (none, psk, psk2, sae) |
| `key` | - | WiFi password |
| `macaddr` | - | Override MAC address |
| `hidden` | false | Hide SSID |

## Dependencies

None.

## Example Playbook

### Home router with PPPoE

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.network
      vars:
        # WAN - PPPoE
        network_wan_proto: pppoe
        network_wan_username: "{{ vault_isp_username }}"
        network_wan_password: "{{ vault_isp_password }}"
        network_wan_ifname: eth1.2

        # LAN
        network_lan_ipaddr: "10.0.0.1"
        network_lan_netmask: "255.255.255.0"

        # WiFi
        network_wifi_enabled: true
        network_wifi_radios:
          - name: radio0
            interface: default_radio0
            country: US
            channel: 36
            htmode: VHT80
            ssid: "Home-5G"
            key: "{{ vault_wifi_password }}"

          - name: radio1
            interface: default_radio1
            country: US
            channel: 1
            htmode: HT40
            legacy_rates: true
            ssid: "Home"
            key: "{{ vault_wifi_password }}"
```

### Office with static WAN IP

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.network
      vars:
        network_wan_proto: static
        network_wan_ipaddr: "203.0.113.50"
        network_wan_netmask: "255.255.255.0"
        network_wan_gateway: "203.0.113.1"
        network_wan_dns: "8.8.8.8"

        network_lan_ipaddr: "192.168.10.1"
        network_lan_netmask: "255.255.255.0"
```

### Disable WiFi

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.network
      vars:
        network_wifi_enabled: false
```

## Tags

- `network` - All tasks
- `network_wan` - WAN configuration only
- `network_lan` - LAN configuration only
- `network_wifi` - WiFi configuration only

## Notes

- Changing LAN IP may disconnect Ansible mid-playbook
- Consider changing LAN IP manually before running playbook
- WiFi changes trigger `wifi reload` which briefly disrupts connections

## License

MIT

## Author

Aharon Haravon
