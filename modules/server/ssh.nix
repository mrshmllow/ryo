{ config, lib, ... }:
let
  cfg = config.server.caddy;
  tailscaleRange = "100.64.0.0/10";
in
{
  options.server.openssh = {
    enable = lib.mkEnableOption "openssh config";
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
      settings.PermitRootLogin = "no";
      extraConfig = ''
        Match Address ${tailscaleRange}
            PermitRootLogin yes
      '';
    };
  };
}
