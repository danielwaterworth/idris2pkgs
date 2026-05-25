{ pkgs }:

let
  lib = pkgs.lib;
  builder = import ./build-idris-package.nix {
    inherit lib;
    inherit (pkgs)
      stdenv
      idris2
      makeWrapper
      rlwrap
      symlinkJoin
      ;
  };

  inherit (builder) mkIdris2Package idris2WithPackages;

  specs = import ../generated/packages.nix;
  overrides = import ./overrides.nix { inherit pkgs lib; };
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
  allSpecs = manualSpecs // specs;

  builtinPackages = [
    "base"
    "contrib"
    "linear"
    "network"
    "prelude"
    "test"
  ];

  packageNameToAttr = lib.listToAttrs (
    lib.mapAttrsToList (name: spec: {
      name = spec.packageName or name;
      value = name;
    }) allSpecs
  );

  isPackagedDep =
    dep:
    !(builtins.elem dep builtinPackages)
    && (builtins.hasAttr dep allSpecs || builtins.hasAttr dep packageNameToAttr);

  depAttrName = dep: if builtins.hasAttr dep allSpecs then dep else packageNameToAttr.${dep};

  packages = lib.fix (
    self:
    lib.mapAttrs (
      name: spec:
      let
        override = overrides.${name} or { };
        mergedSpec = spec // override;
        src =
          mergedSpec.src or (builtins.fetchGit {
            inherit (mergedSpec) url rev;
          });
        idrisDeps = map (dep: self.${depAttrName dep}) (
          builtins.filter isPackagedDep (mergedSpec.deps or [ ])
        );
      in
      mkIdris2Package (
        mergedSpec
        // {
          pname = name;
          inherit src idrisDeps;
        }
      )
    ) allSpecs
  );
in
packages
// {
  inherit mkIdris2Package idris2WithPackages;
  "idris2-with-packages" = idris2WithPackages;
  "mk-idris2-package" = mkIdris2Package;
}
