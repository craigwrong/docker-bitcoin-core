# syntax=docker/dockerfile:1
FROM alpine as prep
RUN apk --update upgrade && apk add autoconf automake libtool pkgconfig
WORKDIR /opt
RUN wget -qO- https://bitcoincore.org/bin/bitcoin-core-23.0/bitcoin-23.0.tar.gz | tar xzf - && \
    mv bitcoin-23.0 bitcoin && \
    cd bitcoin && \
    ./autogen.sh

FROM alpine as builder
RUN apk --update upgrade && apk add pkgconfig boost-dev libevent-dev make g++
COPY --from=prep /opt/bitcoin /opt/bitcoin
WORKDIR /opt/bitcoin
RUN ./configure --without-wallet --without-sqlite --without-bdb --without-gui --without-libs \
        --disable-tests --disable-bench --disable-external-signer \
        --enable-daemon --enable-util-cli --disable-util-tx --disable-util-wallet --disable-util-util && \
    make install

FROM alpine as builder-wallet
RUN apk --update upgrade && apk add boost-dev libevent-dev sqlite-dev pkgconfig make g++
COPY --from=prep /opt/bitcoin /opt/bitcoin
WORKDIR /opt/bitcoin
RUN ./configure --with-wallet --with-sqlite --without-bdb --without-gui --without-libs \
        --disable-tests --disable-bench --disable-external-signer \
        --enable-daemon --disable-util-cli --disable-util-tx --enable-util-wallet --disable-util-util && \
    make install

FROM alpine as daemon
RUN apk --update upgrade && apk add boost libevent
COPY --from=builder /usr/local/bin/bitcoind /usr/local/bin/bitcoind
VOLUME /root/.bitcoin
ENTRYPOINT ["/usr/local/bin/bitcoind"]

FROM alpine as daemon-wallet
RUN apk --update upgrade && apk add boost libevent
COPY --from=builder-wallet /usr/local/bin/bitcoind /usr/local/bin/bitcoind
VOLUME /root/.bitcoin
ENTRYPOINT ["/usr/local/bin/bitcoind"]

FROM alpine as cli
RUN apk --update upgrade && apk add boost libevent
COPY --from=builder /usr/local/bin/bitcoin-cli /usr/local/bin/bitcoin-cli
VOLUME /root/.cookie
ENTRYPOINT ["/usr/local/bin/bitcoin-cli"]

FROM alpine as wallet
RUN apk --update upgrade && apk add boost
# RUN apk --update upgrade && apk add boost sqlite-libs
COPY --from=builder-wallet /usr/local/bin/bitcoin-wallet /usr/local/bin/bitcoin-wallet
VOLUME /root/.bitcoin
ENTRYPOINT ["/usr/local/bin/bitcoin-wallet"]
