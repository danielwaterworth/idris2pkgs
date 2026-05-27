{
  lib,
  stdenv,
  idris2,
  makeWrapper,
  rlwrap,
  symlinkJoin,
}:

let
  idris2LibDir = "idris2-${idris2.version}";

  collectIdrisDeps =
    deps:
    lib.unique (lib.concatMap (dep: collectIdrisDeps (dep.passthru.idrisDeps or [ ]) ++ [ dep ]) deps);

  idris2WithPackages =
    libs:
    let
      allLibs = collectIdrisDeps libs;
    in
    symlinkJoin {
      name = "idris2-with-packages";
      paths = [
        rlwrap
        idris2
      ]
      ++ allLibs;
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/idris2 \
          --prefix IDRIS2_PACKAGE_PATH : $out/idris-packages/${idris2LibDir}

        mv $out/bin/idris2 $out/bin/idris2.wrap2
        printf '%s\n' \
          '#! ${stdenv.shell}' \
          'exec ${rlwrap}/bin/rlwrap "$(dirname "$0")/idris2.wrap2" "$@"' \
          > $out/bin/idris2
        chmod +x $out/bin/idris2
      '';
    };

in
{
  inherit idris2WithPackages;

  mkIdris2Package =
    {
      pname,
      packageName ? pname,
      version,
      src,
      ipkg ? "${packageName}.ipkg",
      idrisDeps ? [ ],
      nativeBuildInputs ? [ ],
      buildInputs ? [ ],
      buildPhase ? null,
      installPhase ? null,
      doCheck ? false,
      doInstallDocs ? true,
      checkPhase ? "",
      passthru ? { },
      meta ? { },
      postInstall ? "",
      ...
    }:
    let
      idris = idris2WithPackages idrisDeps;
      ipkgDir = builtins.dirOf ipkg;
      buildDir = if ipkgDir == "." then "build" else "${ipkgDir}/build";
      packageDir = "$out/idris-packages/${idris2LibDir}/${packageName}-${version}";
    in
    stdenv.mkDerivation {
      inherit
        pname
        version
        src
        doCheck
        meta
        ;

      nativeBuildInputs = [ idris ] ++ nativeBuildInputs;
      inherit buildInputs;

      buildPhase =
        if buildPhase == null then
          ''
            runHook preBuild
            idris2 --build ${ipkg}
            runHook postBuild
          ''
        else
          ''
            runHook preBuild
            ${buildPhase}
            runHook postBuild
          '';

      checkPhase = ''
        runHook preCheck
        ${checkPhase}
        runHook postCheck
      '';

      installPhase =
        if installPhase == null then
          ''
            runHook preInstall
            mkdir -p ${packageDir}
            actualBuildDir=$(
              awk -F= '
                /^[[:space:]]*builddir[[:space:]]*=/ {
                  builddir = $2
                  gsub(/^[[:space:]"]+|[[:space:]"]+$/, "", builddir)
                  print builddir
                }
              ' ${ipkg} | tail -n 1
            )
            if [ -z "$actualBuildDir" ]; then
              actualBuildDir=${buildDir}
            elif [ "${ipkgDir}" != "." ] && [[ "$actualBuildDir" != /* ]]; then
              actualBuildDir=${ipkgDir}/$actualBuildDir
            fi
            ${lib.optionalString doInstallDocs ''
              idris2 --mkdoc ${ipkg}
            ''}
            if [ -d "$actualBuildDir/ttc" ]; then
              cp -R "$actualBuildDir/ttc/." ${packageDir}/
            fi
            if [ -d "$actualBuildDir/docs" ]; then
              cp -R "$actualBuildDir/docs" ${packageDir}/
            fi
            awk '
              /^[[:space:]]*package[[:space:]]+/ { print; next }
              /^[[:space:]]*version[[:space:]]*=/ { print; next }
              /^[[:space:]]*depends([[:space:]]*=)?[[:space:]]*/ { print; inDepends = 1; next }
              inDepends && /^[[:space:]]*$/ { inDepends = 0; next }
              inDepends && /^[[:space:]]*--/ { inDepends = 0; next }
              inDepends && /^[[:space:]]*[[:alnum:]_-]+[[:space:]]*=/ { inDepends = 0; next }
              inDepends { print; next }
              { inDepends = 0 }
            ' ${ipkg} > ${packageDir}/$(basename ${ipkg})
            ${postInstall}
            runHook postInstall
          ''
        else
          ''
            runHook preInstall
            ${installPhase}
            runHook postInstall
          '';

      passthru = passthru // {
        inherit idrisDeps packageName ipkg;
      };
    };
}
