# AutoSSH Remote Port Forwarding

A simple bash script to automatically configure and manage persistent SSH reverse tunnels using AutoSSH and systemd.

## Overview

This tool automates the setup of AutoSSH with systemd to maintain reliable SSH reverse tunnels. It's useful for exposing services from a machine behind NAT/firewall to a remote server with a public IP address.

## Features

- Automatic SSH configuration generation
- Systemd service creation for AutoSSH
- Persistent connection with automatic reconnection
- Support for multiple remote port forwards
- Easy configuration through environment variables

## Prerequisites

- Linux system with systemd
- AutoSSH installed (`sudo apt install autossh` or equivalent)
- SSH access to the remote server
- SSH key pair configured
- SSH public host key*

*
``` bash
# if you never connect to the destination server, you would like to get the public SSH keys, insted you need to perform at least one remote connection and copy pub SSH key to the correct user known_hosts file, or autossh will fail, eg.
ssh-keyscan -t rsa REMOTE_HOSTNAME >> /home/SERVICE_USER/.ssh/known_hosts
```

## Optional Prerequisites
- You would like to create a system user instead a personal one which is dedicated to the systemd service ssh: 
``` bash
sudo adduser --system --shell /usr/sbin/nologin autosshuser
mkdir -p /home/autosshuser/.ssh
touch /home/autosshuser/known_hosts
ssh-keygen -t rsa -b 4096 -N "" -q -f /home/autosshuser/.ssh/id_rsa.autossh
ssh-keyscan -t rsa REMOTE_HOSTNAME >> /home/autosshuser/.ssh/known_hosts
chown -R autosshuser:autosshuser /home/autosshuser/
chmod 600 -R /home/autosshuser/
chmod 700 /home/autosshuser/
chmod 700 /home/autosshuser/.ssh
chmod 700 /home/autosshuser/.ssh/config.d

```


## Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd <repository-name>
```

2. Copy the example environment file and configure it:
```bash
cp env.example .env
vi .env
```

3. Edit `.env` with your configuration:
```bash
SERVICE_USER=your-username

REMOTE_HOST_ALIAS=remote-host
REMOTE_HOSTNAME=example.com
REMOTE_USER=remote-username
REMOTE_PORT=22
SSH_KEY=~/.ssh/id_rsa

REMOTE_FORWARDS="
0.0.0.0:2224 localhost:22
0.0.0.0:13389 localhost:3389
"
```

4. Make the installation script executable:
```bash
chmod +x install.sh
```

5. Run the installation script:
```bash
sudo ./install.sh
```

The script will:
- Generate SSH configuration
- Create a systemd service file
- Prompt you to review both files
- Copy the configuration to the appropriate directories
- Enable and start the AutoSSH service

## Configuration

### Environment Variables

- `SERVICE_USER`: Local user that will run the AutoSSH service
- `REMOTE_HOST_ALIAS`: Alias name for the SSH host configuration
- `REMOTE_HOSTNAME`: Hostname or IP address of the remote server
- `REMOTE_USER`: Username on the remote server
- `REMOTE_PORT`: SSH port on the remote server (usually 22)
- `SSH_KEY`: Path to your SSH private key
- `REMOTE_FORWARDS`: List of port forwards in the format `remote_bind:remote_port local_host:local_port`

### Port Forwarding Format

Each line in `REMOTE_FORWARDS` should follow this format:
```
[remote_bind_address:]remote_port local_host:local_port
```

Example:
```bash
REMOTE_FORWARDS="
0.0.0.0:2224 localhost:22
0.0.0.0:13389 localhost:3389
192.168.1.100:8080 localhost:80
"
```

## Usage

### Check Service Status
```bash
sudo systemctl status autossh.service
```

### View Logs
```bash
sudo journalctl -u autossh.service -f
```

### Stop Service
```bash
sudo systemctl stop autossh.service
```

### Start Service
```bash
sudo systemctl start autossh.service
```

### Restart Service
```bash
sudo systemctl restart autossh.service
```

### Disable Service
```bash
sudo systemctl disable autossh.service
```

## How It Works

1. The installation script reads configuration from `.env`
2. It generates an SSH config file with the specified host and port forwarding rules
3. It creates a systemd service unit that runs AutoSSH
4. AutoSSH maintains the SSH connection and automatically reconnects if it drops
5. The service starts automatically on system boot

## Troubleshooting

### Connection Issues

Check the service logs:
```bash
sudo journalctl -u autossh.service -n 50
```

### SSH Key Authentication

Ensure your SSH key is added to the remote server's `~/.ssh/authorized_keys`:
```bash
ssh-copy-id -i ~/.ssh/id_rsa user@remote-host
```

### Firewall Configuration

Make sure the remote server allows the forwarded ports through its firewall and has `GatewayPorts yes` in `/etc/ssh/sshd_config`.

## Project Structure

```
.
├── env.example                          # Example environment configuration
├── install.sh                           # Main installation script
├── func/
│   ├── configure_ssh.sh                # SSH configuration generator
│   └── configure_systemd_service.sh    # Systemd service generator
└── output/                             # Generated configuration files
    ├── config                          # SSH config
    └── autossh.service                # Systemd service file
```

## Security Considerations

- Keep your SSH private keys secure
- Use strong passwords or key passphrases
- Regularly update your system and AutoSSH
- Review and limit the ports you expose
- Consider using firewall rules on the remote server


## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.


## Recommended Commit Types

| Type    | Content                                   | Example Commit                                  |
|---------|-----------------------------------------------|------------------------------------------------|
| `feat`  | Adding a new feature            | `feat: add configuration script`          |
| `fix`   | Fixing an existing issue          | `fix: correct sshd config`  |
| `docs`  | Updating documentation                         | `docs: add usage instructions for plugin X`  |
| `chore` | Repo cleanup, folder reorganization, config   | `chore: reorganize functions folder`           |

