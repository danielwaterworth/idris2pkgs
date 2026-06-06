{
  description = "Nix package set for Idris 2 packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-idris2 = {
      url = "git+ssh://git@github.com/danielwaterworth/nix-idris2.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, nix-idris2, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      mkIdris2Packages =
        pkgs:
        import ./default.nix {
          inherit pkgs;
          idris2Helpers = nix-idris2.lib.mkIdris2 pkgs;
        };
    in
    {
      lib = {
        inherit mkIdris2Packages;
      };

      overlays.default = final: prev: {
        idris2Packages = import ./default.nix {
          pkgs = final;
          idris2Helpers = nix-idris2.lib.mkIdris2 final;
        };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          idris2Packages = mkIdris2Packages pkgs;
          packageDerivations =
            pkgs.lib.filterAttrs
              (_: value: pkgs.lib.isDerivation value)
              idris2Packages;
        in
        packageDerivations
        // {
          default = idris2Packages.idris2WithPackages [ ];
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = import ./shell.nix { inherit pkgs; };
        }
      );
    };
}
