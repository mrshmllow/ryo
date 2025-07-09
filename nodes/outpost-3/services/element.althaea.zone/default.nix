{ pkgs, ... }:
{
  services.caddy.virtualHosts."element.althaea.zone".extraConfig = ''
    root * ${
      pkgs.element-web.override {
        conf = {
          default_server_config = {
            "m.homeserver" = {
              base_url = "https://matrix.althaea.zone";
              server_name = "althaea.zone";
            };
          };
          permalink_prefix = "https://element.althaea.zone/";
        };
      }
    }
    file_server
  '';
}
