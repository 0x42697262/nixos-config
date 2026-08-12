# Profile: security
# Offensive security tooling, split by discipline. `enable` on its own gives the
# shared basics (recon, scripting, an exploit database); each discipline flag
# adds its own set on top and implies `enable`, so a host only needs to name the
# disciplines it wants.
#
# Graphical tools sit behind `gui.enable` instead of their discipline, because a
# headless container (see ../roles/incus.nix) can use everything else but has
# nowhere to draw Burp, ZAP, or Ghidra.
{ config, lib, pkgs, ... }:
let
  cfg = config.myProfiles.security;

  anyDiscipline = cfg.web.enable
    || cfg.reversing.enable
    || cfg.binexp.enable
    || cfg.forensics.enable
    || cfg.crypto.enable;

  # One interpreter for all disciplines. Separate withPackages environments
  # would each put a `python3` on PATH and shadow one another.
  pythonEnv = pkgs.python3.withPackages (ps:
    with ps;
    [ requests ]
    ++ lib.optionals cfg.web.enable [ beautifulsoup4 pyjwt ]
    ++ lib.optionals cfg.binexp.enable [ pwntools ]
    ++ lib.optionals cfg.crypto.enable [ pycryptodome gmpy2 sympy ]);
in
{
  options.myProfiles.security = {
    enable = lib.mkEnableOption
      "shared security tooling (recon, scripting, exploit database)";

    web.enable = lib.mkEnableOption
      "web application pentesting -- proxies, fuzzers, scanners (Juice Shop)";

    reversing.enable = lib.mkEnableOption
      "reverse engineering -- disassemblers and debuggers";

    binexp.enable = lib.mkEnableOption
      "binary exploitation -- pwntools and ROP tooling";

    forensics.enable = lib.mkEnableOption
      "forensics -- carving, memory and packet analysis, steganography";

    crypto.enable = lib.mkEnableOption
      "cryptography and password cracking";

    gui.enable = lib.mkEnableOption
      "graphical security tools -- needs a desktop or X forwarding";
  };

  config = lib.mkMerge [
    # Naming a discipline is enough; the host does not also have to set `enable`.
    (lib.mkIf anyDiscipline { myProfiles.security.enable = true; })

    (lib.mkIf cfg.enable {
      environment.systemPackages = [ pythonEnv ] ++ (with pkgs; [
        # Recon and the network basics every discipline reaches for.
        nmap
        dnsutils
        whois
        openssl
        socat
        netcat-gnu

        # Poking at services and reading what comes back.
        curl
        httpie
        jq
        file

        # searchsploit
        exploitdb
      ]);
    })

    (lib.mkIf cfg.web.enable {
      environment.systemPackages = with pkgs; [
        # Interception proxy that works in a terminal, unlike Burp and ZAP.
        mitmproxy

        # Content discovery and fuzzing.
        ffuf
        feroxbuster
        gobuster

        # Scanners.
        sqlmap
        nikto
        nuclei
        whatweb
        wpscan

        # Recon against a target's surface.
        httpx
        subfinder

        # Juice Shop leans on JWTs, and its challenges expect a JS runtime.
        jwt-cli
        nodejs
      ];
    })

    (lib.mkIf cfg.reversing.enable {
      environment.systemPackages = with pkgs; [
        radare2
        rizin
        gdb
        gef # gdb frontend for exploit devs; nixpkgs has no pwndbg
        binutils # objdump, readelf, strings, nm
        patchelf
        upx
        ltrace
        strace
      ];
    })

    (lib.mkIf cfg.binexp.enable {
      # pwntools rides along in pythonEnv above.
      environment.systemPackages = with pkgs; [
        gdb
        gef # gdb frontend for exploit devs; nixpkgs has no pwndbg
        ropgadget
        one_gadget
        pwninit
        checksec
        elfutils
      ];
    })

    (lib.mkIf cfg.forensics.enable {
      environment.systemPackages = with pkgs; [
        # Carving and disk work.
        binwalk
        foremost
        testdisk
        sleuthkit

        # Memory and packets.
        volatility3
        tcpdump
        wireshark-cli # tshark

        # Metadata and steganography.
        exiftool
        steghide
        stegseek
        zsteg
        outguess

        hexedit
      ];
    })

    (lib.mkIf cfg.crypto.enable {
      # pycryptodome, gmpy2, and sympy ride along in pythonEnv above.
      environment.systemPackages = with pkgs; [
        hashcat
        john
        hash-identifier
        # RsaCtfTool is not in nixpkgs; gmpy2 + sympy above cover the same
        # ground for the usual RSA challenges.
      ];
    })

    # Graphical tools, gated on the discipline they belong to.
    (lib.mkIf (cfg.gui.enable && cfg.web.enable) {
      environment.systemPackages = with pkgs; [
        burpsuite
        zap
      ];
    })

    (lib.mkIf (cfg.gui.enable && cfg.reversing.enable) {
      environment.systemPackages = with pkgs; [
        ghidra
        cutter
      ];
    })

    (lib.mkIf (cfg.gui.enable && cfg.forensics.enable) {
      # Adds the wireshark group; members may capture without root.
      programs.wireshark.enable = true;
      environment.systemPackages = with pkgs; [ imhex ];
    })
  ];
}
