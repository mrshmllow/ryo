{
  inputs,
  name,
  nodes,
  pkgs,
  lib,
  modulesPath,
  config,
  ...
}: {
  services.grafana = {
    enable = true;

    settings.server.http_port = 2342;
    settings.server.domain = config.deployment.targetHost + ".cat-magellanic.ts.net";

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

  services.caddy = {
    enable = true;
    virtualHosts."${config.services.grafana.settings.server.domain}".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}
    '';
    virtualHosts."http://search.jerma.fans".extraConfig = ''
      reverse_proxy http://127.0.0.1:3000
    '';
    virtualHosts."http://meilisearch.jerma.fans".extraConfig = ''
      reverse_proxy http://${config.services.meilisearch.listenAddress}:${toString config.services.meilisearch.listenPort}
    '';
  };

  services.prometheus = {
    enable = true;
    port = 9001;

    scrapeConfigs =
      [
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

  networking.firewall.allowedTCPPorts = [80 443];
}
