{
  pkgs,
  config,
  ...
}: {
  services.postgresql = {
    enable = true;
    initialScript = pkgs.writeText "synapse-init.sql" ''
      CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
      CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse" TEMPLATE template0 LC_COLLATE = "C" LC_CTYPE = "C";
    '';
  };

  deployment.keys."synapse-keycloak.yml" = {
    keyCommand = ["gpg" "--decrypt" "nodes/outpost-2/matrix/synapse-keycloak.yml.gpg"];
    uploadAt = "pre-activation";
    destDir = "/etc/keys";
    user = "matrix-synapse";
    group = config.users.users.matrix-synapse.group;
  };

  services.matrix-synapse = {
    enable = true;
    extras = [
      "oidc"
    ];
    settings = {
      server_name = "althaea.zone";
      public_baseurl = "https://matrix.althaea.zone";
      url_preview_enabled = true;
      max_upload_size = "200M";
      enable_registration = false;
      password_config.enabled = false;
      backchannel_logout_enabled = true;
    };
    extraConfigFiles = ["/etc/keys/synapse-keycloak.yml"];
  };

  services.caddy = {
    virtualHosts."https://althaea.zone".extraConfig = ''
      header /.well-known/matrix/* Content-Type application/json
      header /.well-known/matrix/* Access-Control-Allow-Origin *
      respond /.well-known/matrix/server `{"m.server": "matrix.althaea.zone:443"}`
      respond /.well-known/matrix/client `{"m.homeserver":{"base_url":"https://matrix.althaea.zone"}}`

      tls /var/lib/caddy/althaea.zone.pem /var/lib/caddy/althaea.zone.key
    '';
    virtualHosts."https://matrix.althaea.zone".extraConfig = ''
      reverse_proxy /_matrix/* localhost:8008
      reverse_proxy /_synapse/client/* localhost:8008

      tls /var/lib/caddy/althaea.zone.pem /var/lib/caddy/althaea.zone.key
    '';

    virtualHosts."element.althaea.zone".extraConfig = ''
      root * ${pkgs.element-web.override {
        conf = {
          default_server_config = {
            "m.homeserver" = {
              base_url = "https://matrix.althaea.zone";
              server_name = "althaea.zone";
            };
          };
          permalink_prefix = "https://element.althaea.zone/";
        };
      }}
      file_server
    '';
  };

  networking.firewall.allowedTCPPorts = [8448];
}
