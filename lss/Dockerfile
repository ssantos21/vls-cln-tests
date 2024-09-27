# build lss
FROM --platform=${TARGETPLATFORM:-${BUILDPLATFORM:-linux/amd64}} alpine:3.18 as builder

WORKDIR /build

RUN apk update && \
    apk add \
    build-base \
    cargo \
    git \
    grpc \
    protobuf \
    protobuf-dev \
    rust

ARG LSS_GIT_HASH \
    LSS_REPO 
RUN echo "building lss from hash: $LSS_GIT_HASH"
RUN git clone $LSS_REPO lss

RUN cd lss && \
    git checkout $LSS_GIT_HASH && \
    cargo install --locked --path ./lightning-storage-server --bin lssd --profile release --root /usr/local/ && \
    cargo clean

# lss runner
FROM --platform=${TARGETPLATFORM:-${BUILDPLATFORM:-linux/amd64}} alpine:3.18 as runner

ARG LSS_DATA=/root/.lssd

RUN apk update && \
  apk add \
  build-base \
  curl-dev \
  protobuf \
  bind-tools \
  tini

COPY --from=builder /usr/local/bin/lssd /usr/local/bin/lssd
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["${LSS_DATA}"]



# Environment variables with default fallbacks
ENV LSS_PORT=${LSS_PORT:-55551}
ENV LSS_INTERFACE=${LSS_INTERFACE:-0.0.0.0}
ENV LSS_CLEARDB=${LSS_CLEARDB:-false}
ENV LSS_DATADIR=${LSS_DATADIR:-datadir}
ENV LSS_DATABASE=${LSS_DATABASE:-sled}
ENV PG_HOST=${PG_HOST:-}
ENV PG_USER=${PG_USER:-dev}
ENV PG_PASSWORD=${PG_PASSWORD:-}
ENV PG_DB=${PG_DB:-dev}

# Expose LSS port
EXPOSE ${LSS_PORT}

# Run lssd with the build arguments passed at runtime
ENTRYPOINT ["/entrypoint.sh"]
