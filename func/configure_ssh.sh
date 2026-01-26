#!/usr/bin/env bash
set -euo pipefail

SSH_CONFIG="$OUTDIR/$1"

if [[ -f "$SSH_CONFIG" ]]; then
    echo "[*] SSH config already exists at $SSH_CONFIG, deleting ..."
    rm -rf "$SSH_CONFIG"
fi

mkdir -p "$OUTDIR"
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"



echo "[+] Writing SSH config for host $REMOTE_HOST_ALIAS"

{
    echo ""
    echo "Host $REMOTE_HOST_ALIAS"
    echo "    HostName $REMOTE_HOSTNAME"
    echo "    User $REMOTE_USER"
    echo "    Port $REMOTE_PORT"
    echo "    IdentityFile $SSH_KEY"
    echo "    Compression yes"
    echo "    ServerAliveInterval 30"
    echo "    ServerAliveCountMax 3"
    echo "    GatewayPorts yes"
    echo "    ExitOnForwardFailure yes"

    while read -r forward; do
        [[ -z "$forward" ]] && continue
        echo "    RemoteForward $forward"
    done <<< "$REMOTE_FORWARDS"

} >> "$SSH_CONFIG"
echo $SSH_CONFIG
echo $OUTDIR
echo $1
echo "SSH configuration updated"