#!/usr/bin/env bash
set -euo pipefail

AUTOSSH_SERVICE="$OUTDIR/$1"

if [[ -f "$AUTOSSH_SERVICE" ]]; then
    echo "[*] AutoSSH service already exists at $AUTOSSH_SERVICE, deleting ..."
    rm -rf "$AUTOSSH_SERVICE"
fi


mkdir -p "$OUTDIR"
touch "$AUTOSSH_SERVICE"
chmod 600 "$AUTOSSH_SERVICE"

echo "[+] Writing SSH config for host $REMOTE_HOST_ALIAS"


{

    echo "[Unit]"
    echo "Description=AutoSSH Remote Port Forward $REMOTE_HOST_ALIAS"
    echo "After=network.target"
    echo ""
    echo "[Service]"
    echo "User=${SERVICE_USER}"
    echo 'Environment="AUTOSSH_GATETIME=0"'
    echo 'Environment=AUTOSSH_POLL=10'
    echo "ExecStart=/usr/bin/autossh -M 0 -o \"ExitOnForwardFailure=yes\" -o \"ServerAliveInterval=30\" -NT \"${REMOTE_HOST_ALIAS}\""
    echo "Restart=always"
    echo "RestartSec=10"
    echo "KillMode=process"
    echo "KillSignal=SIGTERM"
    echo ""
    echo '[Install]'
    echo "WantedBy=multi-user.target"

} >> "$AUTOSSH_SERVICE"

echo "AutoSSH configuration updated"