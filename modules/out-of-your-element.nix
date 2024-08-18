{
  config,
  pkgs,
  lib,
  ...
}: let
  out-of-your-element = pkgs.callPackage ./out-of-your-element.package.nix {};
  cfg = config.services.out-of-your-element;
in {
  options.services.out-of-your-element = {
    enable = lib.mkEnableOption "out-of-your-element";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/out-of-your-element";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "out-of-your-element";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "out-of-your-element";
    };

    configFile = lib.mkOption {
      type = lib.types.path;
      default = null;
    };

    registrationFile = lib.mkOption {
      type = lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      groups.${cfg.group} = {};
      users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
      };
    };

    systemd.tmpfiles.rules = [
      "C+ ${cfg.dataDir} - - - - ${out-of-your-element}/lib/node_modules/out-of-your-element"
      "Z ${cfg.dataDir} 0750 out-of-your-element out-of-your-element - -"
      "d ${cfg.dataDir}/db 0750 out-of-your-element out-of-your-element - -"
      "d ${cfg.dataDir}/node_modules 0750 out-of-your-element out-of-your-element - -"

      "L ${cfg.dataDir}/config.js - - - - ${cfg.configFile}"
      "L ${cfg.dataDir}/registration.yaml - - - - ${cfg.registrationFile}"
    ];

    systemd.services.out-of-your-element = {
      enable = true;
      path = [pkgs.vips];
      wantedBy = ["multi-user.target"];
      script = "${lib.getExe pkgs.nodejs_20} start.js";
      preStart = "${lib.getExe pkgs.nodejs_20} scripts/seed.js";

      serviceConfig = {
        WorkingDirectory = cfg.dataDir;
        Group = cfg.group;
        User = cfg.user;
      };
    };
  };
}
