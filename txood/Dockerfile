# build txoo
FROM --platform=${TARGETPLATFORM:-${BUILDPLATFORM:-linux/amd64}} alpine:3.20 as builder

WORKDIR /build

RUN apk update && \
    apk add \
    git \
    rust \
    cargo

ARG TXOO_GIT_HASH \
    TXOO_REPO
RUN git clone --recurse-submodules $TXOO_REPO
RUN cd txoo && \
    git checkout $TXOO_GIT_HASH && \
    cargo install --path ./txood --bin txood --profile release --root /usr/local/ && \
    cargo clean

# txoo runner
FROM --platform=${TARGETPLATFORM:-${BUILDPLATFORM:-linux/amd64}} alpine:3.20 as runner

LABEL maintainer.0="Lakshya Singh (@king-11)" \
  maintainer.1="Dev Random (@devrandom01)"

ARG TXOO_DATA=/root/.txoo

RUN apk update && \
    apk add \
      build-base \
      bind-tools \
      libev-dev \
      curl-dev \
      curl \
      jq \
      tini

COPY --from=builder /usr/local/bin/txood /usr/bin/txood

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh

VOLUME ["${TXOO_DATA}"]

HEALTHCHECK --interval=5s --timeout=10s --start-period=5s \
    CMD ["/healthcheck.sh"]

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
CMD ["txood"]
