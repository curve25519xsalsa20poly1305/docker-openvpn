FROM alpine:latest

COPY openvpn-up.sh /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk add --no-cache bash curl wget openvpn openresolv openrc \
    && mkdir -p /etc/openvpn \
    && curl -sL -o /etc/openvpn/update-resolv-conf \
        https://github.com/masterkorp/openvpn-update-resolv-conf/raw/master/update-resolv-conf.sh \
    && chmod +x \
        /usr/local/bin/openvpn-up.sh \
        /usr/local/bin/entrypoint.sh \
        /etc/openvpn/update-resolv-conf

ENV         OPENVPN_UP      ""
ENV         DAEMON_MODE     false
ENTRYPOINT  [ "entrypoint.sh" ]
