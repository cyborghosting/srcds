#!/bin/sh -eu

if [ ! -f /tmp/steamcmd_script.txt ]; then
	{
		echo "@ShutdownOnFailedCommand 1";
		echo "@NoPromptForPassword 1";
		echo "force_install_dir $SRCDS_INSTALL_DIR";
		echo "login anonymous";
		echo "app_update ${SRCDS_APP_ID:?NO APP ID SPECIFIED}${SRCDS_APP_BETA:+ -beta ${SRCDS_APP_BETA}}";
		echo "quit";
	} > /tmp/steamcmd_script.txt 
fi

