{
  pkgs,
  config,
  lib,
  ...
}: let
  out-of-your-element = pkgs.callPackage ./out-of-your-element.nix {};
  data-dir = "/var/lib/out-of-your-element";
in {
  users = {
    groups.out-of-your-element = {};
    users.out-of-your-element = {
      isSystemUser = true;
      group = "out-of-your-element";
    };
  };

  deployment.keys."out-of-your-element.config.js" = {
    keyCommand = ["gpg" "--decrypt" "${./config.js.gpg}"];
    group = "out-of-your-element";
    user = "out-of-your-element";
    destDir = "/etc/keys";
    uploadAt = "pre-activation";
  };

  deployment.keys."bridge.service.registration.yaml" = {
    keyCommand = ["gpg" "--decrypt" "${./registration.yaml.gpg}"];
    group = "out-of-your-element";
    user = "out-of-your-element";
    destDir = "/etc/keys";
    uploadAt = "pre-activation";
  };

  deployment.keys."bridge.matrix.registration.yaml" = {
    keyCommand = ["gpg" "--decrypt" "${./registration.yaml.gpg}"];
    group = "matrix-synapse";
    user = "matrix-synapse";
    destDir = "/etc/keys";
    uploadAt = "pre-activation";
  };

  services.matrix-synapse.settings.app_service_config_files = [
    config.deployment.keys."bridge.matrix.registration.yaml".path
  ];

  systemd.tmpfiles.rules = [
    "C+ ${data-dir} - - - - ${out-of-your-element}/lib/node_modules/out-of-your-element"
    "Z ${data-dir} 0750 out-of-your-element out-of-your-element - -"
    "d ${data-dir}/db 0750 out-of-your-element out-of-your-element - -"
    "d ${data-dir}/node_modules 0750 out-of-your-element out-of-your-element - -"

    "L ${data-dir}/config.js - - - - ${config.deployment.keys."out-of-your-element.config.js".path}"
    "L ${data-dir}/registration.yaml - - - - ${config.deployment.keys."bridge.service.registration.yaml".path}"
  ];

  systemd.services.out-of-your-element = {
    enable = true;
    path = [pkgs.vips];
    wantedBy = ["multi-user.target"];
    script = "${lib.getExe pkgs.nodejs_20} start.js";
    preStart = "${lib.getExe pkgs.nodejs_20} scripts/seed.js";

    serviceConfig = {
      WorkingDirectory = data-dir;
      Group = "out-of-your-element";
      User = "out-of-your-element";
    };
  };
}
