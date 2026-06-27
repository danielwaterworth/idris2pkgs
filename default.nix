{
  system ? builtins.currentSystem,
  config ? { },
  overlays ? [ ],
  pkgs ? import <nixpkgs> {
    inherit system config overlays;
  },
}:

let
  lib = pkgs.lib;
  inherit (pkgs.idris2Packages) buildIdris;

  specs = import ./generated/packages.nix;
  overrides = import ./nix/overrides.nix { inherit pkgs lib; };

  ipkgName = spec: lib.removeSuffix ".ipkg" spec.ipkg;

  srcFor =
    spec:
    spec.src or builtins.fetchGit {
      inherit (spec) url rev;
    };

  propagatedIdrisLibraries =
    packages:
    lib.unique (
      lib.concatMap (package: [ package ] ++ (package.propagatedIdrisLibraries or [ ])) packages
    );

  idris2WithPackages =
    packages:
    let
      idrisPackages = propagatedIdrisLibraries packages;
      packagePath = lib.makeSearchPath "lib/idris2-${pkgs.idris2.version}" idrisPackages;
    in
    pkgs.symlinkJoin {
      pname = "idris2-with-packages";
      inherit (pkgs.idris2) version;

      paths = [ pkgs.idris2 ];
      nativeBuildInputs = [ pkgs.makeBinaryWrapper ];

      postBuild = lib.optionalString (idrisPackages != [ ]) ''
        wrapProgram "$out/bin/idris2" \
          --suffix IDRIS2_PACKAGE_PATH ':' ${lib.escapeShellArg packagePath}
      '';
    };

  mkPackage =
    name: spec:
    let
      override = overrides.${name} or { };
      attrs = {
        inherit (spec) version;
        src = srcFor spec;
        ipkgName = ipkgName spec;
        idrisLibraries = map (dep: packageSet.${dep}) (spec.deps or [ ]);
        meta = {
          homepage = spec.url;
          description = spec.description or "Idris 2 package ${spec.packageName}";
          inherit (pkgs.idris2.meta) platforms;
        }
        // (override.meta or { });
        passthru = {
          inherit spec;
        }
        // (override.passthru or { });
      }
      // builtins.removeAttrs override [
        "meta"
        "passthru"
      ];
    in
    (buildIdris attrs).library { };

  generatedPackages = lib.mapAttrs mkPackage specs;

  packageSet = {
    inherit buildIdris idris2WithPackages;
    idris2 = pkgs.idris2Packages.idris2Api;
  }
  // generatedPackages;
in
packageSet
