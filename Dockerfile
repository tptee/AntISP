 # tptee/antisp

FROM debian:8
MAINTAINER dnscrypt.io

ENV BUILD_DEPENDENCIES \
    autoconf \
    cmake \
    bzip2 \
    curl \
    gcc \
    make

RUN set -x && \
    apt-get update && \
    apt-get install -y $BUILD_DEPENDENCIES # --no-install-recommends

RUN set -x && apt-get install -y libldns-dev

ENV LIBSODIUM_VERSION 1.0.12
ENV LIBSODIUM_SHA256 b8648f1bb3a54b0251cf4ffa4f0d76ded13977d4fa7517d988f4c902dd8e2f95
ENV LIBSODIUM_DOWNLOAD_URL https://download.libsodium.org/libsodium/releases/libsodium-${LIBSODIUM_VERSION}.tar.gz

RUN set -x && \
    mkdir -p /tmp/src && \
    cd /tmp/src && \
    curl -sSL $LIBSODIUM_DOWNLOAD_URL -o libsodium.tar.gz && \
    echo "${LIBSODIUM_SHA256} *libsodium.tar.gz" | sha256sum -c - && \
    tar xzf libsodium.tar.gz && \
    rm -f libsodium.tar.gz && \
    cd libsodium-${LIBSODIUM_VERSION} && \
    ./configure --disable-dependency-tracking --enable-minimal --prefix=/usr/local && \
    make check && make install && \
    echo /opt/libsodium/lib > /etc/ld.so.conf.d/libsodium.conf && ldconfig && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV MINISIGN_VERSION 0.7
ENV MINISIGN_SHA256 0c9f25ae647b6ba38cf7e6aea1da4e8fb20e1bc64ef0c679da737a38c8ad43ef
ENV MINISIGN_DOWNLOAD_URL https://github.com/jedisct1/minisign/archive/${MINISIGN_VERSION}.tar.gz

RUN set -x && \
    mkdir -p /tmp/src && \
    cd /tmp/src && \
    curl -sSL $MINISIGN_DOWNLOAD_URL -o minisign.tar.gz && \
    echo "${MINISIGN_SHA256} *minisign.tar.gz" | sha256sum -c - && \
    tar xzf minisign.tar.gz && \
    rm -f minisign.tar.gz && \
    cd minisign-${MINISIGN_VERSION} && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV DNSCRYPT_PROXY_VERSION 1.9.4
ENV DNSCRYPT_PROXY_SHA256 40543efbcd56033ac03a1edf4581305e8c9bed4579ac55e6279644f07c315307
ENV DNSCRYPT_PROXY_DOWNLOAD_URL https://download.dnscrypt.org/dnscrypt-proxy/dnscrypt-proxy-${DNSCRYPT_PROXY_VERSION}.tar.gz
ENV DNSCRYPT_PROXY_DOWNLOAD_MINISIG ${DNSCRYPT_PROXY_DOWNLOAD_URL}.minisig

RUN set -x && \
    mkdir -p /tmp/src && \
    cd /tmp/src && \
    curl -sSL $DNSCRYPT_PROXY_DOWNLOAD_URL -o dnscrypt-proxy.tar.gz && \
    curl -sSL $DNSCRYPT_PROXY_DOWNLOAD_MINISIG -o dnscrypt-proxy.tar.gz.minisig && \
    echo "${DNSCRYPT_PROXY_SHA256} *dnscrypt-proxy.tar.gz" | sha256sum -c - && \
    minisign -VP RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3 -m dnscrypt-proxy.tar.gz && \
    tar xzf dnscrypt-proxy.tar.gz && \
    rm -f dnscrypt-proxy.tar.gz && \
    cd dnscrypt-proxy-${DNSCRYPT_PROXY_VERSION} && \
    mkdir -p /opt/dnscrypt-proxy/empty && \
    groupadd _dnscrypt-proxy && \
    useradd -g _dnscrypt-proxy -s /etc -d /opt/dnscrypt-proxy/empty _dnscrypt-proxy && \
    env CPPFLAGS=-I/usr/local/libsodium/include LDFLAGS=-L/usr/local/libsodium/lib \
        ./configure --disable-dependency-tracking --prefix=/usr/local && \
    make install && \
    rm -fr /opt/dnscrypt-proxy/share && \
    rm -fr /tmp/* /var/tmp/*

RUN set -x && \
    apt-get purge -y --auto-remove $BUILD_DEPENDENCIES && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 53/tcp 53/udp

COPY ./ /dnscrypt-proxy-docker

CMD /usr/local/sbin/dnscrypt-proxy /dnscrypt-proxy-docker/dnscrypt-proxy.conf
