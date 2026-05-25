{
  description = "Nix package set for Idris 2 packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      lib = {
        mkIdris2Packages = pkgs: import ./default.nix { inherit pkgs; };
      };

      overlays.default = import ./overlay.nix;

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          packageDerivations = import ./release.nix { inherit pkgs; };
          idris2Packages = import ./default.nix { inherit pkgs; };
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
