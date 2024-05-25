{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./grafana.nix
    ./forge.nix
  ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";

  networking.hostName = "outpost-2";

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

  services.searx.enable = true;
  services.searx.settings.server.port = 9090;

  services.caddy = {
    enable = true;
    virtualHosts."search.althaea.zone".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString config.services.searx.settings.server.port}
    '';
  };

  system.stateVersion = "24.05";
}
