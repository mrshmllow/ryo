{ config, ... }:
{
  services =
    let
      domain = "qbittorrent.local";
    in
    {
      # TODO: Remove
      deluge = {
        enable = true;
        web = {
          enable = true;
          openFirewall = true;
        };
      };

      qbittorrent = {
        enable = true;
        openFirewall = true;
      };

      openvpn.servers = {
        vpn = {
          config = ''config ${config.deployment.keys."media.udp.ovpn".path} '';
          updateResolvConf = true;
          authUserPass = config.deployment.keys."media.udp.ovpn.pass".path;
        };
      };

      caddy.virtualHosts.${domain}.extraConfig = ''
        reverse_proxy :${toString config.services.qbittorrent.webuiPort}
        tls internal
      '';

      blocky.settings.customDNS.mapping = {
        ${domain} = "10.1.1.117";
      };
    };

  boot.kernelModules = [ "wireguard" ];

  deployment.keys."media.udp.ovpn" = {
    keyCommand = [
      "gpg"
      "--decrypt"
      "${../../../../secrets/media.udp.ovpn.gpg}"
    ];

    destDir = "/etc/keys";
    uploadAt = "pre-activation";
  };

  deployment.keys."media.udp.ovpn.pass" = {
    keyCommand = [
      "gpg"
      "--decrypt"
      "${../../../../secrets/media.udp.ovpn.pass.gpg}"
    ];

    destDir = "/etc/keys";
    uploadAt = "pre-activation";
  };
}
