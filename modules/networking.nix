{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  cfg = config.ryo-network;
in {
  options.ryo-network = {
    home.enable = lib.mkEnableOption "home wireless";
    det.enable = lib.mkEnableOption "det wireless";
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.home.enable == false && cfg.det.enable == false) {
      networking.networkmanager.enable = true;
    })
    (lib.mkIf (cfg.home.enable || cfg.det.enable) {
      networking.wireless.enable = true;
      networking.wireless.secretsFile = config.deployment.keys."wireless.env".path;

      deployment.keys."wireless.env" = {
        keyCommand = ["gpg" "--decrypt" "${../secrets/wireless.env.gpg}"];
        uploadAt = "pre-activation";
        destDir = "/etc/keys";
      };
    })
    (lib.mkIf cfg.home.enable {
      networking.wireless.networks."the internet" = {
        pskRaw = "ext:HOME_PSK";
        priority = 100;
      };
    })
    (lib.mkIf cfg.det.enable {
      networking.wireless.networks."detnsw-a" = {
        auth = ''
          key_mgmt=WPA-EAP
          eap=PEAP
          phase2="auth=MSCHAPV2"
          identity="ext:DETNSW_IDENT"
          password=ext:DETNSW_PASSWORD
        '';
      };
    })
  ];
}
