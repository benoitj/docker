#!/bin/bash -x
set -e
set -o pipefail

[ "$DEBUG" == 'true' ] && set -x

DAEMON=sshd
HOSTKEY=/etc/ssh/ssh_host_rsa_key

# set timezone
ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime

# create the host key if not already created
[[ ! -f "${HOSTKEY}" ]] && ssh-keygen -A

# create user / group git
grep -q git /etc/group || groupadd --gid $PGID git
grep -q git /etc/passwd || useradd --uid $PUID --shell /usr/bin/git-annex-shell --home-dir /home/git -g git git

mkdir -p "${HOME}/.ssh"
[ "$PUBKEY_FILE" ] && cat "$PUBKEY_FILE" > "${HOME}/.ssh/authorized_keys"

[ "$EXT_PORT" ] && echo "export EXT_PORT='$EXT_PORT'" > "${HOME}/.bashrc"

chown -R git:git "${HOME}"
chmod -R 755 "${HOME}"

# Fix permissions, if writable
if [[ -w "${HOME}/.ssh" ]]; then
    chown git:git "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh/"
fi
if [[ -w "${HOME}/.ssh/authorized_keys" ]]; then
    chown git:git "${HOME}/.ssh/authorized_keys"
    chmod 600 "${HOME}/.ssh/authorized_keys"
fi

# Warn if no config
if [[ ! -e "${HOME}/.ssh/authorized_keys" ]]; then
  echo "WARNING: No SSH authorized_keys found for git"
fi

chmod +x "${HOME}/git-shell-commands/create"
chmod +x "${HOME}/git-shell-commands/list"
chmod +x "${HOME}/git-shell-commands/no-interactive-login"

stop() {
    echo "Received SIGINT or SIGTERM. Shutting down $DAEMON"
    pid=$(cat "/var/run/${DAEMON}/${DAEMON}.pid")
    kill -SIGTERM "${pid}"
    wait "${pid}"
    echo "Done."
}

echo "Running $@"
if [[ "$(basename "$1")" == "$DAEMON" ]]; then
    trap stop SIGINT SIGTERM

    $@ &
    pid="$!"
    mkdir -p "/var/run/${DAEMON}" && echo "${pid}" > "/var/run/${DAEMON}/${DAEMON}.pid"
    wait "${pid}" && exit $?
else
    exec "$@"
fi
