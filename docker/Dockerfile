FROM --platform=$BUILDPLATFORM rust:1.64.0-bullseye AS solana-builder

ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG TARGETARCH
ARG CI_COMMIT

WORKDIR /srv/solana

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates vim-tiny curl git pkg-config llvm clang make

RUN dpkg --add-architecture ${TARGETARCH} \
    && apt-get update \
    && ARCHITECTURE=$(echo ${TARGETARCH} | sed -e 's/arm64/aarch64/g' -e 's/amd64/x86-64/g') \
    && apt-get install -y --no-install-recommends \
        build-essential clang \
        $(if [ "$BUILDPLATFORM" = "$TARGETPLATFORM" ]; then echo gcc g++ ; else echo gcc-$ARCHITECTURE-linux-gnu g++-$ARCHITECTURE-linux-gnu ; fi) \
        libc6-dev:$TARGETARCH libssl-dev:$TARGETARCH libudev-dev:$TARGETARCH zlib1g-dev:$TARGETARCH libprotobuf-dev:$TARGETARCH protobuf-compiler:$TARGETARCH

COPY --link . /srv/solana/

RUN ARCHITECTURE=$(echo ${TARGETARCH} | sed -e 's/arm64/aarch64/g' -e 's/amd64/x86_64/g') \
    && rust_stable=$(bash -c ". /srv/solana/ci/rust-version.sh; printenv | sed -n 's/^rust_stable=//p'") \
    && rustup toolchain install ${rust_stable} --target $(rustup show | sed -n 's/Default host: //gp') --component rustc cargo rustfmt rust-std clippy \
    && rustup toolchain install --force-non-host ${rust_stable} --target $ARCHITECTURE-unknown-linux-gnu --component rustc cargo rustfmt rust-std clippy

RUN cd /srv/solana \
    && CI_COMMIT=$(git rev-parse --short=8 HEAD) \
    && ARCHITECTURE=$(echo ${TARGETARCH} | sed -e 's/arm64/aarch64/g' -e 's/amd64/x86_64/g') \
    && TARGET=$ARCHITECTURE-unknown-linux-gnu \
    && rust_stable=$(bash -c ". /srv/solana/ci/rust-version.sh; printenv | sed -n 's/^rust_stable=//p'") \
    && TARGET_CPU=$(if [ "$BUILDPLATFORM" = "$TARGETPLATFORM" ]; then echo 'native'; else echo ${TARGETARCH} | sed -e 's/arm64/aarch64/g' -e 's/amd64/x86-64/g'; fi) \
    && PKG_CONFIG_PATH="/usr/lib/$ARCHITECTURE-linux-gnu/pkgconfig/" PKG_CONFIG_ALLOW_CROSS=1 CARGO_ENCODED_RUSTFLAGS="-Clinker=$ARCHITECTURE-linux-gnu-gcc$(printf '\037')-Cstrip=symbols$(printf '\037')--cfg=tokio_unstable$(printf '\037')-Ctarget-cpu=$TARGET_CPU" CARGO_NET_GIT_FETCH_WITH_CLI=true cargo +$rust_stable build --target=$TARGET --release

RUN mkdir /dist/ \
    && ARCHITECTURE=$(echo ${TARGETARCH} | sed -e 's/arm64/aarch64/g' -e 's/amd64/x86_64/g') \
    && cp /srv/solana/target/$ARCHITECTURE-unknown-linux-gnu/release/solana /dist/ \
    && cp /srv/solana/target/$ARCHITECTURE-unknown-linux-gnu/release/solana-keygen /dist/ \
    && cp /srv/solana/target/$ARCHITECTURE-unknown-linux-gnu/release/solana-test-validator /dist/

FROM --platform=$BUILDPLATFORM rust:1.64.0-bullseye as anchor-builder
RUN apt-get update \
    && apt-get install -y --no-install-recommends pkg-config build-essential libudev-dev libssl-dev

RUN cargo install --git https://github.com/coral-xyz/anchor avm --locked --force

RUN avm install 0.27.0 && avm use 0.27.0

FROM --platform=$TARGETPLATFORM debian:bullseye-slim AS tools

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bzip2 zlib1g \
    && rm -rf /var/lib/apt/lists/*

COPY --from=solana-builder /dist/ /usr/local/bin/
COPY --from=anchor-builder /usr/local/cargo/bin/anchor /usr/local/bin/

