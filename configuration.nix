{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./aliases.nix
      ./user-config.nix
      ./monitoring.nix
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

  networking.hostName = "Nix-Template";

  services.qemuGuest.enable = true;
  
  # Boot configuration
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Static network configuration
  networking.useDHCP = true;
  # networking.interfaces.eth0 = {
  #   ipv4.addresses = [
  #     {
  #       address = "10.0.69.200";
  #       prefixLength = 24;
  #     }
  #   ];
  # };
  # networking.defaultGateway = "10.0.0.1";
  # networking.nameservers = [ "10.0.0.1" "1.1.1.1" "9.9.9.9" "8.8.8.8" ];

  # Set keyboard layout to Swiss German (for console)
  console.keyMap = "sg";

  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  services.fail2ban.enable = true;

  # System logging with persistent storage
  services.journald = {
    extraConfig = ''
      Storage=persistent
      MaxRetentionSec=90d
      Compress=yes
      StandardOutput=journal
    '';
  };

  # Enable nix flakes and nix-command
  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  # Automatic updates
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "Sat 06:00";
    flake = "/etc/nixos";
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
      dates = "weekly";
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

  # User-level systemd service for luna to auto-start start Komodo Periphery
  systemd.user.services.docker-compose = {
    description = "Auto start Komodo Periphery";
    after = [ "docker.service" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "simple";
      WorkingDirectory = "/etc/nixos";
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

  system.stateVersion = "25.11";
}
