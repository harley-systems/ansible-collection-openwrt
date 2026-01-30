# harley.openwrt.ipsec

Configure StrongSwan IPSec VPN on OpenWRT.

## Description

This role installs and configures StrongSwan for IPSec VPN connectivity:

- Road-warrior VPN gateway (mobile clients)
- Site-to-site VPN (connect networks)
- Cloud VPN (AWS, Azure, etc.)
- Certificate-based (RSA) and PSK authentication

## Requirements

- OpenWRT 21.02+
- Sufficient storage for StrongSwan packages (~2MB)

## Role Variables

### StrongSwan Global Settings

```yaml
ipsec_charondebug: "ike 2, knl 2, cfg 2, net 2, esp 2, dmn 2, mgr 2"
ipsec_uniqueids: true

# IKE proposals
ipsec_ike_default: >-
  aes128-sha256-modp2048,
  aes256-sha256-modp2048

# ESP proposals
ipsec_esp_default: >-
  aes128-sha256,
  aes256-sha256

# Dead Peer Detection
ipsec_dpdaction: clear    # none, clear, hold, restart
ipsec_dpddelay: 300s

# Authentication
ipsec_leftauth: pubkey
ipsec_rightauth: pubkey
```

### Certificates

```yaml
# CA certificates -> /etc/ipsec.d/cacerts/
ipsec_ca_certs:
  - src: files/rootCA.der
    dest: rootCA.der

# Host certificates -> /etc/ipsec.d/certs/
ipsec_host_certs:
  - src: files/vpnCert.der
    dest: vpnCert.der

# Private keys -> /etc/ipsec.d/private/
ipsec_private_keys:
  - src: files/vpnKey.der
    dest: vpnKey.der
```

### Secrets

```yaml
# RSA key path (for certificate auth)
ipsec_rsa_key: "/etc/ipsec.d/private/vpnKey.der"

# PSK secrets (for pre-shared key auth)
ipsec_psk_secrets:
  - local: "192.168.1.1"
    remote: "203.0.113.50"
    secret: "{{ vault_ipsec_psk }}"
```

### Connections

```yaml
ipsec_connections:
  - name: my-vpn
    enabled: start      # start, add, route, ignore
    mark: 100
    type: tunnel

    # Local side
    left: "%any"
    leftid: "C=US, O=MyOrg, CN=vpn.example.com"
    leftsubnet: "192.168.1.0/24"
    leftcert: vpnCert.der
    leftsendcert: always
    leftupdown: "/etc/ipsec.d/ipsec-updown.sh ..."

    # Remote side
    right: "vpn.remote.com"
    rightid: "C=US, O=Remote, CN=vpn.remote.com"
    rightsubnet: "10.0.0.0/24"
    rightcert: remoteCert.der
    rightsourceip: "10.42.0.0/16"   # For road-warrior
    rightdns: "8.8.8.8"
    rightca: "C=US, O=MyOrg, CN=MyOrg CA"
```

## Connection Examples

### Road-Warrior Gateway

Accept VPN connections from mobile clients:

```yaml
ipsec_connections:
  - name: road-warrior
    mark: 200
    type: tunnel
    left: "%any"
    leftid: "C=US, O=MyOrg, CN=vpn.example.com"
    leftsubnet: "0.0.0.0/0"
    leftcert: vpnCert.der
    leftsendcert: always
    leftupdown: "/etc/ipsec.d/ipsec-updown.sh -ln vpn-rw-%id -ll 10.42.255.254/32 -lr %vip/32 -m 200 -r %vip/32"
    right: "%any"
    rightsourceip: "10.42.0.0/16"
    rightdns: "8.8.8.8,2001:4860:4860::8888"
    rightca: "C=US, O=MyOrg, CN=MyOrg CA"
```

### Site-to-Site Responder

Accept connections from a remote site:

```yaml
ipsec_connections:
  - name: remote-site
    mark: 100
    type: tunnel
    left: "%any"
    leftsubnet: "192.168.1.0/24"
    leftcert: vpnCert.der
    leftsendcert: always
    leftupdown: "/etc/ipsec.d/ipsec-updown.sh -ln vpn-site -lr 169.254.71.2/30 -ll 169.254.71.1/30 -m 100 -r 10.0.0.0/24"
    right: "%any"
    rightca: "C=US, O=RemoteSite, CN=RemoteSite CA"
    rightsubnet: "10.0.0.0/24"
    rightid: "C=US, O=RemoteSite, CN=remote@example.com"
```

### Site-to-Site Initiator

Connect to a remote VPN gateway:

```yaml
ipsec_connections:
  - name: cloud-site
    enabled: start
    mark: 102
    type: tunnel
    leftcert: clientCert.der
    leftsubnet: "192.168.1.0/24"
    leftupdown: "/etc/ipsec.d/ipsec-updown.sh -ln vpn-cloud -ll 169.254.71.10/30 -lr 169.254.71.9/30 -m 102 -r 172.16.0.0/16"
    right: "vpn.remote-site.com"
    rightid: "C=US, O=RemoteSite, CN=vpn.remote-site.com"
    rightcert: remoteCert.der
    rightsubnet: "172.16.0.0/16"
```

## Updown Script

The included `ipsec-updown.sh` script manages VTI (Virtual Tunnel Interface) creation:

**Parameters:**
- `-ln, --link-name` - VTI interface name
- `-ll, --link-local` - Local tunnel IP
- `-lr, --link-remote` - Remote tunnel IP
- `-m, --mark` - XFRM mark
- `-r, --static-route` - Routes (comma-separated)

**Dynamic Placeholders (for road-warrior):**
- `%vip` - Client's virtual IP (PLUTO_PEER_SOURCEIP)
- `%id` - Unique connection ID (PLUTO_UNIQUEID)

## Dependencies

None.

## Example Playbook

### Road-Warrior VPN Gateway

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.ipsec
      vars:
        ipsec_ca_certs:
          - src: "{{ playbook_dir }}/files/certs/rootCA.der"
            dest: rootCA.der

        ipsec_host_certs:
          - src: "{{ playbook_dir }}/files/certs/vpnCert.der"
            dest: vpnCert.der

        ipsec_private_keys:
          - src: "{{ playbook_dir }}/files/certs/vpnKey.der"
            dest: vpnKey.der

        ipsec_rsa_key: "/etc/ipsec.d/private/vpnKey.der"

        ipsec_connections:
          - name: road-warrior
            mark: 200
            type: tunnel
            left: "%any"
            leftid: "C=US, O=MyOrg, CN=vpn.example.com"
            leftsubnet: "0.0.0.0/0"
            leftcert: vpnCert.der
            leftsendcert: always
            leftupdown: "/etc/ipsec.d/ipsec-updown.sh -ln vpn-rw-%id -ll 10.42.255.254/32 -lr %vip/32 -m 200 -r %vip/32"
            right: "%any"
            rightsourceip: "10.42.0.0/16"
            rightdns: "8.8.8.8"
            rightca: "C=US, O=MyOrg, CN=MyOrg CA"
```

### Combined Road-Warrior and Site-to-Site

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.ipsec
      vars:
        ipsec_ca_certs:
          - src: files/certs/rootCA.der
            dest: rootCA.der
          - src: files/certs/subCA.der
            dest: subCA.der

        ipsec_host_certs:
          - src: files/certs/vpnCert.der
            dest: vpnCert.der
          - src: files/certs/clientCert.der
            dest: clientCert.der

        ipsec_private_keys:
          - src: files/certs/vpnKey.der
            dest: vpnKey.der

        ipsec_rsa_key: "/etc/ipsec.d/private/vpnKey.der"

        ipsec_connections:
          # Road-warrior gateway
          - name: road-warrior
            mark: 200
            type: tunnel
            left: "%any"
            leftsubnet: "0.0.0.0/0"
            leftcert: vpnCert.der
            leftsendcert: always
            leftupdown: "/etc/ipsec.d/ipsec-updown.sh -ln vpn-rw-%id -ll 10.42.255.254/32 -lr %vip/32 -m 200 -r %vip/32"
            right: "%any"
            rightsourceip: "10.42.0.0/16"
            rightca: "C=US, O=MyOrg, CN=MyOrg CA"

          # Site-to-site to cloud
          - name: cloud-site
            enabled: start
            mark: 100
            type: tunnel
            leftcert: clientCert.der
            leftsubnet: "192.168.1.0/24"
            leftupdown: "/etc/ipsec.d/ipsec-updown.sh -ln vpn-cloud -ll 169.254.71.10/30 -lr 169.254.71.9/30 -m 100 -r 172.16.0.0/16"
            right: "vpn.cloud-provider.com"
            rightsubnet: "172.16.0.0/16"
```

## Tags

- `ipsec` - All tasks
- `ipsec_packages` - Package installation
- `ipsec_dirs` - Directory creation
- `ipsec_certs` - Certificate deployment
- `ipsec_updown` - Updown script
- `ipsec_config` - Configuration files
- `ipsec_sysctl` - Sysctl settings
- `ipsec_autostart` - rc.local configuration

## Notes

- Keep private keys in Ansible Vault or a secure location
- The firewall role should be configured to allow IPSec traffic (UDP 500, 4500, ESP, AH)
- VTI interfaces are created dynamically by the updown script
- Each connection needs a unique mark value
- For road-warrior, ensure the virtual IP pool doesn't overlap with existing networks

## Troubleshooting

Check IPSec status:
```bash
ipsec statusall
```

View charon logs:
```bash
logread | grep charon
```

Test connection:
```bash
ipsec up <connection-name>
```

## License

MIT

## Author

Aharon Haravon
