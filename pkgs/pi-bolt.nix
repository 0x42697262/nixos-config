{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  libxcb,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "pi-bolt";
  version = "1.3.1";

  src = fetchurl {
    url = "https://github.com/opensec-git/Pi-Bolt/releases/download/bolt-v${finalAttrs.version}/pi-bolt-linux-x64.tar.gz";
    hash = "sha256-IWIe8BF0j81DjGqMaPbs7uIfsQWIvj0hUi31LYgQzN0=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [ libxcb ];

  dontStrip = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/pi-bolt $out/bin
    cp -r . $out/lib/pi-bolt

    makeWrapper $out/lib/pi-bolt/pi-start $out/bin/pi-bolt \
      --set-default PI_TELEMETRY 0

    runHook postInstall
  '';

  meta = {
    description = "Pi coding agent compiled ahead of time to a native executable";
    homepage = "https://github.com/opensec-git/Pi-Bolt";
    license = lib.licenses.mit;
    mainProgram = "pi-bolt";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
