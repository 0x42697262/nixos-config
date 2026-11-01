# Profile: shell
# Fish as the login shell, with the tide prompt.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myProfiles.shell;
in
{
  options.myProfiles.shell = {
    enable = lib.mkEnableOption "fish shell with the tide prompt";

    extras.enable = lib.mkEnableOption ''
      interactive fish extras: fastfetch greeting, eza aliases, bat as man
      pager, done/autopair plugins, !! and !$ expansion
    '';
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      users.defaultUserShell = pkgs.fish;

      programs.fish = {
        enable = true;
        shellInit = "set -g fish_greeting";
        shellAbbrs = {
          Ns = "nix-shell -p --command fish";
          Nd = "nix develop";
        };
      };

      environment.systemPackages = [ pkgs.fishPlugins.tide ];
    })

    (lib.mkIf (cfg.enable && cfg.extras.enable) {
      programs.fish.interactiveShellInit = ''
        function fish_greeting
            fastfetch
        end

        set -x MANROFFOPT "-c"
        set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
        set -U __done_min_cmd_duration 10000
        set -U __done_notification_urgency_level low

        if test -f ~/.fish_profile
            source ~/.fish_profile
        end
        fish_add_path ~/.local/bin ~/.cargo/bin

        function __history_previous_command
            switch (commandline -t)
                case "!"
                    commandline -t $history[1]; commandline -f repaint
                case "*"
                    commandline -i !
            end
        end
        function __history_previous_command_arguments
            switch (commandline -t)
                case "!"
                    commandline -t ""
                    commandline -f history-token-search-backward
                case "*"
                    commandline -i '$'
            end
        end
        if [ "$fish_key_bindings" = fish_vi_key_bindings ]
            bind -Minsert ! __history_previous_command
            bind -Minsert '$' __history_previous_command_arguments
        else
            bind ! __history_previous_command
            bind '$' __history_previous_command_arguments
        end

        function history
            builtin history --show-time='%F %T ' $argv
        end
        function backup --argument filename
            cp $filename $filename.bak
        end
      '';

      programs.fish.shellAliases = {
        ls = "eza -al --color=always --group-directories-first --icons=always";
        la = "eza -a --color=always --group-directories-first --icons=always";
        ll = "eza -l --color=always --group-directories-first --icons=always";
        lt = "eza -aT --color=always --group-directories-first --icons=always";
        "l." = "eza -a | grep -e '^\\.'";
        tarnow = "tar -acf ";
        untar = "tar -zxvf ";
        wget = "wget -c ";
        psmem = "ps auxf | sort -nr -k 4";
        psmem10 = "ps auxf | sort -nr -k 4 | head -10";
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        grep = "grep --color=auto";
        hw = "hwinfo --short";
        tb = "nc termbin.com 9999";
        jctl = "journalctl -p 3 -xb";
      };

      environment.systemPackages = with pkgs; [
        fastfetch
        eza
        bat
        hwinfo
        netcat-openbsd
        fishPlugins.done
        fishPlugins.autopair
      ];
    })
  ];
}
