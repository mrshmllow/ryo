{ config, ... }:
let
  domain = "autobrr.local";
in
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

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    reverse_proxy :${builtins.toString config.services.autobrr.settings.port}
    tls internal
  '';

  services.blocky.settings.customDNS.mapping = {
    ${domain} = "10.1.1.117";
  };
}
