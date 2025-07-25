{ config, ... }:
{
  services.autobrr = {
    enable = true;
    openFirewall = true;
    secretFile = config.deployment.keys."autobrr.secret".path;
  };

  deployment.keys."autobrr.secret" = {
    keyCommand = [
      "gpg"
      "--decrypt"
      "${../../../../secrets/autobrr.secret.gpg}"
    ];

    destDir = "/etc/keys";
    uploadAt = "pre-activation";
  };

  media.subdomains."autobrr".port = config.services.autobrr.settings.port;
}
