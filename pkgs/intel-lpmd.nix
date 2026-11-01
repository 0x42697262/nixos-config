{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  pkg-config,
  gtk-doc,
  glib,
  libxml2,
  libnl,
  systemd,
  upower,
}:
stdenv.mkDerivation {
  pname = "intel-lpmd";
  version = "0.1.1-unstable-2026-04-05";

  src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "intel-lpmd";
    rev = "0a3c9e8abac42453a84fd806bbd72bc2faf77d23";
    hash = "sha256-xHuP5pl1Krsx5Ac/60ukejK/RoRGx7QN46wyZ1S1iNc=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    gtk-doc
    glib
  ];

  buildInputs = [
    glib
    libxml2
    libnl
    systemd
    upower
  ];

  configureFlags = [
    "--sysconfdir=${placeholder "out"}/etc"
    "--localstatedir=/var"
    "--with-dbus-sys-dir=${placeholder "out"}/share/dbus-1/system.d"
    "--with-systemdsystemunitdir=${placeholder "out"}/lib/systemd/system"
    "--disable-werror"
  ];

  preAutoreconf = ''
    touch ChangeLog NEWS AUTHORS README
  '';

  meta = {
    description = "Intel Low Power Mode Daemon";
    homepage = "https://github.com/CachyOS/intel-lpmd";
    license = lib.licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "intel_lpmd";
  };
}
