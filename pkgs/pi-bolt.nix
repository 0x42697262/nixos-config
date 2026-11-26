# Pi-Bolt: the Pi coding agent compiled ahead of time to one executable.
# Repackages the signed upstream release; the hash is that of
# pi-bolt-linux-x64.tar.gz in the release's SHA256SUMS, whose signature
# verifies against keys/release.pub.
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

  # native/linux/prebuilds/linux-x64/linux-platform-x11.node (clipboard).
  buildInputs = [ libxcb ];

  # pi is a Bun executable whose program lives in the .bun ELF section;
  # stripping would drop it. Setting the interpreter (autoPatchelf) is fine.
  dontStrip = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/pi-bolt $out/bin
    cp -r . $out/lib/pi-bolt

    # pi-start (static) preloads pi and execs the sibling pi binary, which
    # finds its themes and assets next to itself. Install ping off unless
    # the user sets PI_TELEMETRY.
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
