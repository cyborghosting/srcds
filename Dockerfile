# Declare environment variables

FROM debian:bookworm-slim AS stage-1

ENV UID=999
ENV GID=999
ENV GIDLIST=

ENV SRCDS_INSTALL_DIR=/srcds

ENV SRCDS_APP_ID=
ENV SRCDS_APP_BETA=
ENV SRCDS_RUN=srcds_run

ENV SRCDS_PID_FILE=/tmp/srcds.pid


# Install packages and generate locales

FROM stage-1 AS stage-2

ARG DEBIAN_FRONTEND=noninteractive
RUN set -eux; \
    # Add multiarch support \
    dpkg --add-architecture i386; \
    # Install requirements \
    apt-get update; \
    apt-get install --assume-yes --no-install-recommends --no-install-suggests \
        # C/C++ libraries \
        lib32gcc-s1=12.2.0-14 \
        lib32stdc++6=12.2.0-14 \
        # bzip2 library \
        libbz2-1.0=1.0.8-5+b1 \
        libbz2-1.0:i386=1.0.8-5+b1 \
        # curl library \
        libcurl3-gnutls=7.88.1-10+deb12u8 \
        libcurl3-gnutls:i386=7.88.1-10+deb12u8 \
        # ncurses library \
        libncurses5=6.4-4 \
        libncurses5:i386=6.4-4 \
        # zlib library \
        zlib1g=1:1.2.13.dfsg-1 \
        lib32z1=1:1.2.13.dfsg-1 \
        # certificates \
        ca-certificates=20230311 \
        # locales \
        locales=2.36-9+deb12u9; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    # Generate locales \
    { \
        echo 'C.UTF-8 UTF-8'; \
        echo 'en_US.UTF-8 UTF-8'; \
    } > /etc/locale.gen; \
    locale-gen


# Download and install steamcmd

FROM busybox:stable AS steamcmd

ARG STEAMCMD_URL=https://cdn.akamai.steamstatic.com/client/installer/steamcmd_linux.tar.gz

ADD $STEAMCMD_URL /tmp

RUN set -eux; \
    mkdir -p /steamcmd; \
    tar -C /steamcmd -zxpf /tmp/steamcmd_linux.tar.gz

FROM stage-2 AS stage-3

RUN set -eux; \
    groupadd --system --gid "$GID" steam; \
    useradd --system --create-home --uid "$UID" --gid "$GID" steam

COPY --from=steamcmd --link /steamcmd/steamcmd.sh /steamcmd/linux32/steamcmd /usr/local/lib/steam/
COPY root/usr /usr

USER steam
RUN set -eux; \
    steamcmd +quit

USER root


# Download and install s6-overlay

FROM busybox:stable AS s6-overlay

ARG S6_OVERLAY_VERSION=3.2.0.2

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp

RUN set -eux; \
    mkdir -p /s6-overlay; \
    tar -C /s6-overlay -Jxpf /tmp/s6-overlay-noarch.tar.xz; \
    tar -C /s6-overlay -Jxpf /tmp/s6-overlay-x86_64.tar.xz
    
FROM stage-3 AS stage-4

COPY --from=s6-overlay --link /s6-overlay /
COPY root/etc /etc

ENTRYPOINT [ "/init" ]

ENV S6_KEEP_ENV=1


# Install setup script

FROM stage-4 AS stage-5

ADD --chmod=755 https://github.com/ko1nksm/shdotenv/releases/latest/download/shdotenv /usr/local/bin/shdotenv

ADD run.sh /run.sh

CMD [ "/run.sh" ]


# Add healthcheck funtionality

FROM golang:1.24-bookworm AS healthcheck

WORKDIR /app

ADD healthcheck/go.mod .
ADD healthcheck/go.sum .
RUN go mod download

ADD healthcheck/*.go .
RUN go build -o /healthcheck

FROM stage-5 AS stage-6

COPY --chown=root:root --chmod=755 --from=healthcheck /healthcheck /healthcheck
HEALTHCHECK --interval=10s --retries=6 CMD [ "/healthcheck" ]

FROM stage-6

