{
  pkgs,
  inputs,
  config,
  ...
}: let
  dataDir = "/var/lib/typst-bot";
in {
  virtualisation.oci-containers.containers.actual = {
    enable = false;

    image = pkgs.dockerTools.buildImage {
      name = "hello-docker";
      fromImage = inputs.typst-bot;
    };
    volumes = [
      "${dataDir}:/bot/sqlite"
      "${dataDir}:/bot/cache"
    ];
    user = "${toString config.users.users.typstbot.uid}:${toString config.users.groups.typstbot.gid}";
    environmentFiles = [
      config.deployment.keys."typstbot.env".path
    ];
  };

  deployment.keys."typstbot.env" = {
    keyCommand = [
      "gpg"
      "--decrypt"
      "${../secrets/typstbot.key.gpg}"
    ];

    destDir = "/etc/keys";
    uploadAt = "pre-activation";
  };

  users = {
    users.typstbot = {
      isSystemUser = true;
      group = "typstbot";
    };

    groups.typstbot = {};
  };

  systemd = {
    tmpfiles.rules = [
      "d ${dataDir} 0700 typstbot typstbot - -"
    ];
  };
}
