{config, ...}: {
  services.keycloak = {
    enable = true;
    settings = {
      hostname = "identity.althaea.zone";

      http-port = 9090;
      proxy = "edge";
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts.${config.services.keycloak.settings.hostname}.extraConfig = ''
      reverse_proxy http://${config.services.keycloak.settings.http-host}:${toString config.services.keycloak.settings.http-port}
    '';
  };
}
