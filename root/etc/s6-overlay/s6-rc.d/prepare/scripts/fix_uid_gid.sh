#!/bin/sh -eu

usermod --non-unique --uid="$UID" --gid="$GID" steam
groupmod --non-unique --gid="$GID" steam

chown --recursive "$UID:$GID" ~steam

