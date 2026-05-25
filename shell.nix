{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  packages = [
    pkgs.git
    pkgs.nixfmt-rfc-style
    pkgs.python3
  ];
}
