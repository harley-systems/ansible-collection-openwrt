# harley.openwrt.webui

Configure uhttpd with HTTPS/TLS for LuCI web interface.

## Description

This role configures the OpenWRT uhttpd web server for secure HTTPS access:

- Installs TLS packages (px5g-mbedtls, luci-ssl, luci-app-uhttpd)
- Optionally copies custom SSL certificate and key
- Configures uhttpd listen addresses for HTTP and HTTPS
- Optionally redirects HTTP to HTTPS

## Requirements

- OpenWRT 21.02+
- `harley.openwrt.base` role (or Python already installed)

## Role Variables

### Optional Variables

```yaml
# Certificate configuration
webui_copy_certs: false              # Set true to copy certs from controller
webui_cert_path: /etc/uhttpd.crt     # Path on router for certificate
webui_key_path: /etc/uhttpd.key      # Path on router for private key

# Source paths (required if webui_copy_certs: true)
webui_cert_src: "files/etc/router.crt"
webui_key_src: "files/etc/router.key"

# Listen configuration
webui_listen_ip: "{{ lan_ip_address | default('0.0.0.0') }}"
webui_http_port: 80
webui_https_port: 443

# Redirect HTTP to HTTPS
webui_redirect_https: true
```

## Dependencies

None, but typically used after `harley.openwrt.base`.

## Example Playbook

### Basic - Use auto-generated certificate

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.webui
      vars:
        webui_listen_ip: "192.168.1.1"
        webui_redirect_https: true
```

### With custom certificate

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.webui
      vars:
        webui_copy_certs: true
        webui_cert_src: "files/certs/router.crt"
        webui_key_src: "files/certs/router.key"
        webui_cert_path: /etc/ssl/router.crt
        webui_key_path: /etc/ssl/router.key
```

### With ACME certificate (from acme role)

```yaml
- hosts: router
  roles:
    - role: harley.openwrt.acme
      vars:
        acme_domain: "*.home.example.com"
    - role: harley.openwrt.webui
      vars:
        webui_cert_path: /etc/acme/*.home.example.com_ecc/fullchain.cer
        webui_key_path: /etc/acme/*.home.example.com_ecc/*.home.example.com.key
```

## Tags

- `webui` - All tasks
- `webui_packages` - Package installation only
- `webui_certs` - Certificate copy only
- `webui_config` - UCI configuration only

## License

MIT

## Author

Aharon Haravon
