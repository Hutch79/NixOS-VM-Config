# NixOS Server Setup

Flake-based NixOS 25.11 configuration for a secure, stable server VM with rootless Docker and semi automated deployment via custom ISO.

## Table of Contents

- [Core Configuration](#core-configuration)
  - [System Architecture](#system-architecture)
  - [Docker Setup](#docker-setup)
  - [Security Hardening](#security-hardening)
  - [User Management](#user-management)
  - [Boot and Partitioning](#boot-and-partitioning)
  - [Keyboard and Locale](#keyboard-and-locale)
  - [Packages and Tools](#packages-and-tools)
  - [Monitoring](#monitoring)
- [Deployment](#deployment)
- [Customization for Your Setup](#customization-for-your-setup)
  - [User Configuration](#user-configuration-user-confignix)
  - [Hostname](#hostname)
  - [Repository URLs](#repository-urls)
  - [Services and Ports](#services-and-ports)
  - [Optional Customization](#optional-customization)

## Core Configuration

### System Architecture

- **NixOS Version**: 25.11 (stable channel)
- **Experimental Features**: Flakes and nix-command enabled for modern Nix workflows
- **QEMU Guest**: Enabled for VM optimization
- **Auto Upgrade**: Weekly on Saturdays at 06:00 (allowes you to fix shit on the weekend ^^'), allows reboot, uses flake from /etc/nixos
- **Garbage Collection**: Automatic weekly, deletes generations older than 30 days
- **Store Optimization**: Automatic weekly

### Docker Setup

- **Rootless Mode**: Enabled for security (no privileged containers)
- **Network size**: 172.17.0.0/12 and 192.168.0.0/16 address pools (27 usable IP per Network) to avoid oversized networks  
- **Auto-Prune**: Daily cleanup of unused containers/images/networks (No volumes will be pruned)
- **User Service**: Docker Compose runs as systemd user service for luna user (socket at /run/user/1010/docker.sock)
- **Live Restore**: Enabled to survive daemon restarts

### Security Hardening

- **SSH**: Key-only authentication, no root login, no password/KbdInteractive auth
- **Fail2ban**: Enabled (default 5 attempts → 1-hour ban)
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
  - See [configuration.nix](configuration.nix) `environment.systemPackages` (line 12) for details
- **Shell Aliases**:
  - See [aliases.nix](aliases.nix) for more details

### Monitoring

- **Alloy**: Unified agent for Prometheus metrics and Loki logs (commented out, requires URLs)
  - Node metrics
  - Systemd journal logs
  - Docker container logs
  - Remote write to Prometheus and Loki with host labeling

## Deployment

See [install/README.md](install/README.md) for detailed installation instructions.

## Customization for Your Setup

Before deploying this configuration, update the following in the repository:

### User Configuration ([user-config.nix](user-config.nix))

- **Username**: Change `luna` to your desired username
- **SSH Keys**: Replace the authorized_keys with your public SSH key(s)
- **Password Hash**: Generate a new hashed password with `mkpasswd -m sha-512`

### Hostname

- **[configuration.nix](configuration.nix)**: Change `Nix-Template` in `networking.hostName`
- **[flake.nix](flake.nix)**: Change `Nix-Template` in `nixosConfigurations`

### Repository URLs

Update git repository URLs for your fork:

- **[install/install-on-iso.sh](install/install-on-iso.sh)**: Change `REPO_URL` to your repository
- **[scripts/config-pull.sh](scripts/config-pull.sh)**: Update `REPO_URL` to your repository
- **[scripts/config-init.sh](scripts/config-init.sh)**: Update `REPO_URL` to your repository

### Services and Ports

- **[services/compose.yml](services/compose.yml)**: Customize Docker Compose services, ports, environment variables, and volumes for your needs

### Optional Customization

- **[configuration.nix](configuration.nix)**:
  - Uncomment and configure static networking if needed
  - Enable and configure monitoring (Alloy) with your Prometheus/Loki URLs
  - Adjust auto-upgrade schedule if desired
- **[aliases.nix](aliases.nix)**: Add or modify shell aliases to match your workflow
