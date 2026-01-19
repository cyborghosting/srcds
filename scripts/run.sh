#!/bin/sh -eu

# Fix the UID and GID of the steam user if PUID or PGID are set.
if [ -n "${PUID}" ] && [ "${PUID}" != "$(id -u steam)" ]; then
    usermod --non-unique --uid="$PUID" steam
fi
if [ -n "${PGID}" ] && [ "${PGID}" != "$(id -g steam)" ]; then
    usermod --gid="$PGID" steam
    groupmod --non-unique --gid="$PGID" steam
fi

chown --recursive steam:steam ~steam

# Create the srcds directory if it does not exist.
if [ ! -e "$SRCDS_INSTALL_DIR" ]; then
    mkdir --parent "$SRCDS_INSTALL_DIR"
    chown --reference=~steam "$SRCDS_INSTALL_DIR"
elif [ ! -d "$SRCDS_INSTALL_DIR" ]; then
    >&2 echo "\"$SRCDS_INSTALL_DIR\" is not directory"
    exit 1
fi

# Check if the steam user can access the SRCDS_INSTALL_DIR.
if ! gosu steam sh -c '[ -r "$SRCDS_INSTALL_DIR" ] && [ -w "$SRCDS_INSTALL_DIR" ] && [ -x "$SRCDS_INSTALL_DIR" ]'; then
    >&2 echo "cannot access directory \"$SRCDS_INSTALL_DIR\""
    exit 1
fi

# Check if the SRCDS_APP_ID is set.
if [ -z "${SRCDS_APP_ID:-}" ]; then
    >&2 echo "No SRCDS_APP_ID specified"
    exit 1
fi

# Create the steamcmd script if it does not exist.
if [ ! -f /tmp/steamcmd_script.txt ]; then
    {
        echo "@ShutdownOnFailedCommand 1";
        echo "@NoPromptForPassword 1";
        echo "force_install_dir ${SRCDS_INSTALL_DIR}";
        echo "login anonymous";
	if [ -z "${SRCDS_VALIDATE:-}" ]; then
            echo "app_update ${SRCDS_APP_ID}${SRCDS_APP_BETA:+ -beta ${SRCDS_APP_BETA}}";
        else
            echo "app_update ${SRCDS_APP_ID}${SRCDS_APP_BETA:+ -beta ${SRCDS_APP_BETA}} validate";
        fi
        echo "quit";
    } > /tmp/steamcmd_script.txt
fi

gosu steam steamcmd +runscript /tmp/steamcmd_script.txt

cd "${SRCDS_INSTALL_DIR}"

EXECUTABLE="${SRCDS_INSTALL_DIR}/${SRCDS_RUN}"

if [ "${USE_DOTENV:-0}" -ne "0" ] && [ -f "${SRCDS_INSTALL_DIR}/.env" ]; then
    eval "$(shdotenv --overload --grep '^SRCDS' --env "${SRCDS_INSTALL_DIR}/.env")"
fi

if [ "${SRCDS_SECURED:-1}" -ne 0 ]; then
    SRCDS_SECURITY_FLAG=-secure
else
    SRCDS_SECURITY_FLAG=-insecure
fi

set +u

exec gosu steam "$EXECUTABLE" \
    -autoupdate \
    -steam_dir ~steam/Steam/steamcmd \
    -steamcmd_script /tmp/steamcmd_script.txt \
    -pidfile "$SRCDS_PID_FILE" \
    ${SRCDS_GAME:+-game "$SRCDS_GAME"} \
    ${SRCDS_STARTMAP:++map "$SRCDS_STARTMAP"} \
    ${SRCDS_MAXPLAYERS:++maxplayers "$SRCDS_MAXPLAYERS"} \
    ${SRCDS_NORESTART:+-norestart} \
    ${SRCDS_FPSMAX:++fps_max "$SRCDS_FPSMAX"} \
    ${SRCDS_TICKRATE:+-tickrate "$SRCDS_TICKRATE"} \
    ${SRCDS_TIMEOUT:+-timeout "$SRCDS_TIMEOUT"} \
    ${SRCDS_IP:+-ip "$SRCDS_IP"} \
    ${SRCDS_PORT:+-port "$SRCDS_PORT"} \
    ${SRCDS_CLIENTPORT:++clientport "$SRCDS_CLIENTPORT"} \
    ${SRCDS_HOSTPORT:++hostport "$SRCDS_HOSTPORT"} \
    ${SRCDS_TV_PORT:++tv_port "$SRCDS_TV_PORT"} \
    ${SRCDS_PW:++sv_password "$SRCDS_PW"} \
    ${SRCDS_RCONPW:++rcon_password "$SRCDS_RCONPW"} \
    ${SRCDS_SECURITY_FLAG} \
    ${SRCDS_TOKEN:++sv_setsteamaccount "$SRCDS_TOKEN"} \
    ${SRCDS_ADDITIONAL_ARGS}
