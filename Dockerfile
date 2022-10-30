# syntax=docker/dockerfile:1
FROM debian as prep
RUN apt-get update && apt-get -y upgrade && apt-get install --no-install-recommends --yes wget ca-certificates autoconf automake pkg-config libtool
WORKDIR /opt
RUN wget -qO- https://bitcoincore.org/bin/bitcoin-core-23.0/bitcoin-23.0.tar.gz | tar xzf - && \
    mv bitcoin-23.0 bitcoin && \
    cd bitcoin && \
    ./autogen.sh

FROM debian as builder-base
RUN apt-get update && apt-get -y upgrade && apt-get install --yes --no-install-recommends make g++ binutils

FROM builder-base as builder-depends
COPY --from=prep /opt/bitcoin /opt/bitcoin
RUN apt-get install --yes --no-install-recommends curl ca-certificates lbzip2
WORKDIR /opt/bitcoin/depends
RUN make NO_QT=1 NO_QR=1 NO_ZMQ=1 NO_WALLET=1 NO_BDB=1 NO_SQLITE=1 NO_UPNP=1 NO_NATPMP=1 NO_USDT=1

FROM builder-base as builder
COPY --from=prep /opt/bitcoin /opt/bitcoin
COPY --from=builder-depends /opt/bitcoin/depends/x86_64-pc-linux-gnu /opt/bitcoin/depends/x86_64-pc-linux-gnu
RUN apt-get install --yes --no-install-recommends pkg-config
WORKDIR /opt/bitcoin
RUN LDFLAGS="-static-libstdc++" ./configure \
        --prefix=`pwd`/depends/x86_64-pc-linux-gnu \
        --without-wallet --without-sqlite --without-bdb --without-gui --without-libs \
        --disable-tests --disable-bench --disable-external-signer \
        --enable-daemon --enable-util-cli --disable-util-tx --disable-util-wallet --disable-util-util && \
    make install

FROM scratch as deps
COPY --from=debian /lib/x86_64-linux-gnu/libpthread.so.0 /lib/libpthread.so.0
COPY --from=debian /lib/x86_64-linux-gnu/libm.so.6 /lib/libm.so.6
COPY --from=debian /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/libgcc_s.so.1
COPY --from=debian /lib/x86_64-linux-gnu/libc.so.6 /lib/libc.so.6
COPY --from=debian /lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2

FROM scratch as daemon
COPY --from=deps / /
COPY --from=builder /opt/bitcoin/depends/x86_64-pc-linux-gnu/bin/bitcoind /bin/bitcoind
VOLUME /.bitcoin
ENTRYPOINT ["/bin/bitcoind"]

FROM scratch as cli
COPY --from=deps / /
COPY --from=builder /opt/bitcoin/depends/x86_64-pc-linux-gnu/bin/bitcoin-cli /bin/bitcoin-cli
VOLUME /.bitcoin
ENTRYPOINT ["/bin/bitcoin-cli"]
