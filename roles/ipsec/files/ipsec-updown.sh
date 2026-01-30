#!/bin/bash
#
# ipsec-updown.sh - StrongSwan updown script for VTI tunnel management
#
# This script is called by StrongSwan when IPsec connections are established
# or terminated. It creates/destroys VTI interfaces and manages routing.
#
# Usage in ipsec.conf:
#   leftupdown="/etc/ipsec.d/ipsec-updown.sh -ln <name> -ll <local-ip> -lr <remote-ip> -m <mark> -r <route>"
#
# Parameters:
#   -ln, --link-name     VTI interface name (e.g., vpn-rw-1)
#   -ll, --link-local    Local IP address for tunnel interface (e.g., 10.42.255.254/32)
#   -lr, --link-remote   Remote IP address for tunnel interface (e.g., 10.42.0.1/32)
#   -m,  --mark          XFRM mark for policy matching (e.g., 200)
#   -r,  --static-route  Network(s) to route through tunnel, comma-separated
#
# Dynamic Placeholders (for road-warrior connections):
#   %vip  - Replaced with PLUTO_PEER_SOURCEIP (virtual IP assigned to client)
#   %id   - Replaced with PLUTO_UNIQUEID (unique connection identifier)
#
# Example for road-warrior:
#   leftupdown="/etc/ipsec.d/ipsec-updown.sh -ln vpn-rw-%id -ll 10.42.255.254/32 -lr %vip/32 -m 200 -r %vip/32"
#
#   When client connects with virtual IP 10.42.0.1 and unique ID 7:
#     -ln vpn-rw-%id  -> vpn-rw-7
#     -lr %vip/32     -> 10.42.0.1/32
#     -r  %vip/32     -> 10.42.0.1/32
#
# StrongSwan Environment Variables (provided automatically):
#   PLUTO_VERB           - Action: up-client, down-client, etc.
#   PLUTO_INTERFACE      - Physical interface (e.g., pppoe-wan)
#   PLUTO_ME             - Our public IP address
#   PLUTO_PEER           - Remote peer's public IP address
#   PLUTO_PEER_SOURCEIP  - Virtual IP assigned to remote peer (road-warrior)
#   PLUTO_UNIQUEID       - Unique connection identifier
#

while [[ $# > 1 ]]; do
	case ${1} in
		-ln|--link-name)
			TUNNEL_NAME="${2}"
			TUNNEL_PHY_INTERFACE="${PLUTO_INTERFACE}"
			shift
			;;
		-ll|--link-local)
			TUNNEL_LOCAL_ADDRESS="${2}"
			TUNNEL_LOCAL_ENDPOINT="${PLUTO_ME}"
			shift
			;;
		-lr|--link-remote)
			TUNNEL_REMOTE_ADDRESS="${2}"
			TUNNEL_REMOTE_ENDPOINT="${PLUTO_PEER}"
			shift
			;;
		-m|--mark)
			TUNNEL_MARK="${2}"
			shift
			;;
		-r|--static-route)
			TUNNEL_STATIC_ROUTE="${2}"
			shift
			;;
		*)
			echo "${0}: Unknown argument \"${1}\"" >&2
			;;
	esac
	shift
done

# Expand dynamic placeholders for road-warrior support
# See header comments for full documentation
expand_placeholders() {
	# %vip  -> PLUTO_PEER_SOURCEIP (virtual IP assigned to client)
	# %id   -> PLUTO_UNIQUEID (unique connection identifier)
	local value="$1"
	value="${value//%vip/${PLUTO_PEER_SOURCEIP}}"
	value="${value//%id/${PLUTO_UNIQUEID}}"
	echo "$value"
}

TUNNEL_NAME=$(expand_placeholders "$TUNNEL_NAME")
TUNNEL_REMOTE_ADDRESS=$(expand_placeholders "$TUNNEL_REMOTE_ADDRESS")
TUNNEL_STATIC_ROUTE=$(expand_placeholders "$TUNNEL_STATIC_ROUTE")

command_exists() {
	type "$1" >&2 2>&2
}

create_interface() {
	ip link add ${TUNNEL_NAME} type vti local ${TUNNEL_LOCAL_ENDPOINT} remote ${TUNNEL_REMOTE_ENDPOINT} key ${TUNNEL_MARK}
	ip addr add ${TUNNEL_LOCAL_ADDRESS} remote ${TUNNEL_REMOTE_ADDRESS} dev ${TUNNEL_NAME}
	ip link set ${TUNNEL_NAME} up mtu 1419
}

configure_sysctl() {
	sysctl -w net.ipv4.ip_forward=1
	sysctl -w net.ipv4.conf.${TUNNEL_NAME}.rp_filter=2
	sysctl -w net.ipv4.conf.${TUNNEL_NAME}.disable_policy=1
}

add_route() {
	IFS=',' read -ra route <<< "${TUNNEL_STATIC_ROUTE}"
    	for i in "${route[@]}"; do
	    ip route add ${i} dev ${TUNNEL_NAME} metric ${TUNNEL_MARK}
	    # Remove conflicting route from table 220 (StrongSwan adds a route
	    # via the default gateway which conflicts with VTI routing)
	    ip route del ${i} table 220 2>/dev/null || true
	done
	iptables -t mangle -A FORWARD -o ${TUNNEL_NAME} -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
	iptables -t mangle -A INPUT -p esp -s ${TUNNEL_REMOTE_ENDPOINT} -d ${TUNNEL_LOCAL_ENDPOINT} -j MARK --set-xmark ${TUNNEL_MARK}
}

cleanup() {
        IFS=',' read -ra route <<< "${TUNNEL_STATIC_ROUTE}"
        for i in "${route[@]}"; do
            ip route del ${i} dev ${TUNNEL_NAME} metric ${TUNNEL_MARK}
        done
	iptables -t mangle -D FORWARD -o ${TUNNEL_NAME} -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
	iptables -t mangle -D INPUT -p esp -s ${TUNNEL_REMOTE_ENDPOINT} -d ${TUNNEL_LOCAL_ENDPOINT} -j MARK --set-xmark ${TUNNEL_MARK}
	ip route flush cache
}

delete_interface() {
	ip link set ${TUNNEL_NAME} down
	ip link del ${TUNNEL_NAME}
}

# main execution starts here

command_exists ip || echo "ERROR: ip command is required to execute the script, check if you are running as root, mostly to do with path, /sbin/" >&2 2>&2
command_exists iptables || echo "ERROR: iptables command is required to execute the script, check if you are running as root, mostly to do with path, /sbin/" >&2 2>&2
command_exists sysctl || echo "ERROR: sysctl command is required to execute the script, check if you are running as root, mostly to do with path, /sbin/" >&2 2>&2

case "${PLUTO_VERB}" in
	up-client)
		create_interface
		configure_sysctl
		add_route
		;;
	down-client)
		cleanup
		delete_interface
		;;
esac
