FROM ubuntu:18.04

LABEL maintainer="github/5t4cktr4c3"
ARG NORDVPN_VERSION=3.8.10

HEALTHCHECK --interval=5m --timeout=20s --start-period=1m \
	CMD if test $( curl -m 10 -s https://api.nordvpn.com/v1/helpers/ips/insights | jq -r '.["protected"]' ) = "true" ; then exit 0; else nordvpn disconnect; nordvpn connect ${CONNECT} ; exit $?; fi

RUN addgroup --system vpn && \
	apt-get update -yqq && \
	apt-get install -yqq nano man iputils-ping net-tools dnsutils traceroute curl jq && \
	curl -s https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/nordvpn-release_1.0.0_all.deb --output /tmp/nordrepo.deb && \
    apt-get install -yqq /tmp/nordrepo.deb && \
    apt-get update -yqq && \
    apt-get install -yqq nordvpn${NORDVPN_VERSION:+=$NORDVPN_VERSION} && \
    apt-get remove -yqq nordvpn-release && \
    apt-get autoremove -yqq && \
    apt-get autoclean -yqq && \
    rm -rf \
		/tmp/* \
		/var/cache/apt/archives/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

CMD ["/usr/bin/start_vpn.sh"]
COPY start_vpn.sh /usr/bin
