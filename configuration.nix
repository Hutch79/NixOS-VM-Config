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

  # Docker + docker-compose (rootless mode)
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
    autoPrune = {
      enable = true;
      dates = "daily";
      flags = [ "--all" ];  # Prune everything except volumes (default behavior)
    };
    daemon.settings = {
      live-restore = true;
      default-address-pools = [
        { base = "172.17.0.0/12"; size = 27; }
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

  # User-level systemd service for luna to auto-start start docker stack
  systemd.user.services.docker-compose = {
    description = "Auto start docker stack";
    after = [ "docker.service" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "simple";
      WorkingDirectory = "/etc/nixos/services";
      ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f compose.yml up";
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f compose.yml down";
      Restart = "on-failure";
      RestartSec = "10s";
    };
    environment = {
      HOME = "/home/luna";
      DOCKER_HOST = "unix:///run/user/1010/docker.sock";
    };
  };

  services.qemuGuest.enable = true;
  
  # Boot configuration
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Enable nix flakes and nix-command
  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  system.stateVersion = "25.11";
}
