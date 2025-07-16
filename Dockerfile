# download SteamCMD

FROM busybox:stable AS steamcmd

ARG STEAMCMD_URL=https://cdn.akamai.steamstatic.com/client/installer/steamcmd_linux.tar.gz
ARG STEAMCMD_CHECKSUM=sha256:cebf0046bfd08cf45da6bc094ae47aa39ebf4155e5ede41373b579b8f1071e7c

ADD --checksum=$STEAMCMD_CHECKSUM $STEAMCMD_URL /tmp/steamcmd_linux.tar.gz
RUN set -eux; \
    mkdir -p /steamcmd; \
    tar xzpf /tmp/steamcmd_linux.tar.gz -C /steamcmd


# build healthcheck binary

FROM golang:1.24 AS healthcheck

WORKDIR /app

ADD healthcheck/go.mod .
ADD healthcheck/go.sum .
RUN go mod download

ADD healthcheck/*.go .
RUN go build -o /healthcheck


# list latest packages

FROM debian:bookworm-slim AS packages

ADD scripts/listpkgs.sh /

ARG CACHEBUST=0

ARG DEBIAN_FRONTEND=noninteractive
RUN set -eux; \
    # Add multiarch support \
    dpkg --add-architecture i386; \
    # Update APT cache \
    apt-get update; \
    /listpkgs.sh \
        # C/C++ libraries \
        lib32gcc-s1 \
        lib32stdc++6 \
        # bzip2 library \
        libbz2-1.0 \
        libbz2-1.0:i386 \
        # curl library \
        libcurl3-gnutls \
        libcurl3-gnutls:i386 \
        # ncurses library \
        libncurses5 \
        libncurses5:i386 \
        # zlib library \
        zlib1g \
        lib32z1 \
        # certificates \
        ca-certificates \
        # locales \
        locales \
        # init \
        dumb-init \
    | tee /packages.txt; \
    rm -rf /var/lib/apt/lists/*


# install packages and generate locales

FROM debian:bookworm-slim

COPY --from=packages /packages.txt /

ARG DEBIAN_FRONTEND=noninteractive
RUN set -eux; \
    # Add multiarch support \
    dpkg --add-architecture i386; \
    # Install requirements \
    apt-get update; \
    xargs apt-get install --assume-yes --no-install-recommends --no-install-suggests < /packages.txt; \
    rm -rf /var/lib/apt/lists/*; \
    # Generate locales \
    { \
        echo 'C.UTF-8 UTF-8'; \
        echo 'en_US.UTF-8 UTF-8'; \
    } > /etc/locale.gen; \
    locale-gen


# install gosu

COPY --from=tianon/gosu /gosu /usr/local/bin/gosu


# install steamcmd

RUN set -eux; \
    useradd --create-home --user-group steam

COPY --from=steamcmd /steamcmd/steamcmd.sh      /opt/steamcmd/steamcmd.sh
COPY --from=steamcmd /steamcmd/linux32/steamcmd /opt/steamcmd/linux32/steamcmd
COPY scripts/steamcmd /usr/local/bin/steamcmd


# download and install shdotenv

ARG SHDOTENV_URL=https://github.com/ko1nksm/shdotenv/releases/download/v0.14.0/shdotenv
ARG SHDOTENV_CHECKSUM=sha256:efa1c0aa7d59331c0823e8a3a56066db6088094052b00dae63694e046985d29e

ADD --chmod=755 --checksum=$SHDOTENV_CHECKSUM $SHDOTENV_URL /usr/local/bin/shdotenv


# install run script

ADD scripts/run.sh /run.sh
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD [ "/run.sh" ]


# install healthcheck

COPY --chown=root:root --chmod=755 --from=healthcheck /healthcheck /healthcheck
HEALTHCHECK --interval=10s --retries=6 CMD [ "/healthcheck" ]


# environment variables

ENV PUID=
ENV PGID=

ENV SRCDS_INSTALL_DIR=/srcds

ENV SRCDS_APP_ID=
ENV SRCDS_APP_BETA=
ENV SRCDS_RUN=srcds_run

ENV SRCDS_PID_FILE=/tmp/srcds.pid
