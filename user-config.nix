{ config, pkgs, ... }:

{
  users.users.luna = {
    isNormalUser = true;
    uid = 1010;
    description = "Luna";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    hashedPassword = "$6$NXnztz57WwSU9sR1$LG/7hDdP9q6NQNIjTjtyNoEfpkxcGH.yWV2fW.FAvAyjKoCapZ6DfO4TPe.B9SfxHj6llG8FZL8v1jFuxPklf0";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMuBOfqBaeMEVnhtKF7HEO3PmxXP0JZX3LP7JcfIVSjM"
    ];
    packages = with pkgs; [

    ];
  };
}
