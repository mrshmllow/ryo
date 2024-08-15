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
    ./module.nix
  ];

  nixpkgs = {
    overlays = [inputs.nix-minecraft.overlay];

    config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "minecraft-server"
      ];
  };

  services.minecraft-servers = let
    fabric = pkgs.fabricServers.fabric-1_21_1;
    mods = {
      "mods/FabricProxy-Lite.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/8dI2tmqs/versions/AQhF7kvw/FabricProxy-Lite-2.9.0.jar";
        hash = "sha256-wIQA86Uh6gIQgmr8uAJpfWY2QUIBlMrkFu0PhvQPoac=";
      };
      "mods/Lithium.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/5szYtenV/lithium-fabric-mc1.21.1-0.13.0.jar";
        hash = "sha256-ENNx/uOXvwMG4eLYY8VMVkQrzC3G4BYD8UafL+SRDWE=";
      };
      "mods/FerriteCore.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/uXXizFIs/versions/wmIZ4wP4/ferritecore-7.0.0-fabric.jar";
        hash = "sha256-LDEgDR9d5qPPXtxMPTkgBjbh4GDEtUjc+CSe9IdmAyM=";
      };
      "mods/SimpleVoiceChat.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/9eGKb6K1/versions/lZkOuATd/voicechat-fabric-1.21.1-2.5.20.jar";
        hash = "sha256-YDFhGhT34iNWUT7jYBGn2A/E63RxhRZ6Jtdxzyf1y2U=";
      };
      "mods/Chunky.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/fALzjamp/versions/dPliWter/Chunky-1.4.16.jar";
        hash = "sha256-yfA+Mi5jHulMy42/N3aFnNEnZuUTt1M+n5ZueZ20eTc=";
      };
      "mods/Fabric.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/bK6OgzFj/fabric-api-0.102.1%2B1.21.1.jar";
        hash = "sha256-2ouVZNKtpqT/6uYrwSn7QhRHhsxTzx55oNcj8vaTopw=";
      };
      "mods/LuckPerms.jar" = pkgs.fetchurl {
        url = "https://download.luckperms.net/1554/fabric/LuckPerms-Fabric-5.4.139.jar";
        hash = "sha256-QOdw3jgJnYXOZuaVp45z0jzRH1Ar56FZwm4onJzBEtQ=";
      };
    };

    whitelist = {
      marshmallow = "dd4edde3-f0c7-4e27-82df-9c374548f2b9";

      Tentable876 = "665d064b-2b07-420d-859b-7f1774b46568";
      pepsi985 = "28035660-6a73-44a6-b3a6-022f52955a5b";
      Pepsi_max5901 = "3a5c4759-6d18-473e-a397-201a7b84410d";
      Always_Happy213 = "8b146eea-ef23-40ea-b8fd-4b8b592a2969";
      MaterialTec = "ce4f5c09-bb90-45c6-ae1c-28ebe17b39af";
      Polarite_Panda = "307d67f3-7a4c-4853-b3a8-d8d78c1f90c8";
    };
  in {
    enable = true;
    eula = true;

    voicechat-servers = ["default" "creative"];

    velocity = {
      enable = true;
      openFirewall = true;
      config = {
        servers = ["default" "creative"];
        try = ["default" "creative"];
        motd = "visit <color:#4287f5>mc.althaea.zone</color:#4287f5> for the map";
      };
    };

    servers = {
      velocity = {
        symlinks = {
          "plugins/LuckPerms-Velocity.jar" = pkgs.fetchurl {
            url = "https://download.luckperms.net/1554/velocity/LuckPerms-Velocity-5.4.139.jar";
            hash = "sha256-6v/CtD8QeqSuU9Y7oTIRJgIZCEiUrCOeslk52Euf38Y=";
          };
          "plugins/luckperms/config.yml" = ./lp.velocity.yml;
        };
      };

      creative = {
        enable = true;
        autoStart = true;
        # Do not open!
        openFirewall = false;
        package = fabric;

        inherit whitelist;

        serverProperties = {
          white-list = true;
          difficulty = "normal";
          gamemode = "creative";
          level-type = "minecraft:flat";
          server-port = 25567;
        };

        symlinks =
          {
            "config/luckperms/luckperms.conf" = pkgs.runCommand "luckperms.conf" {} ''
              cp ${./lp.fabric.conf} $out
              substituteInPlace $out --replace "%SERVER%" "creative"
            '';
          }
          // mods;
      };

      default = {
        enable = true;
        autoStart = true;
        # Do not open!
        openFirewall = false;
        package = fabric;

        inherit whitelist;

        serverProperties = {
          white-list = true;
          difficulty = "normal";
          server-port = 25568;
        };

        symlinks =
          {
            "config/luckperms/luckperms.conf" = pkgs.runCommand "luckperms.conf" {} ''
              cp ${./lp.fabric.conf} $out
              substituteInPlace $out --replace "%SERVER%" "survival"
            '';

            "mods/BlueMap.jar" = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/swbUV1cr/versions/Zpzf0Xab/BlueMap-5.3-fabric.jar";
              hash = "sha256-5FdRX2773zgIR5MQSNAO52lblA5M9wi57fjbQSe0oXs=";
            };
          }
          // mods;
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
  networking.hostName = "mc";
  networking.domain = "althaea.zone";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC2kH40sa5FDliqDNROQgsR5h1W6sdSona22K9YvUx0K marsh@marsh-wsl" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsrE2dWjrj+nBTYrrfpVIaW6wxs3ClSDW3iKffD73p+ marsh@marsh-framework"];
  system.stateVersion = "23.11";
}
