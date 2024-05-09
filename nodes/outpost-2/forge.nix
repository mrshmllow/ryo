{config, ...}: {
  services.forgejo = {
    enable = true;
    settings = {
      server = {
        DOMAIN = "git.althaea.zone";
        LANDING_PAGE = "explore";
      };

      service = {
        DISABLE_REGISTRATION = true;
      };
    };
  };

  services.gitea-actions-runner.instances = {
    outpost-1 = {
      enable = true;
      name = config.networking.hostName;
      url = "https://" + config.services.forgejo.settings.server.DOMAIN;
      labels = [
        "ubuntu-latest:docker://node:22.1-bullseye"
      ];
    };
  };

  virtualisation.docker.enable = true;

  services.caddy = {
    enable = true;
    virtualHosts."git.althaea.zone".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}
    '';
  };
}
