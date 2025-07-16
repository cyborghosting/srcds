#!/bin/sh -eu

get_version ( ) {
	apt-cache policy "$1" | grep 'Candidate:' | head -1 | sed -e 's/^  Candidate: \(.\+\)/\1/'
}

for package in "$@"; do
	version=$(get_version "${package}")
	echo "${package}=${version}"
done
