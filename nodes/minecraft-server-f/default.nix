{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./backup.nix
    ../minecraft-server/module.nix
  ];

  nixpkgs = {
    overlays = [inputs.nix-minecraft.overlay];

    config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "minecraft-server"
      ];
  };

  deployment.keys."minecraft.env.gpg" = {
    keyCommand = ["gpg" "--decrypt" "${./minecraft.env.gpg}"];

    uploadAt = "pre-activation";
    destDir = "/etc/keys";
  };

  services.minecraft-servers = let
    whitelist = {
      marshmallow = "dd4edde3-f0c7-4e27-82df-9c374548f2b9";
      Cinedaniel = "e844b36e-b0f0-4054-9c00-3fadf216fd90";
      gremyy = "6340aeb2-c218-45a2-bc54-14fd153468e9";
      Bacongoblin = "b3502b0b-13a1-42bb-9db6-504cf12a5f3e";
    };
  in {
    enable = true;
    eula = true;

    voicechat-servers = ["survival"];

    velocity = {
      enable = true;
      openFirewall = true;
      config = {
        servers = ["survival"];
        try = ["survival"];
        motd = "visit <color:#4287f5>mc.althaea.zone</color:#4287f5> for the map";
      };
    };

    environmentFile = config.deployment.keys."minecraft.env.gpg".path;

    servers = {
      survival = {
        enable = true;
        autoStart = true;
        # Do not open!
        openFirewall = false;
        package = pkgs.fabricServers.fabric-1_21_4;

        inherit whitelist;

        serverProperties = {
          white-list = true;
          difficulty = "normal";
          server-port = 25568;
        };

        symlinks = {
          "mods/BlueMap.jar" = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/swbUV1cr/versions/Mvle7bPy/bluemap-5.5-fabric.jar";
            hash = "sha256-/fwlSgI3bOjRdo6WOu/Rov8ZDc8PLZehtuT2mhAjf9M=";
          };
          "mods/litium.jar" = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/t1FlWYl9/lithium-fabric-0.14.3%2Bmc1.21.4.jar";
            hash = "sha256-LJFVhw/3MnsPnYTHVZbM3xJtne1lV5twuYeqZSMZEn4=";
          };
          "mods/fabric-api.jar" = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/kgg9d3no/fabric-api-0.112.0%2B1.21.4.jar";
            hash = "sha256-sF8YSSJ5P1yXWL69MSilqCz8ez9TjwDXQ0F5+MJMLMk=";
          };
          "mods/chunky.jar" = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/fALzjamp/versions/VkAgASL1/Chunky-Fabric-1.4.27.jar";
            hash = "sha256-A8kKcLIzQWvZZziUm+kJ0eytrHQ/fBVZQ18uQXN9Qf0=";
          };
          "mods/viafabric.jar" = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/YlKdE5VK/versions/UGHhXjIX/ViaFabric-0.4.17%2B93-main.jar";
            hash = "sha256-jdaOP3okwaWprXsBu4jzzbhwfs3GOumODrnPjGa5S6Q=";
          };
          "mods/viabackwards.jar" = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/NpvuJQoq/versions/eMvFeqZt/ViaBackwards-5.2.0.jar";
            hash = "sha256-/It2n35VFMl2WTeWF3ft4cO6hNhzHZ09zVI+b0CnQvI=";
          };
          "mods/FabricProxy-Lite.jar" = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/8dI2tmqs/versions/AQhF7kvw/FabricProxy-Lite-2.9.0.jar";
            hash = "sha256-wIQA86Uh6gIQgmr8uAJpfWY2QUIBlMrkFu0PhvQPoac=";
          };
          "mods/simplevoicechat.jar" = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/9eGKb6K1/versions/pl9FpaYJ/voicechat-fabric-1.21.4-2.5.26.jar";
            hash = "sha256-2ni2tQjMCO3jaEA1OHXoonZpGqHGVlY/9rzVsijrxVA=";
          };
        };

        files = {
          # "config/paper-global.yml" = ./paper-global.yml;
          # "config/paper-world-defaults.yml" = ./paper-world-defaults.yml;
        };
      };
    };
  };

  # caddy
  networking.firewall.allowedUDPPorts = [config.services.minecraft-servers.velocity.port];

  networking.firewall.allowedTCPPorts = [80 443];

  services.caddy = {
    enable = true;

    # bluemap port
    virtualHosts."mc.althaea.zone".extraConfig = ''
      reverse_proxy http://127.0.0.1:8100

      tls /var/lib/caddy/althaea.zone.pem /var/lib/caddy/althaea.zone.key
    '';
  };

  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = "minecraft";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = ["minecraft"];
  };

  environment.systemPackages = with pkgs; [
    tmux
  ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = "mc-forgettable";
  networking.domain = "althaea.zone";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC2kH40sa5FDliqDNROQgsR5h1W6sdSona22K9YvUx0K marsh@marsh-wsl" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsrE2dWjrj+nBTYrrfpVIaW6wxs3ClSDW3iKffD73p+ marsh@marsh-framework" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPSvOZoSGVEpR6eTDK9OJ31MWQPF2s8oLc8J7MBh6nez marsh@maple"];
  system.stateVersion = "23.11";
}
