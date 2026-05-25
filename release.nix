{
  pkgs ? import <nixpkgs> { },
}:

let
  idris2Packages = import ./default.nix { inherit pkgs; };
in
pkgs.lib.filterAttrs (_: pkgs.lib.isDerivation) idris2Packages
