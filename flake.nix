{
  description = "Modular NixOS config with flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... }:
  {
      nixosConfigurations."Nix-Template" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          pkgsUnstable = import nixpkgs-unstable
          {
            system = "x86_64-linux";
            config = { allowUnfree = true; };
          };
        };

        modules = [ ./configuration.nix ];
      };

      # Custom ISO configuration
      nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          pkgsUnstable = import nixpkgs-unstable
          {
            system = "x86_64-linux";
            config = { allowUnfree = true; };
          };
        };

        modules = [ ./install/iso-configuration.nix ];
      };
    };
}
