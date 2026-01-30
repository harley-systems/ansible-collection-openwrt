# harley.openwrt.base

Initial OpenWRT setup for Ansible management.

## Description

This role prepares a fresh OpenWRT installation for ongoing Ansible management by:

- Installing Python3 (required for Ansible modules)
- Installing pip3 and virtualenv
- Installing SFTP server (required for Ansible file transfers)
- Installing user management tools (useradd, groupadd, sudo)
- Creating an ansible user with SSH key authentication

## Requirements

- Fresh OpenWRT installation (21.02+)
- SSH access as root (for initial run)

## Role Variables

### Required Variables

```yaml
base_ansible_authorized_key: "ssh-rsa AAAA..."  # SSH public key for ansible user
base_ansible_password: "secure_password"         # Password for ansible user
```

### Optional Variables

```yaml
# Ansible user configuration
base_ansible_user: ansible              # Username to create
base_ansible_user_id: 1000              # UID/GID for the user
base_ansible_user_groups: "adm,ansible,wheel"
base_ansible_user_shell: /bin/ash
base_ansible_user_home: /home/ansible

# First-run credentials (for initial connection as root)
base_first_run_user: root
base_first_run_password: ""

# Feature toggles
base_install_python: true
base_install_pip: true
base_install_sftp: true
base_install_sudo: true
base_update_packages: true
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: router
  gather_facts: false  # Can't gather facts until Python is installed

  roles:
    - role: harley.openwrt.base
      vars:
        base_ansible_authorized_key: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
        base_ansible_password: "{{ vault_ansible_password }}"
        base_first_run_user: root
        base_first_run_password: ""
```

## Tags

- `base` - All tasks
- `detect_connection` - Connection detection only
- `update_packages` - Package list update only
- `install_python3` - Python installation only
- `install_pip3` - Pip installation only
- `install_sftp` - SFTP server only
- `install_user_management` - User tools and sudo only
- `create_ansible_user` - User creation only

## License

MIT

## Author

Aharon Haravon
