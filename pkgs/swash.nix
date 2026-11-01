{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  wrapGAppsHook4,
  gtk4,
  libadwaita,
  tesseract,
  wl-clipboard,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "swash";
  version = "1.5.1";

  src = fetchFromGitHub {
    owner = "ItsLemmy";
    repo = "swash";
    tag = "v${finalAttrs.version}";
    hash = "sha256-SxdrsKUIDLUfWQp7Wa50NwFo36h3LzMd6SOBIy14KAA=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    gtk4
    libadwaita
  ];

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : "${
        lib.makeBinPath [
          tesseract
          wl-clipboard
        ]
      }"
    )
  '';

  meta = {
    description = "Screenshot annotator and lightweight image editor";
    homepage = "https://github.com/ItsLemmy/swash";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "swash";
  };
})
