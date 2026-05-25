# idris2pkgs

`idris2pkgs` is a Nix package set for Idris 2 packages listed in
[`idris2-pack-db`](https://github.com/stefan-hoeck/idris2-pack-db).

The package metadata is generated from `idris2-pack-db` plus each package's
`.ipkg` file. Package sources are pinned to resolved commits from
`STATUS.md` when available.

## Usage

Build a package:

```sh
nix-build -A algebra
```

Create an Idris with packages environment:

```nix
let
  idris2pkgs = import ./default.nix { inherit pkgs; };
in
idris2pkgs.idris2-with-packages [
  idris2pkgs.algebra
  idris2pkgs.containers
]
```

As an overlay:

```nix
import <nixpkgs> {
  overlays = [ (import ./overlay.nix) ];
}
```

This exposes `pkgs.idris2Packages`.

Build all packages for the current `nixpkgs`:

```sh
nix-build release.nix
```

There is also a thin `flake.nix` wrapper for users who want flake commands,
but the package set does not depend on flakes.

## Private Packages

The package set exposes the same builder used for generated packages:

- `mkIdris2Package`
- `idris2WithPackages`

For a private package:

```nix
{ pkgs ? import <nixpkgs> { } }:

let
  idris2pkgs = import ./default.nix { inherit pkgs; };
in
idris2pkgs.mkIdris2Package {
  pname = "my-private-package";
  packageName = "my-private-package";
  version = "0.1.0";
  src = ./my-private-package;
  ipkg = "my-private-package.ipkg";
  idrisDeps = [
    idris2pkgs.algebra
    idris2pkgs.containers
  ];
}
```

When using the overlay, the same builder is available at
`pkgs.idris2Packages.mkIdris2Package`.

If one private package depends on another, use a recursive attribute set:

```nix
{ pkgs ? import <nixpkgs> { overlays = [ (import ./overlay.nix) ]; } }:

let
  inherit (pkgs.idris2Packages) mkIdris2Package;

  private = rec {
    core = mkIdris2Package {
      pname = "private-core";
      packageName = "private-core";
      version = "0.1.0";
      src = ./private-core;
      ipkg = "private-core.ipkg";
      idrisDeps = [ pkgs.idris2Packages.algebra ];
    };

    app = mkIdris2Package {
      pname = "private-app";
      packageName = "private-app";
      version = "0.1.0";
      src = ./private-app;
      ipkg = "private-app.ipkg";
      idrisDeps = [ core ];
    };
  };
in
private
```

## Updating

Regenerate package metadata from the current upstream Pack database:

```sh
./scripts/update-pack-db
```

The update script resolves branch names to commits, fetches the package source
for every Pack DB entry, reads its `.ipkg`, and writes
`generated/packages.nix`.

## Status

This repository generates derivations for every package entry in Pack DB.
Packages with C libraries, custom build scripts, or nonstandard toolchains may
still need entries in `nix/overrides.nix`.
