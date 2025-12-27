# NixOS Server Setup

Flake-based NixOS 25.11 configuration for a secure, stable server VM with rootless Docker and automated deployment via custom ISO.

## Core Configuration

### System Architecture

- **NixOS Version**: 25.11 (stable channel)
- **Experimental Features**: Flakes and nix-command enabled for modern Nix workflows
- **QEMU Guest**: Enabled for VM optimization
- **Auto Upgrade**: Weekly on Saturdays at 06:00, allows reboot, uses flake from /etc/nixos
- **Garbage Collection**: Automatic weekly, deletes generations older than 30 days
- **Store Optimization**: Automatic weekly

### Docker Setup

- **Rootless Mode**: Enabled for security (no privileged containers)
- **Custom Networks**: 172.17.0.0/12 and 192.168.0.0/16 address pools (27 usable IP per Network) to avoid oversized networks  
- **Auto-Prune**: Weekly cleanup of unused containers/images/networks (No volumes will be pruned)
- **User Service**: Docker Compose runs as systemd user service for luna user (socket at /run/user/1010/docker.sock)
- **Live Restore**: Enabled to survive daemon restarts

### Security Hardening

- **SSH**: Key-only authentication, no root login, no password/KbdInteractive auth
- **Fail2ban**: Enabled (default 5 attempts → 1-hour ban)
- **Firewall**: Container egress filtering blocks traffic to local networks (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16), CGNat (100.64.0.0/10), link-local (169.254.0.0/16); allows all other outbound and established
- **Journald**: Persistent logging with 90-day retention and compression

### User Management

- **User**: luna (UID 1010) with sudo access (wheel group) and docker/networkmanager group membership
- **SSH Keys**: Pre-configured authorized keys for passwordless login
- **Password**: Hashed for security, only used for sudo and KVM login

### Boot and Partitioning

- **Partitioning**: MBR for BIOS compatibility (avoids GPT boot issues in VMs)
- **Filesystem**: ext4 for reliability
- **Bootloader**: GRUB with MBR installation on /dev/sda

### Keyboard and Locale

- **Console Layout**: Swiss German (sg)

### Packages and Tools

- **System Packages**: git, btop, dysk, traceroute, ncdu, netbird, net-tools
- **Shell Aliases**: Nix commands (update, rebuild, prune, generations), navigation (.. ...), mkdir with parents, ll, vi/vim→nano, ports (netstat), cls

### Monitoring

- **Alloy**: Unified agent for Prometheus metrics and Loki logs (commented out, requires URLs)
  - Node metrics
  - Systemd journal logs
  - Docker container logs
  - Remote write to Prometheus and Loki with host labeling

## Deployment

### Building the ISO

Run from the project root directory:

```bash
./install/build-iso.sh
```

Creates `result/iso/nixos-minimal-*.iso` - bootable installer with baked-in configuration.

### Installation

Boot from the ISO - it will automatically detect /dev/sda and install NixOS hands-free. Alternatively, for manual control:

```bash
sudo ./install/install-on-iso.sh [--auto]
```

Script handles MBR partitioning, ext4 formatting, config copying, hardware generation, and NixOS installation. Uses /dev/sda. With --auto, runs without prompts and reboots automatically.

### Post-Install

- SSH available immediately after boot
- Docker services start automatically via user systemd
- All configurations applied from flake
