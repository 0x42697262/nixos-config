# gitlab-runner -- NixOS system container (Incus/LXD) on the local workstation.
# Runs a GitLab Runner with the Docker executor. The container must be launched
# with nesting enabled so Docker can run inside it:
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

  # The Docker executor runs each CI job in its own container, so this needs a
  # working Docker daemon -- which is why the Incus container needs nesting.
  virtualisation.docker.enable = true;

  services.gitlab-runner = {
    enable = true;
    services.default = {
      # Env file (NOT in git) with the server URL and runner token, e.g.:
      #   CI_SERVER_URL=https://seggs.wineff.net
      #   CI_SERVER_TOKEN=glrt-xxxxxxxxxxxxxxxxxxxx
      # Create a runner in GitLab (Admin/Group/Project -> CI/CD -> Runners ->
      # New runner) to get the glrt- token, then write this file on the box.
      registrationConfigFile = "/etc/nixos/gitlab-runner.env";

      executor = "docker";
      dockerImage = "alpine:latest";
      # Also pick up jobs that carry no tags.
      runUntagged = true;
    };
  };

  # First-install release. Confirm with `nixos-version` in the container and
  # keep it pinned to that value afterwards.
  system.stateVersion = "25.11";
}
