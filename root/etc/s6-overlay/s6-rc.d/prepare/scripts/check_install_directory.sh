#!/bin/sh -eu

if [ -f "$SRCDS_INSTALL_DIR" ]; then
	>&2 echo "\"$SRCDS_INSTALL_DIR\" is not directory"
	exit 1
elif [ ! -d "$SRCDS_INSTALL_DIR" ]; then
	mkdir -p "$SRCDS_INSTALL_DIR" 
	chown "$UID:$GID" "$SRCDS_INSTALL_DIR"
	chmod u+rwx "$SRCDS_INSTALL_DIR"
fi

if ! s6-applyuidgid -U test -r "$SRCDS_INSTALL_DIR"; then
	>&2 echo "cannot read from directory \"$SRCDS_INSTALL_DIR\""
	exit 1
elif ! s6-applyuidgid -U test -w "$SRCDS_INSTALL_DIR"; then
	>&2 echo "cannot write to directory \"$SRCDS_INSTALL_DIR\""
	exit 1
elif ! s6-applyuidgid -U test -x "$SRCDS_INSTALL_DIR"; then
	>&2 echo "cannot change directory into directory \"$SRCDS_INSTALL_DIR\""
	exit 1
fi

