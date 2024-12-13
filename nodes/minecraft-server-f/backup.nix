{config, ...}: {
  deployment.keys."minecraft-b2.pass.gpg" = {
    keyCommand = ["gpg" "--decrypt" "${./b2.pass.gpg}"];

    uploadAt = "pre-activation";
    destDir = "/etc/keys";
  };

  deployment.keys."minecraft-b2.env.gpg" = {
    keyCommand = ["gpg" "--decrypt" "${./b2.env.gpg}"];

    uploadAt = "pre-activation";
    destDir = "/etc/keys";
  };

  services.restic.backups = {
    minecraft = {
      initialize = true;
      passwordFile = config.deployment.keys."minecraft-b2.pass.gpg".path;
      environmentFile = config.deployment.keys."minecraft-b2.env.gpg".path;
      paths = [
        config.services.minecraft-servers.dataDir
      ];
      repository = "s3:s3.us-east-005.backblazeb2.com/restic-001";
      timerConfig = {
        OnCalendar = "daily";
        RandomizedDelaySec = "5h";
      };
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 3"
      ];
    };
  };
}
