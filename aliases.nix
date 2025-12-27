{ config, pkgs, ... }:

{
  programs.bash.shellAliases = {
     nix-update = "cd /etc/nixos && nix flake update && sudo nixos-rebuild switch --flake .";
     nix-rebuild = "cd /etc/nixos && sudo nixos-rebuild switch --flake .";
     nix-pull = "bash /etc/nixos/scripts/config-pull.sh";
     nix-prune = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +50 && sudo nix-collect-garbage";
     nix-gens = "nixos-rebuild list-generations";

     pls="sudo $(fc -ln -1)";  # Executes last command with sudo

     flatpack="flatpak";

     "cd.."="cd ..";
     ".."="cd ..";
     "..."="cd ../../";
     "...."="cd ../../../";
     "....."="cd ../../../../";

     mkdir="mkdir -pv";  # Auto create parent directorys

     ll="ls -alh";

     # I don't like vim .-.
     vi="nano" ;
     vim="nano";

     ports="netstat -tulanp";  # List open ports

     cls="clear";
  };
}
