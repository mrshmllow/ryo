{...}: {
  imports = [
    ./hardware-configuration.nix
    ./services
  ];

  networking.firewall.allowedTCPPorts = [80 443];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = "outpost-3";
  networking.domain = "althaea.zone";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsrE2dWjrj+nBTYrrfpVIaW6wxs3ClSDW3iKffD73p+ marsh@marsh-framework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGFCPRaZzp7mPqlyJo6c5VW/hBHlzHwo2oyrZhdNxmdY marsh@marsh-wsl"
  ];
  system.stateVersion = "23.11";
}
