{
  system ? builtins.currentSystem,
  config ? { },
  overlays ? [ ],
  pkgs ? import <nixpkgs> {
    inherit system config overlays;
  },
  idris2Helpers ? import (builtins.fetchGit {
    url = "git@github.com:danielwaterworth/nix-idris2.git";
    rev = "8ca72e2ab5a263d5a8c7d6c5441ad6303040207e";
  }) { inherit pkgs; },
}:

let
  lib = pkgs.lib;

  packageSet = idris2Helpers.mkPackageSet {
    specs = import ./generated/packages.nix;
    overrides = import ./nix/overrides.nix { inherit pkgs lib; };
    manualSpecs = {
      idris2 = {
        packageName = "idris2";
        version = pkgs.idris2.version;
        src = pkgs.idris2.src;
        ipkg = "idris2api.ipkg";
        deps = [ ];
        description = "Idris 2 compiler API";
      };
    };
  };
in
packageSet
// {
  "idris2-with-packages" = packageSet.idris2WithPackages;
  "mk-idris2-package" = packageSet.mkIdris2Package;
}
