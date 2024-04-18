{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    getTailscale = subdomain: subdomain + ".cat-magellanic.ts.net";
  in {
    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
        };
      };

      defaults = {pkgs, ...}: {
        services.tailscale = {
          enable = true;
          authKeyFile = "/run/keys/tailscale.key";
          permitCertUid = "caddy";
        };

        deployment.keys."tailscale.key" = {
          keyCommand = ["age" "--decrypt" "-i" "/home/marsh/key.txt" "secrets/tailscale.key"];

          uploadAt = "pre-activation";
        };

        services.prometheus.exporters = {
          node = {
            enable = true;
            enabledCollectors = ["systemd"];
            port = 9002;
          };
        };

        # By default, Colmena will replace unknown remote profile
        # (unknown means the profile isn't in the nix store on the
        # host running Colmena) during apply (with the default goal,
        # boot, and switch).
        # If you share a hive with others, or use multiple machines,
        # and are not careful to always commit/push/pull changes
        # you can accidentaly overwrite a remote profile so in those
        # scenarios you might want to change this default to false.
        # deployment.replaceUnknownProfiles = true;
      };

      outpost-1 = {
        name,
        nodes,
        pkgs,
        lib,
        modulesPath,
        config,
        ...
      }: {
        deployment = {
          targetHost = builtins.trace name name;
          targetUser = "root";
          buildOnTarget = true;
        };

        imports = [./nodes/outpost-1];
      };
    };
  };
}
