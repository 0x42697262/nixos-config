{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "cachyos-hypr-noctalia";
  version = "1.2.6";

  src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "cachyos-hypr-noctalia";
    tag = finalAttrs.version;
    hash = "sha256-X0SI3ywRcvHXjQxCuf7/5L4wG/zxAaaI89/9kZGF0a4=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/cachyos-hypr-noctalia
    cp -r etc/skel $out/share/cachyos-hypr-noctalia/skel
    runHook postInstall
  '';

  meta = {
    description = "CachyOS Hyprland and Noctalia dotfiles";
    homepage = "https://github.com/CachyOS/cachyos-hypr-noctalia";
    license = lib.licenses.gpl1Only;
    platforms = lib.platforms.all;
  };
})
