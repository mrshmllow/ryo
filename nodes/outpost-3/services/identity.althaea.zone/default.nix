{ config, ... }:
{
  deployment.keys."keycloak-db.pass" = {
    keyCommand = [
      "gpg"
      "--decrypt"
      "${./../../../../secrets/keycloak-db.pass.gpg}"
    ];

    uploadAt = "pre-activation";
    destDir = "/etc/keys";
  };

  services.keycloak = {
    enable = true;
    settings = {
      hostname = "identity.althaea.zone";

      http-port = 9090;
      proxy-headers = "xforwarded";
      http-enabled = true;
    };

    database.passwordFile = config.deployment.keys."keycloak-db.pass".path;
  };

  services.caddy = {
    enable = true;
    virtualHosts.${config.services.keycloak.settings.hostname}.extraConfig = ''
      reverse_proxy http://${config.services.keycloak.settings.http-host}:${toString config.services.keycloak.settings.http-port}
    '';
  };
}
