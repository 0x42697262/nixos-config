{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "kde-win11";
  version = "1.0.0-unstable-2026-11-05";

  src = fetchFromGitHub {
    owner = "0x42697262";
    repo = "kde-win11";
    rev = "b6ae1b964ed38c12f049e70e8546cfe27c1a7f1b";
    hash = "sha256-re0xuGQJCIcvCUOFvCcq8Uipzm+Kmkf5QlwofKcw58w=";
  };

  dontBuild = true;

  postPatch = ''
    for f in packages/plasma/look-and-feel/*/contents/layouts/org.kde.plasma.desktop-layout.js; do
      substituteInPlace "$f" --replace-fail \
        '"file://" + userDataPath() + "/.local/share/" + settings.wallpaperPackage + "/"' \
        '"file:///run/current-system/sw/share/" + settings.wallpaperPackage + "/"'
    done
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share
    cp -r packages/{plasma,aurorae,color-schemes,icons,konsole,wallpapers,sddm,Kvantum} $out/share/
    runHook postInstall
  '';

  meta = {
    description = "Windows 11 style theme for KDE Plasma 6";
    homepage = "https://github.com/0x42697262/kde-win11";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
