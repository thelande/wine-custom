FROM --platform=$TARGETOS/$TARGETARCH debian:bookworm-slim AS builder
LABEL maintainer="Tom Helander <thomas.helander@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /usr/src/wine

# Upgrade base packages
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get autoclean

# Install wine build dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux; \
    dpkg --add-architecture i386; \
    apt-get update; \
    apt-get install -y \
        build-essential \
        flex \
        bison \
        ccache \
        git \
        gcc-multilib \
        gcc-mingw-w64 \
        libasound2-dev \
        libasound2-dev:i386 \
        libpulse-dev \
        libpulse-dev:i386 \
        libudev-dev \
        libudev-dev:i386 \
        libdbus-1-dev \
        libdbus-1-dev:i386 \
        libfontconfig-dev \
        libfontconfig-dev:i386 \
        libfreetype-dev \
        libfreetype-dev:i386 \
        libgnutls28-dev \
        libgnutls28-dev:i386 \
        libgl-dev \
        libgl-dev:i386 \
        libunwind-dev \
        libunwind-dev:i386 \
        libx11-dev \
        libx11-dev:i386 \
        libxcomposite-dev \
        libxcomposite-dev:i386 \
        libxcursor-dev \
        libxcursor-dev:i386 \
        libxfixes-dev \
        libxfixes-dev:i386 \
        libxi-dev \
        libxi-dev:i386 \
        libxrandr-dev \
        libxrandr-dev:i386 \
        libxrender-dev \
        libxrender-dev:i386 \
        libxext-dev \
        libxext-dev:i386 \
        libusb-dev:i386 \
        libvulkan-dev \
        libvulkan-dev:i386 \
        xvfb

# Build wine
RUN --mount=type=cache,target=/usr/src/wine/wine-source \
    --mount=type=cache,target=/usr/src/wine/wine64-build \
    --mount=type=cache,target=/usr/src/wine/wine32-build \
    set -eux; \
    if [ ! -f wine-source/configure ]; then git clone -b add-httpsendresponseentitybody --depth=1 \
        https://gitlab.winehq.org/thelande/wine.git wine-source; fi; \
    NCPUS=$(grep -c MHz /proc/cpuinfo); \
    mkdir -p wine64-build; \
    cd wine64-build; \
    [ -f Makefile ] || ../wine-source/configure --enable-win64 --disable-tests; \
    find ./ -name '*.o' -size 0 -delete; \
    make -s -j${NCPUS}; \
    cd ..; \
    mkdir -p wine32-build; \
    cd wine32-build; \
    [ -f Makefile ] || ../wine-source/configure --with-wine64=../wine64-build --disable-tests; \
    find ./ -name '*.o' -size 0 -delete; \
    make -s -j${NCPUS}

FROM --platform=$TARGETOS/$TARGETARCH debian:bookworm-slim AS wine
LABEL maintainer="Tom Helander <thomas.helander@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive

# Upgrade base packages
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    # Include dummy bind mount from builder stage to force docker buildx to
    # build that stage.
    --mount=type=bind,from=builder,source=/mnt,target=/builder/mnt \
    set -eux; \
    dpkg --add-architecture i386; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get autoclean

# Build and install our custom wine
RUN --mount=type=cache,target=/usr/src/wine/wine-source \
    --mount=type=cache,target=/usr/src/wine/wine64-build \
    --mount=type=cache,target=/usr/src/wine/wine32-build \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        build-essential \
        gcc-mingw-w64 \
        libc6-dev \
        libc6-dev:i386 \
        wget \
    ; \
    NCPUS=$(grep -c MHz /proc/cpuinfo); \
    cd /usr/src/wine/wine32-build; \
    make install -s -j${NCPUS}; \
    cd /usr/src/wine/wine64-build; \
    make install -s -j${NCPUS}; \
    apt-get autoremove -y \
        build-essential \
        gcc-mingw-w64 \
        libc6-dev \
        libc6-dev:i386

# Install distro-version of wine to get runtime dependencies, then uninstall
# just wine.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux; \
    apt-get update; \
    apt-get install -y --install-recommends wine; \
    apt-get remove -y wine wine64 wine32; \
    apt-get autoclean

# Install winetricks
RUN	set -eux; \
    wget -q -O /usr/local/sbin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks; \
    chmod +x /usr/local/sbin/winetricks
