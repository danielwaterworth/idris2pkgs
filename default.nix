{
  system ? builtins.currentSystem,
  config ? { },
  overlays ? [ ],
  pkgs ? import <nixpkgs> {
    inherit system config overlays;
  },
}:

import ./nix/package-set.nix { inherit pkgs; }
