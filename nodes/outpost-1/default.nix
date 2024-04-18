{
  name,
  nodes,
  pkgs,
  lib,
  modulesPath,
  config,
  ...
}: {
  imports = [./hetzner.nix];

  nixpkgs.system = "aarch64-linux";

  services.grafana = {
    enable = true;

    settings.server.http_port = 2342;
    settings.server.domain = getTailscale config.deployment.targetHost;

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
  };

  networking.firewall.allowedTCPPorts = [80 443];

  services.prometheus = {
    enable = true;
    port = 9001;

    scrapeConfigs = lib.lists.forEach nodes (
      x: {
        job_name = x;
        static_configs = [
          {
            targets = ["${x}:9002"];
          }
        ];
      }
    );
  };
}
