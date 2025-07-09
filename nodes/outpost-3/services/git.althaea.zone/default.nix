{
  config,
  pkgs,
  lib,
  ...
}:
let
  themes =
    map
      (
        theme:
        map (color: "catppuccin-${theme}-${color}") [
          "rosewater"
          "flamingo"
          "pink"
          "mauve"
          "red"
          "maroon"
          "peach"
          "yellow"
          "green"
          "teal"
          "sky"
          "sapphire"
          "blue"
          "lavender"
        ]
      )
      [
        "latte"
        "frappe"
        "macchiato"
        "mocha"
      ];
  default-themes = [
    "forgejo-auto"
    "forgejo-light"
    "forgejo-dark"
    "forgejo-auto-deuteranopia-protanopia"
    "forgejo-light-deuteranopia-protanopia"
    "forgejo-dark-deuteranopia-protanopia"
    "forgejo-auto-tritanopia"
    "forgejo-light-tritanopia"
    "forgejo-dark-tritanopia"
  ];
in
{
  imports = [ ./runner.nix ];

  services.forgejo = {
    enable = true;
    package = pkgs.forgejo;
    settings = {
      server = {
        ROOT_URL = "https://git.althaea.zone";
        DOMAIN = "git.althaea.zone";
        SSH_DOMAIN = "bare.git.althaea.zone";
        LANDING_PAGE = "explore";
        OFFLINE_MODE = false;
      };

      service = {
        ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
      };

      ui = {
        THEMES = lib.strings.concatStringsSep "," (builtins.concatLists themes ++ default-themes);
        DEFAULT_THEME = "catppuccin-mocha-mauve";
      };
    };

    database = {
      type = "postgres";
    };
  };

  systemd.services.forgejo = {
    preStart =
      let
        name = "catppuccin-themes";

        catppuccin-themes = pkgs.fetchurl {
          url = "https://github.com/catppuccin/gitea/releases/download/v1.0.1/catppuccin-gitea.tar.gz";
          sha256 = "sha256-TvC6DxmjCy/qskJL+WMZO7Y2tcUI++y4GUgeAkDaKaM=";
        };
        theme-dir = "${config.services.forgejo.customDir}/public/assets/css";
        script = pkgs.writeShellScriptBin name ''
          mkdir -p ${theme-dir}
          tar -xf ${catppuccin-themes} --overwrite -C ${theme-dir}
        '';

        package = pkgs.symlinkJoin {
          inherit name;
          paths =
            [ script ]
            ++ [
              pkgs.gnutar
              pkgs.gzip
            ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
        };
      in
      lib.mkAfter ''
        (umask 027; ${lib.getExe' package "catppuccin-themes"})
      '';
    after = [ "keycloak.service" ];
  };

  # https://github.com/NixOS/nixpkgs/issues/306205
  services.openssh.settings.AcceptEnv = "GIT_PROTOCOL";

  virtualisation.docker.enable = true;

  services.caddy = {
    enable = true;
    virtualHosts.${config.services.forgejo.settings.server.DOMAIN}.extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}

      rewrite /user/login /user/oauth2/Keycloak
    '';
  };
}
