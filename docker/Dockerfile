FROM --platform=$BUILDPLATFORM rust:1.64.0-bullseye AS builder

ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG TARGETARCH
ARG CI_COMMIT

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates vim-tiny curl git pkg-config llvm clang make

RUN dpkg --add-architecture ${TARGETARCH} \
    && apt-get update \
    && ARCHITECTURE=$(echo ${TARGETARCH} | sed -e 's/arm64/aarch64/g' -e 's/amd64/x86-64/g') \
    && apt-get install -y --no-install-recommends \
        build-essential clang \
        $(if [ "$BUILDPLATFORM" = "$TARGETPLATFORM" ]; then echo gcc g++ ; else echo gcc-$ARCHITECTURE-linux-gnu g++-$ARCHITECTURE-linux-gnu ; fi) \
        libc6-dev:$TARGETARCH libssl-dev:$TARGETARCH libudev-dev:$TARGETARCH zlib1g-dev:$TARGETARCH libprotobuf-dev:$TARGETARCH protobuf-compiler:$TARGETARCH

RUN ARCHITECTURE=$(echo ${TARGETARCH} | sed -e 's/arm64/aarch64/g' -e 's/amd64/x86_64/g') \
    && rustup component add rustfmt clippy \
    && rustup target add $ARCHITECTURE-unknown-linux-gnu \
    && rustup toolchain install --force-non-host stable-$ARCHITECTURE-unknown-linux-gnu

RUN git clone https://github.com/solana-labs/solana.git /srv/solana

RUN cd /srv/solana \
    && ARCHITECTURE=$(echo ${TARGETARCH} | sed -e 's/arm64/aarch64/g' -e 's/amd64/x86_64/g') \
    && rustup target add $ARCHITECTURE-unknown-linux-gnu \
    && TARGET=$ARCHITECTURE-unknown-linux-gnu \
    && PKG_CONFIG_PATH="/usr/lib/$ARCHITECTURE-linux-gnu/pkgconfig/" PKG_CONFIG_ALLOW_CROSS=1 RUSTFLAGS="-C linker=$ARCHITECTURE-linux-gnu-gcc -C strip=symbols --cfg tokio_unstable" CARGO_NET_GIT_FETCH_WITH_CLI=true cargo build --target=$TARGET --release 

RUN mkdir /dist/ \
    && ARCHITECTURE=$(echo ${TARGETARCH} | sed -e 's/arm64/aarch64/g' -e 's/amd64/x86_64/g') \
    && cp /srv/solana/target/$ARCHITECTURE-unknown-linux-gnu/release/solana /dist/ \
    && cp /srv/solana/target/$ARCHITECTURE-unknown-linux-gnu/release/solana-keygen /dist/ \
    && cp /srv/solana/target/$ARCHITECTURE-unknown-linux-gnu/release/solana-test-validator /dist/

FROM --platform=$TARGETPLATFORM debian:bullseye-20220912 AS tools

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bzip2 zlib1g \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /dist/ /usr/local/bin/
