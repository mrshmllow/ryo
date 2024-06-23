{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";

    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    candy.url = "github:mrshmllow/nvim-candy";
  };

  outputs = inputs @ {
    flake-parts,
    home-manager,
    nixpkgs,
    nixos-hardware,
    ...
  }: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "x86_64-darwin" "i686-linux" "aarch64-linux"];
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations.marsh = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [./home.nix];
      };
    });

    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
        };
        specialArgs = {inherit inputs;};
      };

      defaults = {
        pkgs,
        name,
        nodes,
        lib,
        ...
      }: let
        exporting_nodes = ["outpost-2" "pi"];
      in {
        services.tailscale = {
          enable = true;
          authKeyFile = "/run/keys/tailscale.key";
          permitCertUid = "caddy";
          extraUpFlags = ["--ssh"];
        };

        deployment.keys."tailscale.key" = {
          keyCommand = ["age" "--decrypt" "-i" "/home/marsh/key.txt" "secrets/tailscale.key"];

          uploadAt = "pre-activation";
        };

        services.prometheus.exporters = lib.mkIf (builtins.elem name exporting_nodes) {
          node = {
            enable = true;
            enabledCollectors = ["systemd"];
            port = 9002;
          };
        };
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

      althaea = {name, ...}: {
        deployment = {
          allowLocalDeployment = true;

          keys."wireless.env" = {
            keyCommand = ["age" "--decrypt" "-i" "/home/marsh/key.txt" "secrets/wireless.env"];
            uploadAt = "pre-activation";
            destDir = "/etc/keys";
          };
        };

        imports = [
          ./nodes/${name}
          ./marsh
          home-manager.nixosModules.home-manager
          nixos-hardware.nixosModules.framework-13th-gen-intel
        ];
      };
    };
  };
}
