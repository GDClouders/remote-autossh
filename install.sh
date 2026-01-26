#!/bin/bash

## remember to copy env.example in .env and edit it before running this script
set -euo pipefail


DIRSCRIPT=$(dirname "${BASH_SOURCE[0]}")
OUTDIR="$DIRSCRIPT/output"
ENV_FILE=".env"

if [[ ! -f "$ENV_FILE" ]]; then
    echo ".env file not found"
    exit 127
fi

source "$ENV_FILE"

OUTFILESSHCONFIG="config"
OUTFILESYSTEMDSERVICE="autossh.service"
source "$DIRSCRIPT/func/configure_ssh.sh" "$OUTFILESSHCONFIG"
source "$DIRSCRIPT/func/configure_systemd_service.sh" "$OUTFILESYSTEMDSERVICE"

cat $OUTDIR/$OUTFILESSHCONFIG

read -p "Please review the SSH config, Press [Enter] key to continue, or Ctrl+C to abort..."


check_and_add_ssh_include() {
    local ssh_config_file="/home/$SERVICE_USER/.ssh/config"
    local include_line="Include config.d/*"
    
    if [[ ! -d "/home/$SERVICE_USER/.ssh" ]]; then
        echo "[+] Creating .ssh directory for user $SERVICE_USER"
        mkdir -p "/home/$SERVICE_USER/.ssh"
        chmod 700 "/home/$SERVICE_USER/.ssh"
        chown "$SERVICE_USER:$SERVICE_USER" "/home/$SERVICE_USER/.ssh"
    fi
    
    if [[ ! -f "$ssh_config_file" ]]; then
        echo "[+] SSH config file doesn't exist, creating it with Include directive"
        echo "$include_line" > "$ssh_config_file"
        chmod 600 "$ssh_config_file"
        chown "$SERVICE_USER:$SERVICE_USER" "$ssh_config_file"
        echo "[✓] Include directive added to new SSH config"
        return 0
    fi
    
    # Check if Include directive already exists
    if grep -qE "^[[:space:]]*Include[[:space:]]+config\.d/\*" "$ssh_config_file"; then
        echo "[✓] Include directive already present in SSH config"
        return 0
    fi
    
    echo "[+] Adding Include directive to existing SSH config"
    
    local temp_file=$(mktemp)
    echo "$include_line" > "$temp_file"
    echo "" >> "$temp_file"
    cat "$ssh_config_file" >> "$temp_file"
    
    mv "$temp_file" "$ssh_config_file"
    chmod 600 "$ssh_config_file"
    chown "$SERVICE_USER:$SERVICE_USER" "$ssh_config_file"
    
    echo "[✓] Include directive added to SSH config"
}

check_and_add_ssh_include



cp "$OUTDIR/$OUTFILESSHCONFIG" /home/$SERVICE_USER/.ssh/config.d/${REMOTE_HOST_ALIAS}-autossh_config.conf
echo "[+] SSH config copied to /home/$SERVICE_USER/.ssh/config.d/${REMOTE_HOST_ALIAS}-autossh_config.conf"

cat $OUTDIR/$OUTFILESYSTEMDSERVICE

read -p "Please review the AutoSSH.service, Press [Enter] key to continue, or Ctrl+C to abort..."


sudo cp "$OUTDIR/$OUTFILESYSTEMDSERVICE" /etc/systemd/system/autossh.service


sudo systemctl daemon-reload
sudo systemctl enable autossh.service
sudo systemctl start autossh.service    
echo "[+] AutoSSH service started"

echo "[+] Installation complete. Use 'sudo systemctl status autossh.service' to check the service status."
