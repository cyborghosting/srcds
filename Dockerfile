FROM busybox:stable AS steamcmd

ARG STEAMCMD_URL=https://cdn.akamai.steamstatic.com/client/installer/steamcmd_linux.tar.gz
ARG STEAMCMD_CHECKSUM=sha256:cebf0046bfd08cf45da6bc094ae47aa39ebf4155e5ede41373b579b8f1071e7c

ADD --checksum=$STEAMCMD_CHECKSUM $STEAMCMD_URL /tmp/steamcmd_linux.tar.gz
RUN set -eux; \
    mkdir -p /steamcmd; \
    tar xzpf /tmp/steamcmd_linux.tar.gz -C /steamcmd


FROM busybox:stable AS s6-overlay

ARG S6_OVERLAY_VERSION=3.2.1.0
ARG S6_OVERLAY_DOWNLOAD_URL=https://github.com/just-containers/s6-overlay/releases/download
ARG S6_OVERLAY_NOARCH_CHECKSUM=sha256:42e038a9a00fc0fef70bf0bc42f625a9c14f8ecdfe77d4ad93281edf717e10c5
ARG S6_OVERLAY_X86_64_CHECKSUM=sha256:8bcbc2cada58426f976b159dcc4e06cbb1454d5f39252b3bb0c778ccf71c9435

ADD --checksum=$S6_OVERLAY_NOARCH_CHECKSUM ${S6_OVERLAY_DOWNLOAD_URL}/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp/s6-overlay-noarch.tar.xz
ADD --checksum=$S6_OVERLAY_X86_64_CHECKSUM ${S6_OVERLAY_DOWNLOAD_URL}/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp/s6-overlay-x86_64.tar.xz

RUN set -eux; \
    mkdir -p /s6-overlay; \
    tar xJpf /tmp/s6-overlay-noarch.tar.xz -C /s6-overlay; \
    tar xJpf /tmp/s6-overlay-x86_64.tar.xz -C /s6-overlay
    

FROM golang:1.24 AS healthcheck

WORKDIR /app

ADD healthcheck/go.mod .
ADD healthcheck/go.sum .
RUN go mod download

ADD healthcheck/*.go .
RUN go build -o /healthcheck


# Install packages and generate locales

FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive
RUN set -eux; \
    # Add multiarch support \
    dpkg --add-architecture i386; \
    # Install requirements \
    apt-get update; \
    apt-get install --assume-yes --no-install-recommends --no-install-suggests \
        # C/C++ libraries \
        lib32gcc-s1=12.2.0-14+deb12u1 \
        lib32stdc++6=12.2.0-14+deb12u1 \
        # bzip2 library \
        libbz2-1.0=1.0.8-5+b1 \
        libbz2-1.0:i386=1.0.8-5+b1 \
        # curl library \
        libcurl3-gnutls=7.88.1-10+deb12u12 \
        libcurl3-gnutls:i386=7.88.1-10+deb12u12 \
        # ncurses library \
        libncurses5=6.4-4 \
        libncurses5:i386=6.4-4 \
        # zlib library \
        zlib1g=1:1.2.13.dfsg-1 \
        lib32z1=1:1.2.13.dfsg-1 \
        # certificates \
        ca-certificates=20230311+deb12u1 \
        # locales \
        locales=2.36-9+deb12u10; \
    rm -rf /var/lib/apt/lists/*; \
    # Generate locales \
    { \
        echo 'C.UTF-8 UTF-8'; \
        echo 'en_US.UTF-8 UTF-8'; \
    } > /etc/locale.gen; \
    locale-gen


# Download and install steamcmd

RUN set -eux; \
    useradd --create-home --user-group steam

COPY --from=steamcmd --link /steamcmd/steamcmd.sh /opt/steamcmd/
COPY --from=steamcmd --link /steamcmd/linux32/steamcmd /opt/steamcmd/
COPY root/usr/local/bin/steamcmd /usr/local/bin/steamcmd


# Copy s6-overlay and setup files

COPY --from=s6-overlay --link /s6-overlay /
COPY root/etc/. /etc/
ENTRYPOINT [ "/init" ]

ENV S6_KEEP_ENV=1
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV S6_CMD_USE_TERMINAL=1

# Install shdotenv and run script

ADD --chmod=755 https://github.com/ko1nksm/shdotenv/releases/latest/download/shdotenv /usr/local/bin/shdotenv
ADD run.sh /run.sh
CMD [ "/run.sh" ]


# Install healthcheck

COPY --chown=root:root --chmod=755 --from=healthcheck /healthcheck /healthcheck
HEALTHCHECK --interval=10s --retries=6 CMD [ "/healthcheck" ]


# Environment variables

ENV PUID=
ENV PGID=

ENV SRCDS_INSTALL_DIR=/srcds

ENV SRCDS_APP_ID=
ENV SRCDS_APP_BETA=
ENV SRCDS_RUN=srcds_run

ENV SRCDS_PID_FILE=/tmp/srcds.pid
