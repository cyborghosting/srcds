#!/bin/sh -eu

get_version ( ) {
	apt-cache --pkg-cache "pkgcache.bin" show "$1" | grep 'Version:' | head -1 | sed -e 's/^Version: \(.\+\)/\1/'
}

for package in "$@"; do
	version=$(get_version "${package}")
	echo "${package}=${version}"
done
