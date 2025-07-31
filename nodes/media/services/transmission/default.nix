{ config, pkgs, ... }:
{
  services = {
    qbittorrent = {
      enable = true;
      openFirewall = true;
      webuiPort = 8081;
      serverConfig = {
        Preferences = {
          WebUI = {
            RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
            Password_PBKDF2 = "Z/bIFekWWbZbyG/sBEIPVA==:2XkBQz8C36N7nrLiX8coUJOV914lIHCLOkliN3B7/f2xbNlHS46ZW7FYQm2Yv1mygIqH5z1UE2WbBAQoRWcxmw==";
            AlternativeUIEnabled = true;
          };
          # 23:00
          Scheduler.end_time = "\0\0\0\xf\x4\xefm\x80";
        };
        BitTorrent.Session =
          let
            unlimited = -1;
          in
          {
            AlternativeGlobalDLSpeedLimit = 1000;
            AlternativeGlobalUPSpeedLimit = 1000;
            UseAlternativeGlobalSpeedLimit = true;

            BandwidthSchedulerEnabled = true;

            AnonymousModeEnabled = true;

            Preallocation = true;
            TempPathEnabled = true;

            DefaultSavePath = "/storage/data/torrents/";
            TempPath = "/storage/data/incomplete/";

            UseCategoryPathsInManualMode = true;

            GlobalMaxSeedingMinutes = 8 * 1440;
            GlobalMaxRatio = 1;

            MaxActiveDownloads = unlimited;
            MaxActiveTorrents = unlimited;
            MaxActiveUploads = unlimited;
            MaxConnections = unlimited;
            MaxConnectionsPerTorrent = unlimited;
            MaxUploads = unlimited;
            MaxUploadsPerTorrent = unlimited;
          };
      };
    };

    openvpn.servers = {
      vpn = {
        config = ''config ${config.deployment.keys."media.udp.ovpn".path} '';
        updateResolvConf = true;
        authUserPass = config.deployment.keys."media.udp.ovpn.pass".path;
      };
    };
  };

  media.subdomains."qbittorrent".port = config.services.qbittorrent.webuiPort;

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
