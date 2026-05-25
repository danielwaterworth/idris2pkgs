final: prev:

{
  idris2Packages = import ./default.nix {
    pkgs = final;
  };
}
