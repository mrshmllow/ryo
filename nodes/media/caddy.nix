{ config, lib, ... }:
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
        virtualHosts."*.home.althaea.zone".extraConfig =
          (lib.concatLines (
            lib.mapAttrsToList (name: value: ''
              @${name} host ${name}.home.althaea.zone
              handle @${name} {
                reverse_proxy localhost:${builtins.toString value.port}
              }
            '') config.media.subdomains
          ))
          + ''
            tls /var/lib/caddy/star.home.althaea.zone.pem /var/lib/caddy/star.home.althaea.zone.key
          '';
      };
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
