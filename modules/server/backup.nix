{
  config,
  lib,
  pkgs,
  name,
  ...
}:
let
  cfg = config.server.backups;

  repository = "s3:https://s3.us-east-005.backblazeb2.com/restic-001";
  passwordFile = config.deployment.keys."restic.password".path;
  pruneOpts = [
    "--keep-daily 7"
    "--keep-weekly 4"
    "--keep-monthly 12"
    "--keep-yearly 75"
  ];
  environmentFile = config.deployment.keys."restic.env".path;
in
{
  options.server.backups = {
    enable = lib.mkEnableOption "restic backups for this node";

    paths = lib.mkOption {
      default = [ ];
      type = lib.types.listOf lib.types.str;
    };

    exclude = lib.mkOption {
      default = [ ];
      type = lib.types.listOf lib.types.str;
    };

    postgres-dbs = lib.mkOption {
      default = [ ];
      type = lib.types.listOf lib.types.str;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.restic.backups.${name} = {
        inherit (cfg) paths exclude;
        inherit
          passwordFile
          repository
          pruneOpts
          environmentFile
          ;
      };

      deployment.keys."restic.password" = {
        keyCommand = [
          "gpg"
          "--decrypt"
          "${../../secrets/restic.password.gpg}"
        ];

        destDir = "/etc/keys";
        uploadAt = "pre-activation";

        inherit (config.services.restic.backups.${name}) user;
      };

      deployment.keys."restic.env" = {
        keyCommand = [
          "gpg"
          "--decrypt"
          "${../../secrets/restic.env.gpg}"
        ];

        destDir = "/etc/keys";
        uploadAt = "pre-activation";

        inherit (config.services.restic.backups.${name}) user;
      };
    })
    (lib.mkIf
      (cfg.enable && config.services.postgresql.enable && (builtins.length cfg.postgres-dbs > 0))
      {
        services.restic.backups."${name}-postgres" =
          let
            getPath = name: "/tmp/restic-dump-postgres/${name}";
            pg_dump = lib.getExe' config.services.postgresql.package "pg_dump";
          in
          {
            inherit
              passwordFile
              repository
              pruneOpts
              environmentFile
              ;
            backupPrepareCommand = lib.concatMapStringsSep "\n" (name: ''
              ${lib.getExe pkgs.sudo} -u postgres mkdir -p ${getPath name}
              ${lib.getExe pkgs.sudo} -u postgres ${pg_dump} -Fd ${name} -f ${getPath name}
            '') cfg.postgres-dbs;
            backupCleanupCommand = lib.concatMapStringsSep "\n" (name: ''
              rm -rf ${getPath name}
            '') cfg.postgres-dbs;
            paths = builtins.map getPath cfg.postgres-dbs;
          };
      }
    )
  ];
}
