#!/bin/sh -eu

export HOME=~steam

s6-setuidgid steam steamcmd +runscript /tmp/steamcmd_script.txt

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

exec s6-setuidgid steam "$EXECUTABLE" \
    -autoupdate \
    -steam_dir ~/Steam/steamcmd \
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
