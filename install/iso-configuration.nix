# Custom NixOS ISO Builder
# This creates an installable ISO with your full configuration baked in

{ config, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # NixOS release version
  system.stateVersion = "25.11";

  # Enable experimental features (flakes)
  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  # Set keyboard layout to Swiss German (for both console and X server)
  console.useXkbConfig = true;
  services.xserver.xkb.layout = "ch";
  services.xserver.xkb.variant = "de";
  services.xserver.xkb.options = "kpdl:dot";  # Use dot instead of comma on numpad

  # Add your configuration files to the ISO
  environment.etc."nixos/configuration.nix".source = ../configuration.nix;
  environment.etc."nixos/user-config.nix".source = ../user-config.nix;
  environment.etc."nixos/aliases.nix".source = ../aliases.nix;
  environment.etc."nixos/monitoring.nix".source = ../monitoring.nix;
  environment.etc."nixos/flake.nix".source = ../flake.nix;
  environment.etc."nixos/flake.lock".source = ../flake.lock;
  environment.etc."nixos/compose.yml".source = ../services/compose.yml;

  # Add scripts to the ISO
  environment.etc."nixos/scripts/config-pull.sh".source = ../scripts/config-pull.sh;
  environment.etc."nixos/scripts/config-pull.sh".mode = "0755";
  environment.etc."nixos/scripts/config-init.sh".source = ../scripts/config-init.sh;
  environment.etc."nixos/scripts/config-init.sh".mode = "0755";

  # Add installation script to ISO
  environment.etc."nixos/install-on-iso.sh".source = ./install-on-iso.sh;
  environment.etc."nixos/install-on-iso.sh".mode = "0755";

  # Add helpful tools
  environment.systemPackages = with pkgs; [
    curl
    nano
    parted
    e2fsprogs
    dosfstools
  ];

  # Add a startup message
  environment.etc."issue".text = ''

    ║       NixOS Server Setup - Custom Installation ISO        ║
    ║                                                           ║
    ║  Installation will start automatically on boot.           ║
    ║  Or run manually:                                         ║
    ║  $ sudo /etc/nixos/install-on-iso.sh [--auto]             ║
    ║                                                           ║
    ║  Configuration is already included on this ISO!           ║
    ╚═══════════════════════════════════════════════════════════╝

  '';

  # Auto-run the install script on boot for hands-free installation
  systemd.services.auto-install = {
    description = "Auto install NixOS";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "getty.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/etc/nixos/install-on-iso.sh --auto";
      StandardOutput = "journal+console";
      StandardError = "journal+console";
      User = "root";
    };
  };
}
