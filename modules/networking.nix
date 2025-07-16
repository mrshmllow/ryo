{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ryo-network;
in
{
  options.ryo-network = {
    home.enable = lib.mkEnableOption "home wireless";
    tailscale.enable = lib.mkEnableOption "tailscale";
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.tailscale.enable) {
      services.tailscale = {
        enable = true;
        # authKeyFile = config.deployment.keys."tailscale.key".path;
        permitCertUid = "caddy";
        extraUpFlags = [ "--ssh" ];
      };

      deployment.keys."tailscale.key" = {
        keyCommand = [
          "gpg"
          "--decrypt"
          "${../secrets/tailscale.key.gpg}"
        ];

        uploadAt = "pre-activation";
      };
    })
    (lib.mkIf (config.desktop.gnome.enable && cfg.tailscale.enable) {
      environment.systemPackages = [
        pkgs.gnomeExtensions.tailscale-qs
      ];
    })
    (lib.mkIf (cfg.home.enable == false) {
      networking.networkmanager.enable = true;
    })
    (lib.mkIf (cfg.home.enable) {
      networking.wireless.enable = true;
      networking.wireless.secretsFile = config.deployment.keys."wireless.env".path;

      deployment.keys."wireless.env" = {
        keyCommand = [
          "gpg"
          "--decrypt"
          "${../secrets/wireless.env.gpg}"
        ];
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
