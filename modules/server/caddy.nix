{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.server.caddy;
in
{
  options.server.caddy = {
    enable = lib.mkEnableOption "caddy";
  };

  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;
      email = "acme.amnesty785@passmail.com";
      environmentFile = config.deployment.keys."builtin.caddy.env".path;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.2.1" ];
        hash = "sha256-2D7dnG50CwtCho+U+iHmSj2w14zllQXPjmTHr6lJZ/A=";
      };
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    deployment.keys."builtin.caddy.env" = {
      keyCommand = [
        "gpg"
        "--decrypt"
        "${../../secrets/media.caddy.env.gpg}"
      ];

      destDir = "/etc/keys";
      uploadAt = "pre-activation";

      inherit (config.services.caddy) user group;
    };
  };
}
