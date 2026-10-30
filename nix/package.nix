{ lib
, stdenv
, src
, version
, cmake
, git
, pkg-config
, qt6
, cfitsio
, gsl
, libnova
, wcslib
, opencv
, avahi
, zlib
, indilib
, procps
  # Override with pkgs.indi-full to get the third-party INDI drivers too.
, indi ? indilib
}:

stdenv.mkDerivation {
  pname = "ostserver";
  inherit version src;

  nativeBuildInputs = [
    cmake
    git
    pkg-config
    qt6.qttools # lrelease, for the translations
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtwebsockets
    qt6.qtscxml
    cfitsio
    gsl
    libnova
    wcslib
    opencv
    avahi
    zlib
    indi
  ];

  # #!/bin/bash does not exist in the build sandbox.
  postPatch = ''
    patchShebangs generate-version.sh
  '';

  # Only the backend components: the "Complete" one installs the web UI
  # into the absolute /var/www/pilost, which cannot work in a Nix build.
  # The web UI is copied by hand instead, see the NixOS module.
  installPhase = ''
    runHook preInstall
    cmake --install . --component Runtime
    cmake --install . --component Development
    mkdir -p $out/share/ostserver
    cp -r front-www $out/share/ostserver/www
    runHook postInstall
  '';

  preFixup = ''
    qtWrapperArgs+=(
      # Modules are listed from --libpath and dlopen'ed by bare name
      # (libostfocus.so, ...); the default lookup dirs are /usr/lib*.
      --add-flags "--libpath=$out/lib"
      --prefix LD_LIBRARY_PATH : "$out/lib"
      # indiserver, indi_getprop/indi_setprop and pgrep are spawned at runtime.
      --prefix PATH : "${lib.makeBinPath [ indi procps ]}"
      --set-default OST_INDI_DRIVERS_DIR "${indi}/share/indi"
    )
  '';

  meta = {
    description = "Observatoire Sans Tête - light and headless astrophotography automation tool";
    homepage = "https://gitlab.ostserver.fr/ost/ostserver";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "ostserver";
  };
}
