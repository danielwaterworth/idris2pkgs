# idris2pkgs

`idris2pkgs` is a Nix package set for Idris 2 packages listed in
[`idris2-pack-db`](https://github.com/stefan-hoeck/idris2-pack-db).

The package metadata is generated from `idris2-pack-db` plus each package's
`.ipkg` file. Package sources are pinned to resolved commits from
`STATUS.md` when available.

Idris build helpers are provided by `pkgs.idris2Packages.buildIdris` from
`nixpkgs`.

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
idris2pkgs.idris2WithPackages [
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

The package set exposes the nixpkgs builder used for generated packages:

- `buildIdris`
- `idris2WithPackages`

For a private package:

```nix
{ pkgs ? import <nixpkgs> { } }:

let
  idris2pkgs = import ./default.nix { inherit pkgs; };
in
idris2pkgs.buildIdris {
  ipkgName = "my-private-package";
  version = "0.1.0";
  src = ./my-private-package;
  idrisLibraries = [
    idris2pkgs.algebra
    idris2pkgs.containers
  ];
}.library { }
```

When using the overlay, the same builder is available at
`pkgs.idris2Packages.buildIdris`.

If one private package depends on another, use a recursive attribute set:

```nix
{ pkgs ? import <nixpkgs> { overlays = [ (import ./overlay.nix) ]; } }:

let
  inherit (pkgs.idris2Packages) buildIdris;

  private = rec {
    core = buildIdris {
      ipkgName = "private-core";
      version = "0.1.0";
      src = ./private-core;
      idrisLibraries = [ pkgs.idris2Packages.algebra ];
    }.library { };

    app = buildIdris {
      ipkgName = "private-app";
      version = "0.1.0";
      src = ./private-app;
      idrisLibraries = [ core ];
    }.library { };
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
