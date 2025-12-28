# nix-apply will not copy this file from ~/nixos to /etc/nixos!
# Network changes therefore need to be done in /etc/nixos/network.nix directly

{ config, pkgs, ... }:

{
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
}
