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
      ReubenLaurence = "edf6913d-d73a-42ab-ad7a-f0736dc40b7c";
    };
    common-mods = {
      # Server Optomization
      "mods/litium.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/t1FlWYl9/lithium-fabric-0.14.3%2Bmc1.21.4.jar";
        hash = "sha256-LJFVhw/3MnsPnYTHVZbM3xJtne1lV5twuYeqZSMZEn4=";
      };
      # Dependencies
      "mods/fabric-api.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/kgg9d3no/fabric-api-0.112.0%2B1.21.4.jar";
        hash = "sha256-sF8YSSJ5P1yXWL69MSilqCz8ez9TjwDXQ0F5+MJMLMk=";
      };
      "mods/architectury.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/lhGA9TYQ/versions/XRwibvvn/architectury-15.0.1-fabric.jar";
        hash = "sha256-KRvaGWBaL2a4OjU6cqk/HEpQ1xlRa30wSBzCFw06+A4=";
      };
      "mods/cloth-config.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/9s6osm5g/versions/TJ6o2sr4/cloth-config-17.0.144-fabric.jar";
        hash = "sha256-H9oMSonU8HXlGz61VwpJEocGVtJS2AbqMJHSu8Bngeo=";
      };
      # Velocity Requirement
      "mods/FabricProxy-Lite.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/8dI2tmqs/versions/AQhF7kvw/FabricProxy-Lite-2.9.0.jar";
        hash = "sha256-wIQA86Uh6gIQgmr8uAJpfWY2QUIBlMrkFu0PhvQPoac=";
      };
      # Voice Chat
      "mods/simplevoicechat.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/9eGKb6K1/versions/pl9FpaYJ/voicechat-fabric-1.21.4-2.5.26.jar";
        hash = "sha256-2ni2tQjMCO3jaEA1OHXoonZpGqHGVlY/9rzVsijrxVA=";
      };
      # Optional Client Mods w/ server support:
      "mods/xaeros-minimap.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/1bokaNcj/versions/pGS4L9Gk/Xaeros_Minimap_24.7.1_Fabric_1.21.4.jar";
        hash = "sha256-0/Ay3hAxbBNo5oflft/KV7mPnMY+0VPME059GLln0H8=";
      };
      "mods/rei.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/nfn13YXA/versions/aBHkMOqF/RoughlyEnoughItems-18.0.796-fabric.jar";
        hash = "sha256-z6TQqQFMD8X1gFQPBaoyF6TiiO90vMMjBpUAqRDLQRI=";
      };
      "mods/jade.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/nvQzSEkH/versions/EJub6tVz/Jade-1.21.4-Fabric-17.1.2.jar";
        hash = "sha256-2Ywaudtc5aYjS76WPRKvBJUJYBO8qHSFQo/mF6dPcLo=";
      };
      "mods/itemswapper.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/RPOSBQgq/versions/m5FBPEra/itemswapper-fabric-0.7.4-mc1.21.4.jar";
        hash = "sha256-ypX7hHcN2gD2b1F720zBNbjldga1cnTxLT2+SOv7q7w=";
      };
      "mods/shulkerboxtooltip.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/2M01OLQq/versions/L4CUJgGW/shulkerboxtooltip-fabric-5.2.2%2B1.21.4.jar";
        hash = "sha256-JKYxcLCd8X6y/RtAyel30WEjhfvAxKGpuS0rXL2Nt/8=";
      };
    };
  in {
    enable = true;
    eula = true;

    voicechat-servers = ["survival" "creative"];

    velocity = {
      enable = true;
      openFirewall = true;
      config = {
        servers = ["survival" "creative"];
        try = ["survival" "creative"];
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
          gamemode = "survival";
          generate-structures = false;
        };

        symlinks =
          {
            # Map
            "mods/BlueMap.jar" = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/swbUV1cr/versions/Mvle7bPy/bluemap-5.5-fabric.jar";
              hash = "sha256-/fwlSgI3bOjRdo6WOu/Rov8ZDc8PLZehtuT2mhAjf9M=";
            };
            # Anti xray
            "mods/anti-xray.jar" = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/sml2FMaA/versions/XYsqemKP/antixray-fabric-1.4.7%2B1.21.4.jar";
              hash = "sha256-/eCPum/EBDlVZGbC4HVXHOswerq+ANhlooi6YptoNq8=";
            };
            # Discord Chat
            "mods/dcintegration.jar" = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/rbJ7eS5V/versions/hd62ja8J/dcintegration-fabric-MC1.21.3-3.1.0.1.jar";
              hash = "sha256-5Us8Ig8Nwv9zFLQx8X/C7cTz/O0uTDjeztYMAXBWK0Q=";
            };
            # World Pregen
            "mods/chunky.jar" = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/fALzjamp/versions/VkAgASL1/Chunky-Fabric-1.4.27.jar";
              hash = "sha256-A8kKcLIzQWvZZziUm+kJ0eytrHQ/fBVZQ18uQXN9Qf0=";
            };
          }
          // common-mods;
      };
      creative = {
        enable = true;
        autoStart = true;
        # Do not open!
        openFirewall = false;
        package = pkgs.fabricServers.fabric-1_21_4;

        inherit whitelist;

        serverProperties = {
          white-list = true;
          difficulty = "normal";
          server-port = 25569;
          level-type = "minecraft:flat";
          generator-settings = builtins.toJSON {
            layers = [
              {
                height = 3;
                block = "minecraft:bedrock";
              }
              {
                height = 116;
                block = "minecraft:sandstone";
              }
            ];
            biome = "minecraft:desert";
          };
        };

        symlinks =
          {
            # World Edit
            "mods/worldedit.jar" = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/1u6JkXh5/versions/rIYOU6Ta/worldedit-mod-7.3.10-beta-01.jar";
              hash = "sha256-MRjoE402to7g/wdB+9hWl8GPBvpD0CuswHmQbwYzkJE=";
            };
          }
          // common-mods;
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
