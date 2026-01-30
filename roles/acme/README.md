# harley.openwrt.acme

Let's Encrypt certificates with DNS-01 validation.

## Description

This role configures ACME (Let's Encrypt) certificate automation:

- Installs ACME packages (acme, acme-acmesh-dnsapi, luci-app-acme)
- Configures DNS-01 challenge with supported providers
- Supports wildcard certificates
- Optionally configures uhttpd to use the certificate

## Requirements

- OpenWRT 21.02+
- `harley.openwrt.base` role (or Python already installed)
- DNS provider API credentials

## Role Variables

### Required Variables

```yaml
acme_email: "admin@example.com"      # Let's Encrypt account email
acme_domain: "*.home.example.com"    # Domain(s) for certificate
```

### Provider Credentials (required, provider-specific)

#### Cloudflare (default)
```yaml
acme_dns_provider: dns_cf
acme_cf_token: "your-api-token"
acme_cf_zone_id: "your-zone-id"
```

#### GoDaddy
```yaml
acme_dns_provider: dns_gd
acme_gd_key: "your-key"
acme_gd_secret: "your-secret"
```

#### AWS Route53
```yaml
acme_dns_provider: dns_aws
acme_aws_access_key: "AKIA..."
acme_aws_secret_key: "..."
```

#### Other providers
```yaml
acme_dns_provider: dns_xxx  # See acme.sh dnsapi docs
acme_credentials:
  SOME_KEY: "value"
  ANOTHER_KEY: "value"
```

### Optional Variables

```yaml
# Certificate options
acme_key_type: ec-256          # ec-256, ec-384, rsa-2048, rsa-4096
acme_use_staging: false        # Use staging server for testing
acme_debug: false

# Certificate name in config
acme_cert_name: "wildcard_home_example_com"

# Auto-configure uhttpd
acme_configure_uhttpd: false

# Certificate directory (auto-calculated)
acme_cert_dir: "/etc/acme/{{ domain }}_ecc"
```

## Dependencies

None, but typically used after `harley.openwrt.base`.

## Example Playbook

### Cloudflare wildcard certificate

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.acme
      vars:
        acme_email: "admin@example.com"
        acme_domain: "*.home.example.com"
        acme_cf_token: "{{ vault_cf_token }}"
        acme_cf_zone_id: "{{ vault_cf_zone_id }}"
        acme_configure_uhttpd: true
```

### With webui role

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.acme
      vars:
        acme_email: "admin@example.com"
        acme_domain: "*.home.example.com"
        acme_cf_token: "{{ vault_cf_token }}"
        acme_cf_zone_id: "{{ vault_cf_zone_id }}"

    - role: harley.openwrt.webui
      vars:
        webui_cert_path: "/etc/acme/*.home.example.com_ecc/fullchain.cer"
        webui_key_path: "/etc/acme/*.home.example.com_ecc/*.home.example.com.key"
```

### RSA certificate with staging

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.acme
      vars:
        acme_email: "admin@example.com"
        acme_domain: "router.example.com"
        acme_key_type: rsa-2048
        acme_use_staging: true  # Test first!
        acme_cf_token: "{{ vault_cf_token }}"
        acme_cf_zone_id: "{{ vault_cf_zone_id }}"
```

## Certificate Paths

After successful issuance, certificates are stored at:

- **ECC keys**: `/etc/acme/<domain>_ecc/`
- **RSA keys**: `/etc/acme/<domain>/`

Files:
- `fullchain.cer` - Full certificate chain
- `<domain>.cer` - Certificate only
- `<domain>.key` - Private key
- `ca.cer` - CA certificate

## Tags

- `acme` - All tasks
- `acme_packages` - Package installation only
- `acme_config` - Configuration only
- `acme_credentials` - Credentials deployment only
- `acme_service` - Service enable/start only
- `acme_uhttpd` - uhttpd configuration only

## DNS Providers

See [acme.sh DNS API documentation](https://github.com/acmesh-official/acme.sh/wiki/dnsapi) for the full list of supported providers and their required credentials.

## License

MIT

## Author

Aharon Haravon
