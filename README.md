<p align="center">
    <a href="https://nordvpn.com/"><img src="https://github.com/5t4cktr4c3/nordvpn/raw/master/NordVpn_logo.png"/></a>
    </br>
    <a href="https://github.com/5t4cktr4c3/nordvpn/blob/master/LICENSE"><img src="https://badgen.net/github/license/5t4cktr4c3/nordvpn?color=cyan"/></a>
    <a href="https://cloud.docker.com/u/5t4cktr4c3/repository/docker/5t4cktr4c3/nordvpn"><img src="https://badgen.net/docker/size/5t4cktr4c3/nordvpn?icon=docker&label=size"/></a>
    <a href="https://cloud.docker.com/u/5t4cktr4c3/repository/docker/5t4cktr4c3/nordvpn"><img src="https://badgen.net/docker/pulls/5t4cktr4c3/nordvpn?icon=docker&label=pulls"/></a>
    <a href="https://cloud.docker.com/u/5t4cktr4c3/repository/docker/5t4cktr4c3/nordvpn"><img src="https://badgen.net/docker/stars/5t4cktr4c3/nordvpn?icon=docker&label=stars"/></a>
    <a href="https://github.com/5t4cktr4c3/nordvpn"><img src="https://badgen.net/github/forks/5t4cktr4c3/nordvpn?icon=github&label=forks&color=black"/></a>
    <a href="https://github.com/5t4cktr4c3/nordvpn"><img src="https://badgen.net/github/stars/5t4cktr4c3/nordvpn?icon=github&label=stars&color=black"/></a>
    <a href="https://github.com/5t4cktr4c3/nordvpn/actions?query=workflow%3Arelease"><img src="https://github.com/5t4cktr4c3/nordvpn/workflows/release/badge.svg"/></a>
</p>

Official `NordVPN` client in a docker container; it makes routing traffic through the `NordVPN` network easy.

# HOW TO USE THIS IMAGE

This container was designed to run on the `host`-network, so that it can provide a connection for the whole host's system - including other containers.

**NOTE**: More than the basic privileges are needed for NordVPN. With docker 1.2 or newer you can use the `--cap-add=NET_ADMIN` and `--device /dev/net/tun` options. Earlier versions, or with fig, and you'll have to run it in privileged mode.

## STARTING AN NORDVPN INSTANCE

    docker run -ti --cap-add=NET_ADMIN --device /dev/net/tun --name vpn \
                -e USER=user@email.com -e PASS="password" \
                -e CONNECT=country -d --network host \
                --restart unless-stopped 5t4cktr4c3/nordvpn

## KILL-SWITCH
All traffic going through the host is routed via the VPN (unless whitelisted). If the connection to the `NordVPN` network drops your connection to the internet stays blocked until the VPN tunnel is restored.

# ENVIRONMENT VARIABLES

| Variable | Explanation/Function | Example |
|----------|----------------------|---------|
|`NORDVPN_USERNAME`|username or email address for your nordvpn account|`john.smith@example.com`|
|`NORDVPN_PASSWORD`|password for your nordvpn account|`password`|
|`NORDVPN_ENDPOINT`|endpoint/destination for your nordvpn account|country: `se`/`sweden`<br>city in country: `se stockholm`/`sweden stockholm`<br>server: `se408`<br>group: `p2p`|
|`NORDVPN_PROTOCOL`|protocol for the connection to the `NordVPN` network|TCP: `tcp`<br>UDP: `udp`|
|`NORDVPN_OBFUSCATE`|use [obfuscated servers](https://nordvpn.com/features/obfuscated-servers/) for the connection to the `NordVPN` network|arbitrary value (not empty) to enable|
|`NORDVPN_CYBERSEC`|use the [`CyberSec` feature](https://nordvpn.com/features/cybersec/) of the `NordVPN` network|arbitrary value (not empty) to enable|
|`DNS`|use custom dns servers for the connection to the `NordVPN` network and override the ones in `/etc/resolv.conf` on startup|`103.86.96.100`/`103.86.96.100;103.86.99.100`|
|`WHITELIST_DOMAINS`|whitelist domains to bypass the connection to the `NordVPN` network|`eth0`/`eth0;wlan0`|
|`WHITELIST_NETWORK_INTERFACES`|whitelist subnets of interfaces to allow communication outside the connection to the `NordVPN` network|`nordvpn.com`/`nordvpn.com;www.nordvpn.com`|
|`WHITELIST_NETWORK_4`|whitelist IPv4 subnets in [CIDR notation](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing#CIDR_notation) to allow communication outside the connection to the `NordVPN` network|`192.168.0.0/24`/`192.168.0.0/24;192.168.1.0/24`|
|`WHITELIST_NETWORK_6`|whitelist IPv6 subnets in [CIDR notation](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing#CIDR_notation) to allow communication outside the connection to the `NordVPN` network|`2001:db8::/48`/`2001:db8::/48;2001:db9::/48`|
|`WHITELIST_PORTS`|whitelist ports to bypass the connection to the `NordVPN` network|`80`/`80;8080`|
|`TZ`|[timezone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List) for the docker container|`Europe/Stockholm`|
|`VPNGROUPID`|group id for the user group that can bypass the killswitch|arbitrary value (not empty) to enable|
|`DEBUG`|enable the debugging mode for troubleshooting|arbitrary value (not empty) to enable|

# ISSUES

If you have any problems with or questions about this image, please contact me through a [GitHub issue](https://github.com/5t4cktr4c3/nordvpn/issues).
