{ pkgs, lib }:

{
  crypt = {
    buildInputs = [ pkgs.libxcrypt ];
  };

  distribution = {
    nativeBuildInputs = [ pkgs.gsl ];
    buildInputs = [ pkgs.gsl ];
  };

  idris2-dep-graph = {
    preBuild = ''
      substituteInPlace idris2-dep-graph.ipkg \
        --replace-fail '  = idris2 >= 0.8.0' '  = idris2 >= 0.8.0
        , network'
    '';
  };

  idris2-go = {
    preBuild = ''
      substituteInPlace idris2-go.ipkg \
        --replace-fail 'depends = idris2' 'depends = idris2, network'
    '';
  };

  idris2-lsp = {
    preBuild = ''
      sed -i '/=> Ref PostS PostSession/d' src/Server/ProcessMessage.idr src/Server/Main.idr
      sed -i '/p <- newRef PostS defaultPost/d' src/Server/Main.idr
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
    preBuild = ''
      export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -I${lib.getDev pkgs.SDL2}/include/SDL2"
    '';
    postInstall = ''
      mkdir -p $out/lib
      cp -R lib/* $out/lib/
    '';
  };

  markdown = {
    preBuild = ''
      substituteInPlace src/Text/Markdown/Tokens.idr \
        --replace-fail "rtrim . drop 3 <$> head' ls" "trim . drop 3 <$> head' ls"
    '';
  };

  ncurses-idris = {
    buildInputs = [ pkgs.ncurses ];
    postInstall = ''
      TARGET_VERSION=0.4.0 make -C support install INSTALLDIR=$out/lib/idris2-${pkgs.idris2.version}/ncurses-idris-0.4.0/lib
      mkdir -p $out/lib
      cp -R $out/lib/idris2-${pkgs.idris2.version}/ncurses-idris-0.4.0/lib/* $out/lib/
    '';
  };

  pg-idris = {
    buildInputs = [ pkgs.libpq ];
    preBuild = ''
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
    '';
    postInstall = ''
      export PATH="$PWD/.nix-bin:$PATH"
      TARGET_VERSION=0.0.8 make -C support install INSTALLDIR=$out/lib/idris2-${pkgs.idris2.version}/pg-idris-0.0.8
      mkdir -p $out/lib
      cp -R $out/lib/idris2-${pkgs.idris2.version}/pg-idris-0.0.8/lib/* $out/lib/
    '';
  };

  rtlsdr = {
    buildInputs = [ pkgs.rtl-sdr ];
  };

  sqlite3 = {
    buildInputs = [ pkgs.sqlite ];
  };

  spidr = {
    preInstall = ''
      export SPIDR_LOCAL_INSTALL=true
    '';
  };

  uv = {
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.libuv ];
    postInstall = ''
      make -C support install INSTALLDIR=$out/lib/idris2-${pkgs.idris2.version}/uv-0.1.0/lib
      mkdir -p $out/lib
      cp -R $out/lib/idris2-${pkgs.idris2.version}/uv-0.1.0/lib/* $out/lib/
    '';
  };

  uv-data = {
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.libuv ];
    preBuild = ''
      pushd data
      patchShebangs gencode.sh cleanup.sh
      popd
    '';
    postBuild = ''
      mkdir -p data/build
    '';
  };

  uuid = {
    preInstall = ''
      export UUID_NOINSTALL_SUPPORT=true
    '';
  };

  pjrt-plugin-xla-cpu = {
    preInstall = ''
      export SPIDR_LOCAL_INSTALL=true
    '';
  };

  pjrt-plugin-xla-cuda = {
    preInstall = ''
      export SPIDR_LOCAL_INSTALL=true
    '';
  };
}
