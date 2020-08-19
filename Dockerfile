# ============================== Builder image ================================
FROM ubuntu:20.04 AS build

ARG NODE_VERSION="1.19.0"
ARG CABAL_VERSION="3.2.0.0"
ARG GHC_VERSION="8.6.5"

# Don't ask for geographic area in apt-get
ARG DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    automake \
    build-essential \
    pkg-config \
    libffi-dev \
    libgmp-dev \
    libssl-dev \
    libtinfo-dev \
    libsystemd-dev \
    zlib1g-dev \
    make \
    g++ \
    tmux \
    git \
    jq \
    wget \
    libncursesw5 \
    libtool \
    autoconf

# Download, install and update Cabal
RUN wget https://downloads.haskell.org/~cabal/cabal-install-${CABAL_VERSION}/cabal-install-${CABAL_VERSION}-x86_64-unknown-linux.tar.xz && \
    tar -xf cabal-install-${CABAL_VERSION}-x86_64-unknown-linux.tar.xz && \
    mv cabal /usr/local/bin && \
    cabal update

# Download and install GHC
RUN wget https://downloads.haskell.org/~ghc/${GHC_VERSION}/ghc-${GHC_VERSION}-x86_64-deb9-linux.tar.xz && \
    tar -xf ghc-${GHC_VERSION}-x86_64-deb9-linux.tar.xz && \
    cd ghc-${GHC_VERSION} && \
    ./configure && \
    make install

# Download, build and install Libsodium
RUN git clone https://github.com/input-output-hk/libsodium && \
    cd libsodium && \
    git checkout 66f017f1 && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install

ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

# Download, build and install cardano-node
RUN git clone https://github.com/input-output-hk/cardano-node.git && \
    cd cardano-node && \
    git checkout tags/${NODE_VERSION} && \
    cabal build all && \
    cp -p dist-newstyle/build/x86_64-linux/ghc-${GHC_VERSION}/cardano-node-${NODE_VERSION}/x/cardano-node/build/cardano-node/cardano-node /usr/local/bin/ && \
    cp -p dist-newstyle/build/x86_64-linux/ghc-${GHC_VERSION}/cardano-cli-${NODE_VERSION}/x/cardano-cli/build/cardano-cli/cardano-cli /usr/local/bin/


# ================================ Main image =================================
FROM ubuntu:20.04

# Node
EXPOSE 3000
# Prometheus
EXPOSE 12798

# Use libsodium from IOG
ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

# Copy executables from the builder image
COPY --from=build /usr/local/bin/cardano-node /usr/local/bin/cardano-cli /usr/local/bin/
COPY --from=build /usr/local/lib/libsodium.* /usr/local/lib/
COPY --from=build /usr/local/lib/pkgconfig /usr/local/lib/

ENTRYPOINT ["/usr/local/bin/cardano-node", "run"]
