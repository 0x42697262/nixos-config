{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "cachyos-emerald-kde";
  version = "0-unstable-2026-10-10";

  src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "CachyOS-Emerald-KDE";
    rev = "f0fa3b9dbe5cb0e8146e395ebac8fc4c9100da39";
    hash = "sha256-FyrKDNV5eHUvtYGuHqMeyFbcm8ZexbCn0Nu25EjUZxM=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/color-schemes $out/share/plasma
    cp -r color-schemes/* $out/share/color-schemes/
    cp -r plasma/desktoptheme plasma/look-and-feel $out/share/plasma/
    runHook postInstall
  '';

  meta = {
    description = "CachyOS Emerald theme for KDE Plasma";
    homepage = "https://github.com/CachyOS/CachyOS-Emerald-KDE";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.all;
  };
}
