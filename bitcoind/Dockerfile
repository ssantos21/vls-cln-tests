# Build stage for Bitcoin Core
FROM --platform=${TARGETPLATFORM:-${BUILDPLATFORM:-linux/amd64}} alpine:3.18 as bitcoin-core

ARG TARGETPLATFORM

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk add \
  autoconf \
  automake \
  boost-dev \
  build-base \
  chrpath \
  file \
  gnupg \
  libevent-dev \
  libressl \
  libtool \
  linux-headers \
  sqlite-dev \
  zeromq-dev

ENV GNUPGHOME=/root/.gnupg
RUN mkdir $GNUPGHOME && set -ex \
  && for key in \
    152812300785C96444D3334D17565732E08E5E41 \
    0AD83877C1F0CD1EE9BD660AD7CC770B81FD22A8 \
    590B7292695AFFA5B672CBB2E13FC145CD3F4304 \
    CFB16E21C950F67FA95E558F2EEB9F5CC09526C1 \
    F4FC70F07310028424EFC20A8E4256593F177720 \
    D1DBF2C4B96F2DEBF4C16654410108112E7EA81F \
    287AE4CA1187C68C08B49CB2D11BD4F33F1DB499 \
    9DEAE0DC7063249FB05474681E4AED62986CD25D \
    3EB0DEE6004A13BE5A0CC758BF2978B068054311 \
    ED9BDF7AD6A55E232E84524257FF9BDBCC301009 \
    28E72909F1717FE9607754F8A7BEB2621678D37D \
  ; do \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" || \
    gpg --batch --keyserver keys.openpgp.org --recv-keys "$key" || \
    gpg --batch --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" ; \
  done
RUN gpg --keyserver hkps://keys.openpgp.org --refresh-keys
RUN gpg -kv

COPY verify.sh verify.sh

ARG BITCOIN_VERSION
ARG BITCOIN_PREFIX=/opt/bitcoin-${BITCOIN_VERSION}
ARG BITCOIN_SHA256SUMS_HASH
RUN echo "Building bitcoin core version $BITCOIN_VERSION"
RUN wget https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS && \
    wget https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS.asc && \
    wget https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}.tar.gz && \
    ./verify.sh && \
    echo "${BITCOIN_SHA256SUMS_HASH} SHA256SUMS" | sha256sum -c - && \
    grep " bitcoin-${BITCOIN_VERSION}.tar.gz\$" SHA256SUMS | sha256sum -c - && \
    tar -xzf *.tar.gz

WORKDIR /bitcoin-${BITCOIN_VERSION}

RUN sed -i '/AC_PREREQ/a\AR_FLAGS=cr' configure.ac && \
    sed -i '/AX_PROG_CC_FOR_BUILD/a\AR_FLAGS=cr' src/secp256k1/configure.ac && \
    sed -i s:sys/fcntl.h:fcntl.h: src/compat/compat.h && \
    ./autogen.sh && \
    ./configure LDFLAGS=-L`ls -d /opt/db*`/lib/ CPPFLAGS=-I`ls -d /opt/db*`/include/ \
    --prefix=${BITCOIN_PREFIX} \
    --mandir=/usr/share/man \
    --disable-tests \
    --disable-bench \
    --disable-ccache \
    --with-gui=no \
    --with-utils \
    --with-libs \
    --with-sqlite=yes \
    --with-daemon

RUN make -j $(nproc) && \
    make install && \
    strip ${BITCOIN_PREFIX}/bin/bitcoin-cli \
          ${BITCOIN_PREFIX}/bin/bitcoin-tx \
          ${BITCOIN_PREFIX}/bin/bitcoind \
          ${BITCOIN_PREFIX}/lib/libbitcoinconsensus.a \
          ${BITCOIN_PREFIX}/lib/libbitcoinconsensus.so.0.0.0 && \
    make clean

# Runtime binaries and setup stage
FROM --platform=${TARGETPLATFORM:-${BUILDPLATFORM:-linux/amd64}} alpine:3.18 as runner

ARG UID=100
ARG GID=101

LABEL maintainer.0="Lakshya Singh (@king-11)" \
  maintainer.1="Dev Random (@devrandom01)"

RUN addgroup bitcoin --gid ${GID} --system && \
    adduser --uid ${UID} --system bitcoin --ingroup bitcoin
RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add \
  boost-filesystem \
  boost-system \
  boost-thread \
  sqlite-dev \
  libevent \
  libzmq \
  tini

ARG BITCOIN_VERSION
ARG BITCOIN_PREFIX=/opt/bitcoin-${BITCOIN_VERSION}

ENV BITCOIN_DATA=/home/bitcoin/.bitcoin

COPY --from=bitcoin-core ${BITCOIN_PREFIX}/bin/bitcoin-cli /usr/bin/bitcoin-cli
COPY --from=bitcoin-core ${BITCOIN_PREFIX}/bin/bitcoin-tx /usr/bin/bitcoin-tx
COPY --from=bitcoin-core ${BITCOIN_PREFIX}/bin/bitcoind /usr/bin/bitcoind

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY bitcoin.conf /bitcoin.conf

COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh

RUN mkdir "${BITCOIN_DATA}"
RUN chown bitcoin:bitcoin "${BITCOIN_DATA}"

VOLUME ["${BITCOIN_DATA}"]

USER bitcoin

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]

RUN bitcoind -version | grep "Bitcoin Core version v${BITCOIN_VERSION}"

HEALTHCHECK --interval=10s --timeout=20s --start-period=30s \
  CMD ["/healthcheck.sh"]

CMD ["bitcoind"]
