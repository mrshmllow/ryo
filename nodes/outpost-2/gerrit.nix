{
  config,
  lib,
  pkgs,
  ...
}: {
  services.gerrit = {
    enable = true;
    # Magic number
    serverId = "65be6090-4b62-4db6-9d66-ab15f82633f7";
  };

  services.caddy = {
    enable = true;
    virtualHosts."gerrit.althaea.zone".extraConfig = ''
      reverse_proxy http://${config.services.gerrit.listenAddress}
    '';
  };
}
