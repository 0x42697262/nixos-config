# gitlab-runner -- NixOS system container (Incus/LXD) on the local workstation.
#
# Runs a GitLab Runner with the *shell* executor. CI jobs run directly on this
# container and wrap their build steps in `nix develop`, so the toolchain comes
# from each project's own flake (fully reproducible) instead of a Docker image.
# That means no Docker/nesting is needed for Nix-flake projects like akon-money.
#
# Launch (nesting only matters if you later add a docker-executor / Android job):
#   incus launch images:nixos/unstable gitlab-runner -c security.nesting=true
{ modulesPath, ... }: {
  imports = [
    # Makes NixOS behave as an unprivileged LXC/Incus system container:
    # no bootloader/kernel management, container-appropriate defaults.
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  networking.hostName = "gitlab-runner";

  # zram can't load its kernel module inside an unprivileged container.
  myProfiles.zram.enable = false;
  myProfiles.server.enable = true;

  # The runner clones repos over git; the build toolchain itself comes from
  # `nix develop`, so nothing else needs installing globally.
  programs.git.enable = true;

  services.gitlab-runner = {
    enable = true;
    services.default = {
      # Runner *authentication* token (the new GitLab >= 17 workflow). Env file
      # (NOT in git) with the server URL and glrt- token, e.g.:
      #   CI_SERVER_URL=https://seggs.wineff.net
      #   CI_SERVER_TOKEN=glrt-xxxxxxxxxxxxxxxxxxxx
      # Create a runner in GitLab (Admin/Group/Project -> CI/CD -> Runners ->
      # New runner) to get the glrt- token, then write this file on the box.
      authenticationTokenConfigFile = "/etc/nixos/gitlab-runner.env";

      executor = "shell";
    };
  };

  # First-install release. Confirm with `nixos-version` in the container and
  # keep it pinned to that value afterwards.
  system.stateVersion = "25.11";
}
