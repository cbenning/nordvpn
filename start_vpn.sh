#!/bin/bash

[[ -n ${DEBUG} ]] && set -x
[[ -n ${COUNTRY} && -z ${NORDVPN_ENDPOINT} ]] && CONNECT=${COUNTRY}
[[ "${VPNGROUPID:-""}" =~ ^[0-9]+$ ]] && groupmod -g "VPNGROUPID" -o vpn

function killswitch() {
	iptables -F
	iptables -t nat -F
	iptables -X
	iptables -P INPUT DROP
	iptables -P FORWARD DROP
	iptables -P OUTPUT DROP
	iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	iptables -A INPUT -i lo -j ACCEPT
	iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	iptables -A FORWARD -i lo -j ACCEPT
	iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	iptables -A OUTPUT -o lo -j ACCEPT
	iptables -A OUTPUT -o tap+ -j ACCEPT
	iptables -A OUTPUT -o tun+ -j ACCEPT
	iptables -A OUTPUT -m owner --gid-owner vpn -j ACCEPT || {
		iptables -A OUTPUT -p udp -m udp --dport 53 -j ACCEPT
		iptables -A OUTPUT -p udp -m udp --dport 51820 -j ACCEPT
		iptables -A OUTPUT -p tcp -m tcp --dport 1194 -j ACCEPT
		iptables -A OUTPUT -p udp -m udp --dport 1194 -j ACCEPT
		iptables -A OUTPUT -p tcp -m tcp --dport 443 -j ACCEPT
		iptables -A OUTPUT -o eth0 -d api.nordvpn.com -j ACCEPT
	}
	iptables -t nat -A POSTROUTING -o tap+ -j MASQUERADE
	iptables -t nat -A POSTROUTING -o tun+ -j MASQUERADE
	if [[ -n ${WHITELIST_NETWORK_INTERFACES} ]]; then
		for interface in ${WHITELIST_INTERFACES//[;]/ }; do
			local network="$(ip -o addr show dev ${interface} | awk '$3 == "inet" {print $4}')"
			iptables -A INPUT -s "${network}" -j ACCEPT
			iptables -A FORWARD -d "${network}" -j ACCEPT
			iptables -A FORWARD -s "${network}" -j ACCEPT
			iptables -A OUTPUT -d "${network}" -j ACCEPT
		done
	fi
	[[ -n $WHITELIST_NETWORK_4 ]] && for network in ${WHITELIST_NETWORK4//[;]/ }; do route_create4 "${network}"; done
	[[ -n ${WHITELIST_DOMAINS} ]] && for domain in ${WHITELIST_DOMAINS//[;]/ }; do whitelist_add "${domain}"; done

	ip6tables -F 2>/dev/null
	ipttables -t nat -F 2>/dev/null
	ip6tables -X 2>/dev/null
	ip6tables -P INPUT DROP 2>/dev/null
	ip6tables -P FORWARD DROP 2>/dev/null
	ip6tables -P OUTPUT DROP 2>/dev/null
	ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null
	ip6tables -A INPUT -p icmp -j ACCEPT 2>/dev/null
	ip6tables -A INPUT -i lo -j ACCEPT 2>/dev/null
	ip6tables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null
	ip6tables -A FORWARD -p icmp -j ACCEPT 2>/dev/null
	ip6tables -A FORWARD -i lo -j ACCEPT 2>/dev/null
	ip6tables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null
	ip6tables -A OUTPUT -o lo -j ACCEPT 2>/dev/null
	ip6tables -A OUTPUT -o tap+ -j ACCEPT 2>/dev/null
	ip6tables -A OUTPUT -o tun+ -j ACCEPT 2>/dev/null
	ip6tables -A OUTPUT -m owner --gid-owner vpn -j ACCEPT 2>/dev/null || {
		ip6tables -A OUTPUT -p udp -m udp --dport 53 -j ACCEPT 2>/dev/null
		ip6tables -A OUTPUT -p udp -m udp --dport 51820 -j ACCEPT 2>/dev/null
		ip6tables -A OUTPUT -p tcp -m tcp --dport 1194 -j ACCEPT 2>/dev/null
		ip6tables -A OUTPUT -p udp -m udp --dport 1194 -j ACCEPT 2>/dev/null
		ip6tables -A OUTPUT -p tcp -m tcp --dport 443 -j ACCEPT 2>/dev/null
		ip6tables -A OUTPUT -o eth0 -d api.nordvpn.com -j ACCEPT 2>/dev/null
	}

	local docker6_network="$(ip -o addr show dev eth0 | awk '$3 == "inet6" {print $4; exit}')"
	if [[ -n ${docker6_network} ]]; then
		ip6tables -A INPUT -s "${docker6_network}" -j ACCEPT 2>/dev/null
		ip6tables -A FORWARD -d "${docker6_network}" -j ACCEPT 2>/dev/null
		ip6tables -A FORWARD -s "${docker6_network}" -j ACCEPT 2>/dev/null
		ip6tables -A OUTPUT -d "${docker6_network}" -j ACCEPT 2>/dev/null
	fi
	[[ -n ${WHITELIST_NETWORK_6} ]] && for network in ${WHITELIST_NETWORK_6//[;]/ }; do route_create6 "${network}"; done
}

function route_create4() { # Add a route back to your network, so that return traffic works
	local network="$1" gateway=$(ip route | awk '/default/ {print $3}')
	ip route | grep -q "$network" || ip route add to "$network" via "$gateway" dev eth0
	iptables -A INPUT -s "$network" -j ACCEPT
	iptables -A FORWARD -d "$network" -j ACCEPT
	iptables -A FORWARD -s "$network" -j ACCEPT
	iptables -A OUTPUT -d "$network" -j ACCEPT
}

function route_create6() { # Add a route back to your network, so that return traffic works
	local network="$1" gateway=$(ip -6 route | awk '/default/{print $3}')
	ip -6 route | grep -q "$network" || ip -6 route add to "$network" via "$gateway" dev eth0
	ip6tables -A INPUT -s "$network" -j ACCEPT 2>/dev/null
	ip6tables -A FORWARD -d "$network" -j ACCEPT 2>/dev/null
	ip6tables -A FORWARD -s "$network" -j ACCEPT 2>/dev/null
	ip6tables -A OUTPUT -d "$network" -j ACCEPT 2>/dev/null
}

function whitelist_add() { # Allow unsecured traffic for an specific domain
	local domain=$(echo "$1" | sed 's/^.*:\/\///;s/\/.*$//')
	sg vpn -c "iptables  -A OUTPUT -o eth0 -d ${domain} -j ACCEPT"
	sg vpn -c "ip6tables -A OUTPUT -o eth0 -d ${domain} -j ACCEPT 2>/dev/null"
}

function setupnordvpn() {
	pkill nordvpnd
	mkdir /run/nordvpn
	rm -f /run/nordvpn/nordvpnd.sock
	sg vpn -c "nordvpnd" &
	while [ ! -S /run/nordvpn/nordvpnd.sock ]; do
		sleep 0.25
	done

	nordvpn login -u "${NORDVPN_USERNAME}" -p "${NORDVPN_PASSWORD}"
	nordvpn set technology OpenVPN
	[[ -n ${NORDVPN_PROTOCOL} ]] && nordvpn set protocol ${NORDVPN_PROTOCOL}
	nordvpn set killswitch disabled
	if [[ -n ${NORDVPN_CYBERSEC} ]]; then
		nordvpn set cybersec enabled
	else
		nordvpn set cybersec disabled
	fi
	if [[ -n ${NORDVPN_OBFUSCATE} ]]; then
		nordvpn set obfuscate enabled
	else
		nordvpn set obfuscate disabled
	fi
	nordvpn set notify disabled
	nordvpn set autoconnect disabled
	[[ -n ${DNS} ]] && nordvpn set dns ${DNS//[;]/ } && echo -e "# Generated by $BASH_SOURCE$(for dns in ${DNS//[;]/ }; do echo "\nnameserver ${dns}"; done)" >/etc/resolv.conf
	[[ -n ${WHITELIST_NETWORK_INTERFACES} ]] && for interface in ${WHITELIST_NETWORK_INTERFACES//[;]/ }; do nordvpn whitelist add subnet "$(ip -o addr show dev ${interface} | awk '$3 == "inet" {print $4}')"; done
	[[ -n $WHITELIST_NETWORK_4 ]] && for network in ${WHITELIST_NETWORK_4//[;]/ }; do nordvpn whitelist add subnet "${network}"; done
	[[ -n ${WHITELIST_PORTS} ]] && for port in ${WHITELIST_PORTS//[;]/ }; do nordvpn whitelist add port "${port}"; done
	[[ -n ${DEBUG} ]] && nordvpn -version && nordvpn settings

	mkdir -p /dev/net
	[[ -c /dev/net/tun ]] || mknod -m 0666 /dev/net/tun c 10 200
}

function cleanup() {
	echo "cleaning up"
	nordvpn disconnect
	kill "$(pidof nordvpnd)"
	trap - SIGTERM SIGINT EXIT # https://bash.cyberciti.biz/guide/How_to_clear_trap
	exit 0
}
trap cleanup SIGTERM SIGINT EXIT # https://www.ctl.io/developers/blog/post/gracefully-stopping-docker-containers/

killswitch
setupnordvpn

nordvpn connect ${NORDVPN_ENDPOINT} || exit 1
nordvpn status

tail -f --pid="$(pidof nordvpnd)" /var/log/nordvpn/daemon.log &
wait $!
