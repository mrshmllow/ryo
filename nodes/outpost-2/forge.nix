{config, ...}: {
  services.forgejo = {
    enable = true;
    settings = {
      server = {
        ROOT_URL = "https://git.althaea.zone";
        DOMAIN = "git.althaea.zone";
        LANDING_PAGE = "explore";
        OFFLINE_MODE = false;
      };

      service = {
        ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
      };
    };

    database = {
      type = "postgres";
    };
  };

  virtualisation.docker.enable = true;

  services.caddy = {
    enable = true;
    virtualHosts.${config.services.forgejo.settings.server.DOMAIN}.extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}

      rewrite /user/login /user/oauth2/Keycloak
    '';
  };
}
