# NixOS Server Setup

Flake-based NixOS 25.11 configuration for a secure, stable server VM with rootless Docker and semi automated deployment via custom ISO.

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
- **Shell Aliases**: 
  - Nix: `nix-update`, `nix-rebuild`, `nix-pull`, `nix-prune`, `nix-gens`
  - Navigation: `..`, `...`, `....`, `.....`
  - Utilities: `mkdir` (auto-create parents), `ll` (ls -alh), `vi/vim` → `nano`, `ports` (netstat), `cls` (clear), `pls` (sudo previous command)
  - See `aliases.nix` for more details

### Monitoring

- **Alloy**: Unified agent for Prometheus metrics and Loki logs (commented out, requires URLs)
  - Node metrics
  - Systemd journal logs
  - Docker container logs
  - Remote write to Prometheus and Loki with host labeling

## Deployment

See [install/README.md](install/README.md) for detailed installation instructions.
