{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./grafana.nix
    ./github.nix
    # ./forge.nix
  ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";

  networking.hostName = "outpost-2";

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
    substituters = [
      "https://cache.nixos.org/"
      "https://cache.garnix.io"
      "https://ryo.cachix.org"
    ];
    trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "ryo.cachix.org-1:f/pZAkaRjfBYsTX3myaeIdPpxV6rSMcG3m1ofszjjAw="
    ];
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGFCPRaZzp7mPqlyJo6c5VW/hBHlzHwo2oyrZhdNxmdY marsh@marsh-wsl"
  ];
  services.openssh.settings.PasswordAuthentication = false;

  services.fail2ban.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  system.stateVersion = "24.05";
}
