{ config, ... }:
{
  services.deluge = {
    enable = true;
    web = {
      enable = true;
      openFirewall = true;
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

  services.openvpn.servers = {
    vpn = {
      config = ''config ${config.deployment.keys."media.udp.ovpn".path} '';
      updateResolvConf = true;
      authUserPass = config.deployment.keys."media.udp.ovpn.pass".path;
    };
  };
}
