{
  config,
  ...
}:
{
  services.grafana = {
    enable = true;

    settings = {
      server.http_port = 2342;
      server.domain = "grafana.althaea.zone";
      server.root_url = "https://grafana.althaea.zone/";

      "auth.generic_oauth" = {
        enable = true;
        auto_login = false;
        name = "Keycloak-OAuth";
        allow_sign_up = true;
        client_id = "grafana";
        client_secret = ''''${KEYCLOAK_GRAFANA_SECRET}'';
        scopes = [
          "openid"
          "email"
          "profile"
          "offline_access"
          "roles"
        ];
        email_attribute_path = "email";
        login_attribute_path = "username";
        name_attribute_path = "full_name";
        auth_url = "https://identity.althaea.zone/realms/master/protocol/openid-connect/auth";
        token_url = "https://identity.althaea.zone/realms/master/protocol/openid-connect/token";
        api_url = "https://identity.althaea.zone/realms/master/protocol/openid-connect/userinfo";
        role_attribute_path = "contains(roles[*], 'admin') && 'Admin' || contains(roles[*], 'editor') && 'Editor' || 'Viewer'";
      };
    };

    provision.datasources.settings.datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://127.0.0.1:${toString config.services.prometheus.port}";
      }
      # {
      #   name = "Loki";
      #   type = "loki";
      #   access = "proxy";
      #   url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
      # }
    ];
  };

  systemd.services.grafana.serviceConfig.EnvironmentFile = "/etc/keys/grafana.env";

  deployment.keys."grafana.env" = {
    keyCommand = [
      "gpg"
      "--decrypt"
      "${../../../../secrets/grafana.env.gpg}"
    ];
    uploadAt = "pre-activation";
    destDir = "/etc/keys";
    user = "grafana";
    group = "grafana";
  };

  services.caddy = {
    enable = true;
    virtualHosts."${config.services.grafana.settings.server.domain}".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}
    '';
  };

  services.prometheus = {
    enable = true;
    port = 9001;

    scrapeConfigs = [
      {
        job_name = "servers";
        static_configs = builtins.map (name: { targets = [ "${name}:9002" ]; }) config.ryo.exporting_nodes;
      }
    ];
  };
}
