{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.media = {
    subdomains = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            port = lib.mkOption {
              type = lib.types.port;
            };
          };
        }
      );
      default = { };
    };
  };

  config = {
    services = {
      blocky = {
        enable = true;
        settings = {
          upstream.default = [
            "https://one.one.one.one/dns-query"
          ];
          bootstrapDns = {
            upstream = "https://one.one.one.one/dns-query";
            ips = [
              "1.1.1.1"
              "1.0.0.1"
            ];
          };
          customDNS.mapping = lib.mapAttrs' (name: value: {
            value = "10.1.1.117";
            name = "${name}.home.althaea.zone";
          }) config.media.subdomains;
        };
      };

      caddy = {
        enable = true;
        email = "acme.amnesty785@passmail.com";
        environmentFile = config.deployment.keys."caddy.env".path;
        package = pkgs.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/cloudflare@v0.2.1" ];
          hash = "sha256-2D7dnG50CwtCho+U+iHmSj2w14zllQXPjmTHr6lJZ/A=";
        };
        virtualHosts."*.home.althaea.zone".extraConfig =
          (lib.concatLines (
            lib.mapAttrsToList (name: value: ''
              @${name} host ${name}.home.althaea.zone
              handle @${name} {
                @blocked not remote_ip 100.64.0.0/10 10.1.1.0/24
                respond @blocked "Forbidden" 403

                reverse_proxy localhost:${builtins.toString value.port}
              }
            '') config.media.subdomains
          ))
          + ''
            tls {
                dns cloudflare {$CLOUDFLARE_API_TOKEN}
            }
          '';
      };
    };

    deployment.keys."caddy.env" = {
      keyCommand = [
        "gpg"
        "--decrypt"
        "${../../secrets/media.caddy.env.gpg}"
      ];

      destDir = "/etc/keys";
      uploadAt = "pre-activation";
    };

    networking.firewall = {
      allowedTCPPorts = [
        80
        443
        53
      ];
      allowedUDPPorts = [ 53 ];
    };
  };
}
