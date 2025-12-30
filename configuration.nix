{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./aliases.nix
      ./user-config.nix
      ./monitoring.nix
      ./system-config.nix
    ];

  environment.systemPackages = with pkgs; [
    git
    btop
    dysk
    traceroute
    ncdu
    netbird
    net-tools
    cloud-utils
  ];

  # Automatic updates
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "Sat 06:00";
    flake = "/etc/nixos";
  };

  # Set keyboard layout to Swiss German (for console)
  console.keyMap = "sg";

  services.fail2ban.enable = true;

  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  # System logging with persistent storage
  services.journald = {
    extraConfig = ''
      Storage=persistent
      MaxRetentionSec=90d
      Compress=yes
      StandardOutput=journal
    '';
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Automatic store optimization
  nix.optimise = {
    automatic = true;
    dates = "weekly";
  };

  # Docker + docker-compose (rootful mode)
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "daily";
      flags = [ "--all" ];  # Prune everything except volumes (default behavior)
    };
    daemon.settings = {
      live-restore = true;
      default-address-pools = [
        # 172.18.0.0/16 through 172.31.255.255 can be used for manual networks
        { base = "172.17.0.0/16"; size = 27; }
        { base = "192.168.0.0/16"; size = 27; }
      ];
    };
  };

  # Docker daemon restart policy
  systemd.services.docker = {
    serviceConfig = {
      Restart = "always";
      RestartMaxDelaySec = "5min";
    };
  };

  # System-level systemd service to auto-start docker stack
  systemd.services.docker-compose = {
    description = "Auto start docker stack";
    after = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      WorkingDirectory = "/etc/nixos/services";
      ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f compose.yml up";
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f compose.yml down";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  services.qemuGuest.enable = true;
  networking.wireguard.enable = true;

  # Boot configuration
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Enable nix flakes and nix-command
  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  # Allow all ports on the firewall.
  # Needs to be enabled since fail2ban depends on it.
  networking.firewall = {
    enable = true;
    allowedTCPPortRanges = [
      { from = 1; to = 65535; }
    ];
    allowedUDPPortRanges = [
      { from = 1; to = 65535; }
    ];
  };

  system.stateVersion = "25.11";
}
