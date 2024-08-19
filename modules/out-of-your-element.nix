{
  config,
  pkgs,
  lib,
  ...
}: let
  out-of-your-element = pkgs.callPackage ./out-of-your-element.package.nix {};
  cfg = config.services.out-of-your-element;
  defaultUser = "out-of-your-element";
in {
  options.services.out-of-your-element = {
    enable = lib.mkEnableOption "out-of-your-element";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/out-of-your-element";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = defaultUser;
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = defaultUser;
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
      users = lib.optionalAttrs (cfg.user == defaultUser) {
        ${cfg.user} = {
          isSystemUser = true;
          group = cfg.group;
        };
      };

      groups = lib.optionalAttrs (cfg.group == defaultUser) {
        ${cfg.group} = {};
      };
    };

    systemd = {
      tmpfiles.rules = [
        "Z ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} - -"
        "d ${cfg.dataDir}/db 0750 ${cfg.user} ${cfg.group} - -"
        "d ${cfg.dataDir}/node_modules 0750 ${cfg.user} ${cfg.group} - -"

        "L ${cfg.dataDir}/config.js - - - - ${cfg.configFile}"
        "L ${cfg.dataDir}/registration.yaml - - - - ${cfg.registrationFile}"
      ];

      services.out-of-your-element = {
        enable = true;
        path = [pkgs.vips];
        wantedBy = ["multi-user.target"];
        script = "${lib.getExe pkgs.nodejs_20} start.js";
        preStart = ''
          # feels unsafe but should be fine hopefully xd
          cp -R ${out-of-your-element}/* .

          ${lib.getExe pkgs.nodejs_20} scripts/seed.js
        '';

        serviceConfig = {
          WorkingDirectory = cfg.dataDir;
          Group = cfg.group;
          User = cfg.user;
        };
      };
    };
  };
}
