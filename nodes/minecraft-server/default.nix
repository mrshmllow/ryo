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

  deployment.keys."minecraft.env.gpg" = {
    keyCommand = ["gpg" "--decrypt" "${./minecraft.env.gpg}"];

    uploadAt = "pre-activation";
  };

  services.minecraft-servers = let
    whitelist = {
      marshmallow = "dd4edde3-f0c7-4e27-82df-9c374548f2b9";

      Tentable876 = "665d064b-2b07-420d-859b-7f1774b46568";
      pepsi985 = "28035660-6a73-44a6-b3a6-022f52955a5b";
      Pepsi_max5901 = "3a5c4759-6d18-473e-a397-201a7b84410d";
      Always_Happy213 = "8b146eea-ef23-40ea-b8fd-4b8b592a2969";
      MaterialTec = "ce4f5c09-bb90-45c6-ae1c-28ebe17b39af";
      Polarite_Panda = "307d67f3-7a4c-4853-b3a8-d8d78c1f90c8";
    };
    plugins = {
      "plugins/SimpleVoiceChat.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/9eGKb6K1/versions/nS19YToN/voicechat-bukkit-2.5.20.jar";
        hash = "sha256-XRJdYjkdj8guYuYV7Ti14F/FURoP6526YDm5/kGXfAg=";
      };
      "plugins/LuckPerms-Bukkit.jar" = pkgs.fetchurl {
        url = "https://download.luckperms.net/1554/bukkit/loader/LuckPerms-Bukkit-5.4.139.jar";
        hash = "sha256-8DhCoj9LSxhXKLmjwai598qp9hAQzbIPPNNmIzhVdRw=";
      };
      "plugins/LPCMinimessage.jar" = pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/LOlAU5yB/versions/cfyseuAq/LPC-Minimessage.jar";
        hash = "sha256-KjmZtbREOTXnqyawRpNZp6JLFO/fJOGd80bMn+yx8J0=";
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
      velocity = {
        symlinks = {
          "plugins/LuckPerms-Velocity.jar" = pkgs.fetchurl {
            url = "https://download.luckperms.net/1554/velocity/LuckPerms-Velocity-5.4.139.jar";
            hash = "sha256-6v/CtD8QeqSuU9Y7oTIRJgIZCEiUrCOeslk52Euf38Y=";
          };
          "plugins/Velocitab.jar" = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/Q10irTG0/versions/8lauusu2/Velocitab-1.7.1-b4746dd.jar";
            hash = "sha256-DEA9dvkTP0MnvjpgJr2UDG53JrGXoHX3Ao1EzfGp54M=";
          };
          "plugins/luckperms/config.yml" = ./lp.velocity.yml;
        };
      };

      creative = {
        enable = true;
        autoStart = true;
        # Do not open!
        openFirewall = false;
        package = pkgs.paperServers.paper-1_21_1;

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
            "plugins/LuckPerms/config.yml" = pkgs.runCommand "config.yml" {} ''
              cp ${./lp.bukkit.yml} $out
              substituteInPlace $out --replace "%SERVER%" "creative"
            '';
          }
          // plugins;

        files = {
          "config/paper-global.yml" = ./paper-global.yml;
          "config/paper-world-defaults.yml" = ./paper-world-defaults.yml;
        };
      };

      survival = {
        enable = true;
        autoStart = true;
        # Do not open!
        openFirewall = false;
        package = pkgs.paperServers.paper-1_21_1;

        inherit whitelist;

        serverProperties = {
          white-list = true;
          difficulty = "normal";
          server-port = 25568;
        };

        symlinks =
          {
            "plugins/LuckPerms/config.yml" = pkgs.runCommand "config.yml" {} ''
              cp ${./lp.bukkit.yml} $out
              substituteInPlace $out --replace "%SERVER%" "creative"
            '';
            "plugins/BlueMap.jar" = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/swbUV1cr/versions/TL5ElRWX/BlueMap-5.3-spigot.jar";
              hash = "sha256-fNHcgcoELud8Zxy2nmYX9bFLEIq5spnIk3uMASYfmiI=";
            };
          }
          // plugins;

        files = {
          "config/paper-global.yml" = ./paper-global.yml;
          "config/paper-world-defaults.yml" = ./paper-world-defaults.yml;
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
  networking.hostName = "mc";
  networking.domain = "althaea.zone";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC2kH40sa5FDliqDNROQgsR5h1W6sdSona22K9YvUx0K marsh@marsh-wsl" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsrE2dWjrj+nBTYrrfpVIaW6wxs3ClSDW3iKffD73p+ marsh@marsh-framework"];
  system.stateVersion = "23.11";
}
