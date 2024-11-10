{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        # "aarch64-linux"
      ];

    in
    {
      nixosModules = rec {
        bird = ./modules;
        default = bird;
      };

      checks = builtins.listToAttrs (map
        (system: {
          name = system;
          value = {
            bird = import ./checks/bird.nix {
              inherit self;
              pkgs = nixpkgs.legacyPackages.${system};
            };
          };
        })
        systems);
    };
}
