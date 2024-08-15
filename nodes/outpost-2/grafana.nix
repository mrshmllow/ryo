{
  name,
  config,
  ...
}: {
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
        scopes = ["openid" "email" "profile" "offline_access" "roles"];
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
      {
        name = "Loki";
        type = "loki";
        access = "proxy";
        url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
      }
    ];
  };

  systemd.services.grafana.serviceConfig.EnvironmentFile = "/etc/keys/grafana.env";

  deployment.keys."grafana.env" = {
    keyCommand = ["gpg" "--decrypt" "${./grafana/grafana.env.gpg}"];
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
        job_name = name;
        static_configs = [
          {
            targets = ["${name}:9002"];
          }
        ];
      }
      {
        job_name = "pi";
        static_configs = [
          {
            targets = ["pi:9002"];
          }
        ];
      }
    ];
  };

  services.loki = {
    enable = true;
    configuration = {
      server.http_listen_port = 3030;
      auth_enabled = false;

      common = {
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
        replication_factor = 1;
        path_prefix = "/tmp/loki";
      };

      schema_config = {
        configs = [
          {
            from = "2020-05-15";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };

      storage_config.filesystem.directory = "/tmp/loki/chunks";
    };
  };

  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3031;
        grpc_listen_port = 0;
      };
      positions = {
        filename = "/tmp/positions.yaml";
      };
      clients = [
        {
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
        }
      ];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = "outpost-2";
            };
          };
          relabel_configs = [
            {
              source_labels = ["__journal__systemd_unit"];
              target_label = "unit";
            }
          ];
        }
      ];
    };
  };
}
