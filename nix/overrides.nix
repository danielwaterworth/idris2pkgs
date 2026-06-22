{ pkgs, lib }:

{
  crypt = {
    buildInputs = [ pkgs.libxcrypt ];
  };

  distribution = {
    nativeBuildInputs = [ pkgs.gsl ];
    buildInputs = [ pkgs.gsl ];
  };

  idris2 = {
    buildPhase = ''
      make src/IdrisPaths.idr PREFIX=$out
      idris2 --build idris2api.ipkg
    '';
  };

  idris2-dep-graph = {
    buildPhase = ''
      substituteInPlace idris2-dep-graph.ipkg \
        --replace-fail '  = idris2 >= 0.8.0' '  = idris2 >= 0.8.0
        , network'
      idris2 --build idris2-dep-graph.ipkg
    '';
  };

  idris2-go = {
    buildPhase = ''
      substituteInPlace idris2-go.ipkg \
        --replace-fail 'depends = idris2' 'depends = idris2, network'
      idris2 --build idris2-go.ipkg
    '';
  };

  idris2-lsp = {
    buildPhase = ''
      sed -i '/=> Ref PostS PostSession/d' src/Server/ProcessMessage.idr src/Server/Main.idr
      sed -i '/p <- newRef PostS defaultPost/d' src/Server/Main.idr
      idris2 --build idris2-lsp.ipkg
    '';
  };

  idrisGL = {
    buildInputs = [
      pkgs.SDL2
      pkgs.SDL2_gfx
      pkgs.SDL2_image
      pkgs.SDL2_mixer
      pkgs.SDL2_ttf
    ];
    buildPhase = ''
      export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -I${lib.getDev pkgs.SDL2}/include/SDL2"
      idris2 --build idrisGL.ipkg
    '';
    postInstall = ''
      mkdir -p $out/idris-packages/idris2-${pkgs.idris2.version}/idrisGL-1.0.0/lib $out/lib
      cp -R lib/* $out/idris-packages/idris2-${pkgs.idris2.version}/idrisGL-1.0.0/lib/
      cp -R lib/* $out/lib/
    '';
  };

  markdown = {
    buildPhase = ''
      substituteInPlace src/Text/Markdown/Tokens.idr \
        --replace-fail "rtrim . drop 3 <$> head' ls" "trim . drop 3 <$> head' ls"
      idris2 --build markdown.ipkg
    '';
  };

  ncurses-idris = {
    buildInputs = [ pkgs.ncurses ];
    postInstall = ''
      TARGET_VERSION=0.4.0 make -C support install INSTALLDIR=$out/idris-packages/idris2-${pkgs.idris2.version}/ncurses-idris-0.4.0/lib
      mkdir -p $out/lib
      cp -R $out/idris-packages/idris2-${pkgs.idris2.version}/ncurses-idris-0.4.0/lib/* $out/lib/
    '';
  };

  pg-idris = {
    buildInputs = [ pkgs.libpq ];
    buildPhase = ''
      mkdir -p .nix-bin
      cat > .nix-bin/pg_config <<'EOF'
      #! ${pkgs.runtimeShell}
      case "$1" in
        --includedir) echo "${lib.getDev pkgs.libpq}/include" ;;
        --libdir) echo "${lib.getLib pkgs.libpq}/lib" ;;
        *) exit 1 ;;
      esac
      EOF
      chmod +x .nix-bin/pg_config
      export PATH="$PWD/.nix-bin:$PATH"
      idris2 --build pg-idris.ipkg
    '';
    postInstall = ''
      export PATH="$PWD/.nix-bin:$PATH"
      TARGET_VERSION=0.0.8 make -C support install INSTALLDIR=$out/idris-packages/idris2-${pkgs.idris2.version}/pg-idris-0.0.8
      mkdir -p $out/lib
      cp -R $out/idris-packages/idris2-${pkgs.idris2.version}/pg-idris-0.0.8/lib/* $out/lib/
    '';
  };

  rtlsdr = {
    buildInputs = [ pkgs.rtl-sdr ];
  };

  sqlite3 = {
    buildInputs = [ pkgs.sqlite ];
  };

  uv = {
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.libuv ];
    postInstall = ''
      make -C support install INSTALLDIR=$out/idris-packages/idris2-${pkgs.idris2.version}/uv-0.1.0/lib
      mkdir -p $out/lib
      cp -R $out/idris-packages/idris2-${pkgs.idris2.version}/uv-0.1.0/lib/* $out/lib/
    '';
  };

  uv-data = {
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.libuv ];
    buildPhase = ''
      pushd data
      patchShebangs gencode.sh cleanup.sh
      idris2 --build uv-data.ipkg
      popd
      mkdir -p data/build
    '';
  };
}
