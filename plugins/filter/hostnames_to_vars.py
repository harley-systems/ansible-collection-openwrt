#!/usr/bin/python
class FilterModule(object):
    def filters(self):
        return {
            'host_names_to_ip_addresses': self.host_names_to_ip_addresses
        }

    def host_names_to_ip_addresses(self, hostnames, hostvars):
        ip_addresses = [ hostvars[host]['ip_address'] for host in hostnames ]
        return ip_addresses
