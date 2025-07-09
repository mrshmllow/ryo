{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./services
  ];

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = "outpost-3";
  networking.domain = "althaea.zone";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEf5PCchOeMbngf8Ta+4qErlwGcColab/aw+vOx7ZZu+ marsh@althaea"
  ];

  system.stateVersion = "23.11";
}
