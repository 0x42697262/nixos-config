{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  wayland-scanner,
  wayland,
  wayland-protocols,
  libGL,
  libglvnd,
  freetype,
  fontconfig,
  cairo,
  pango,
  harfbuzz,
  libxkbcommon,
  sdbus-cpp_2,
  systemd,
  pipewire,
  pam,
  curl,
  libwebp,
  libjxl,
  libsndfile,
  glib,
  polkit,
  librsvg,
  libqalculate,
  libxml2,
  md4c,
  libsecret,
  libsodium,
  stb,
  nlohmann_json,
  tomlplusplus,
  libical,
  wireplumber,
  jemalloc,
  makeWrapper,
  git,
  gsettings-desktop-schemas,
  autoAddDriverRunpath,
}:
let
  stb' = stb.overrideAttrs (_: {
    version = "unstable-2025-10-26";
    src = fetchFromGitHub {
      owner = "nothings";
      repo = "stb";
      rev = "f1c79c02822848a9bed4315b12c8c8f3761e1296";
      hash = "sha256-BlyXJtAI7WqXCTT3ylww8zoG0hBxaojJnQDvdQOXJPE=";
    };
  });
in
stdenv.mkDerivation (finalAttrs: {
  pname = "noctalia";
  version = "5.2.1";

  src = fetchFromGitHub {
    owner = "noctalia-dev";
    repo = "noctalia";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ukT5U54WQSpq6sktl5QJOZ8S4ZF3LLmP8CAFel1XJf0=";
  };

  postPatch = ''
    substituteInPlace meson.build \
      --replace-fail "_git_revision_config.set('VCS_TAG', 'unknown')" "_git_revision_config.set('VCS_TAG', 'v${finalAttrs.version}')"
  '';

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    wayland-scanner
    jemalloc
    makeWrapper
    autoAddDriverRunpath
  ];

  buildInputs = [
    wayland
    wayland-protocols
    libGL
    libglvnd
    freetype
    fontconfig
    cairo
    pango
    harfbuzz
    libxkbcommon
    sdbus-cpp_2
    systemd
    pipewire
    wireplumber
    pam
    curl
    libwebp
    libjxl
    libsndfile
    glib
    polkit
    librsvg
    libqalculate
    libxml2
    md4c
    libsecret
    libsodium
    stb'
    nlohmann_json
    tomlplusplus
    libical
  ];

  mesonBuildType = "release";
  mesonFlags = [ "-Dtests=disabled" ];

  postFixup = ''
    wrapProgram $out/bin/noctalia \
      --prefix PATH : ${lib.makeBinPath [ git ]} \
      --prefix XDG_DATA_DIRS : "${glib.getSchemaDataDirPath gsettings-desktop-schemas}"
  '';

  meta = {
    description = "Desktop shell for Wayland compositors";
    homepage = "https://github.com/noctalia-dev/noctalia";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "noctalia";
  };
})
