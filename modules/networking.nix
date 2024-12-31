{
  config,
  lib,
  ...
}: let
  cfg = config.ryo-network;
in {
  options.ryo-network = {
    home.enable = lib.mkEnableOption "home wireless";
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.home.enable == false) {
      networking.networkmanager.enable = true;
    })
    (lib.mkIf (cfg.home.enable) {
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
  ];
}
