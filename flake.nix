{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    yard-search.url = "github:mrshmllow/yard-search";
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs = {nixpkgs.follows = "nixpkgs";};
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
      ];

      imports = [
        inputs.devenv.flakeModule
      ];

      perSystem = {pkgs, ...}: {
        devenv.shells.default = {
          packages = with pkgs; [colmena age];
        };
      };

      flake.colmena = {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
          };
          specialArgs = {inherit inputs;};
        };

        defaults = {
          pkgs,
          node,
          nodes,
          ...
        }: {
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
        };

        outpost-1 = {name, ...}: {
          deployment = {
            #targetHost = name;
            targetHost = "37.27.42.71";
            targetUser = "root";
            buildOnTarget = true;
          };

          deployment.keys."meilimasterkey" = {
            keyCommand = ["age" "--decrypt" "-i" "/home/marsh/key.txt" "secrets/meilimasterkey"];

            uploadAt = "pre-activation";
          };

          imports = [./nodes/${name}];
        };

        outpost-2 = {name, ...}: {
          deployment = {
            targetHost = name;
            targetUser = "root";
            buildOnTarget = true;
          };

          imports = [./nodes/${name}];
        };

        pi = {name, ...}: {
          deployment = {
            targetHost = "100.115.246.65";
            targetUser = "root";
            buildOnTarget = false;
          };

          imports = [./nodes/${name}];
        };
      };
    };
}
