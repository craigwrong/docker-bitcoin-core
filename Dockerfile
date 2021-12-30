# syntax=docker/dockerfile:1
FROM alpine as prep
RUN apk --update upgrade && apk add autoconf automake libtool pkgconfig
WORKDIR /opt
RUN wget -qO- https://bitcoincore.org/bin/bitcoin-core-22.0/bitcoin-22.0.tar.gz | tar xzf - && \
    mv bitcoin-22.0 bitcoin && \
    cd bitcoin && \
    ./autogen.sh

FROM alpine as builder
RUN apk --update upgrade && apk add pkgconfig boost-dev libevent-dev make g++
COPY --from=prep /opt/bitcoin /opt/bitcoin
WORKDIR /opt/bitcoin
RUN ./configure --without-wallet --without-gui --without-bdb --without-libs \
        --disable-tests --disable-bench --disable-external-signer \
        --enable-daemon --enable-util-cli --disable-util-tx --disable-util-wallet --disable-util-util && \
    make install

FROM alpine as daemon
RUN apk --update upgrade && apk add boost libevent
COPY --from=builder /usr/local/bin/bitcoind /usr/local/bin/bitcoind
VOLUME /root/.bitcoin
ENTRYPOINT ["/usr/local/bin/bitcoind"]

FROM alpine as cli
RUN apk --update upgrade && apk add boost libevent
COPY --from=builder /usr/local/bin/bitcoin-cli /usr/local/bin/bitcoin-cli
VOLUME /root/.cookie
ENTRYPOINT ["/usr/local/bin/bitcoin-cli"]
