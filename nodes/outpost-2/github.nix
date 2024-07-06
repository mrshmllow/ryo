{pkgs, ...}: {
  deployment.keys."outpost-2-ryo-runner.token" = {
    keyCommand = ["gpg" "--decrypt" "secrets/outpost-2-ryo-runner.token.gpg"];
    destDir = "/etc/gh-runner-keys";
    uploadAt = "pre-activation";
  };

  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-+"];
    externalInterface = "ens3";
    enableIPv6 = true;
  };

  containers.gh-runner = {
    autoStart = true;
    # ephemeral = true;
    privateNetwork = true;
    hostAddress = "10.231.136.1";
    localAddress = "10.231.136.2";
    hostAddress6 = "fc00::1";
    localAddress6 = "fc00::2";
    bindMounts."/etc/gh-runner-keys".mountPoint = "/etc/gh-runner-keys";
    config = {
      lib,
      pkgs,
      ...
    }: {
      system.stateVersion = "24.11";

      virtualisation.docker.enable = true;

      users.groups.gh-runner = {};

      users.users.gh-runner = {
        isSystemUser = true;
        group = "gh-runner";
        extraGroups = ["docker"];
      };

      networking = {
        firewall.enable = true;
        useHostResolvConf = lib.mkForce false;
      };

      services.resolved.enable = lib.mkForce true;

      boot.binfmt.emulatedSystems = ["aarch64-linux"];

      nix.settings = {
        experimental-features = ["nix-command" "flakes"];
        auto-optimise-store = true;
        trusted-users = ["gh-runner"];
        substituters = [
          "https://cache.nixos.org/"
          "https://ryo.cachix.org"
        ];
        trusted-public-keys = [
          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
          "ryo.cachix.org-1:f/pZAkaRjfBYsTX3myaeIdPpxV6rSMcG3m1ofszjjAw="
        ];
      };

      services.github-runners = {
        outpost-2-ryo = {
          enable = true;
          name = "outpost-2-ryo";
          url = "https://github.com/mrshmllow/ryo_two";
          tokenFile = "/etc/gh-runner-keys/outpost-2-ryo-runner.token";
          extraPackages = with pkgs; [docker cachix];

          user = "gh-runner";
          group = "gh-runner";
        };
      };
    };
  };
}
