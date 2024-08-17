{
  pkgs,
  lib,
  config,
  ...
}: let
  out-of-your-element = pkgs.callPackage ./out-of-your-element.nix {};
in {
  deployment.keys."out-of-your-element.config.js" = {
    keyCommand = ["gpg" "--decrypt" "${./config.js.gpg}"];

    uploadAt = "pre-activation";
  };

  deployment.keys."out-of-your-element.registration.yaml" = {
    keyCommand = ["gpg" "--decrypt" "${./registration.yml.gpg}"];

    uploadAt = "pre-activation";
  };

  systemd.services.out-of-your-element = {
    # name = "out-of-your-element";
    enable = true;
    path = [pkgs.nodejs_22];
    script = "node start.js";

    serviceConfig = {
      WorkingDirectory = "${out-of-your-element}/lib/node_modules/out-of-your-element";
      BindPaths = lib.concatStringsSep " " [
        "${config.deployment.keys."out-of-your-element.config.js".path}:${out-of-your-element}/lib/node_modules/out-of-your-element/config.js"
        "${config.deployment.keys."out-of-your-element.registration.yaml".path}:${out-of-your-element}/lib/node_modules/out-of-your-element/registration.yaml"
      ];
    };
  };
}
