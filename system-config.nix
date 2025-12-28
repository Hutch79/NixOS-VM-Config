# nix-apply will not copy this file from ~/nixos to /etc/nixos!
# Network changes therefore need to be done in /etc/nixos/network.nix directly

{ config, pkgs, ... }:

{
  networking.hostName = "Nix-Template";

  networking.useDHCP = true;
  # networking.interfaces.eth0 = {
  #   ipv4.addresses = [
  #     {
  #       address = "10.0.1.XXX";
  #       prefixLength = 16;
  #     }
  #   ];
  # };
  # networking.defaultGateway.address = "10.0.0.1";
  # networking.nameservers = [ "10.0.0.1" "1.1.1.1" "9.9.9.9" "8.8.8.8" ];
}
