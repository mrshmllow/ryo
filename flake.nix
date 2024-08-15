{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    candy.url = "github:mrshmllow/nvim-candy";
    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      flake = false;
    };
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.lix.follows = "lix";
    };
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
  };

  outputs = inputs @ {
    flake-parts,
    home-manager,
    nixpkgs,
    nixos-hardware,
    pre-commit-hooks,
    lix-module,
    nix-minecraft,
    nixos-wsl,
    self,
    ...
  }: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "x86_64-darwin" "i686-linux" "aarch64-linux"];
  in {
    homeConfigurations.marsh = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      extraSpecialArgs = {inherit inputs;};
      modules = [
        ./home
        {
          home.homeDirectory = "/home/marsh";
        }
      ];
    };

    packages = forAllSystems (system: {
      lix = lix-module.packages.${system}.default;
    });

    checks = forAllSystems (system: {
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          alejandra.enable = true;
          luacheck.enable = true;
        };
      };
    });

    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        buildInputs = with pkgs;
          self.checks.${system}.pre-commit-check.enabledPackages
          ++ [
            colmena
            home-manager.packages.${system}.default
            (writeShellScriptBin "apply-local" ''${lib.getExe colmena} apply-local -v --sudo "$@"'')
            (writeShellScriptBin "apply-hm" ''${lib.getExe home-manager.packages.${system}.default} switch --flake .'')
          ];
      };
    });

    nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        nixos-wsl.nixosModules.default
        home-manager.nixosModules.home-manager
        lix-module.nixosModules.default
        ./marsh
        ./wsl
        ./nix.nix
      ];
    };

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
        config,
        ...
      }: let
        exporting_nodes = ["outpost-2" "pi"];
      in {
        imports = [
          lix-module.nixosModules.default
          ./nix.nix
        ];

        system.activationScripts.diff = {
          supportsDryActivation = true;
          text = ''
            if [ -e /run/current-system ]; then
              PATH=${lib.makeBinPath [config.nix.package]} \
                ${lib.getExe pkgs.nvd} \
                diff /run/current-system $systemConfig
            fi
          '';
        };

        services.tailscale = {
          enable = false;
          authKeyFile = "/run/keys/tailscale.key";
          permitCertUid = "caddy";
          extraUpFlags = ["--ssh"];
        };

        deployment.keys."tailscale.key" = {
          keyCommand = ["gpg" "--decrypt" "${./secrets/tailscale.key.gpg}"];

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

      minecraft-server = {name, ...}: {
        deployment = {
          targetHost = "154.26.156.106";
          targetUser = "root";
          buildOnTarget = true;
        };

        imports = [./nodes/${name} nix-minecraft.nixosModules.minecraft-servers];
      };

      althaea = {name, ...}: {
        deployment = {
          allowLocalDeployment = true;

          keys."wireless.env" = {
            keyCommand = ["gpg" "--decrypt" "${./secrets/wireless.env.gpg}"];
            uploadAt = "pre-activation";
            destDir = "/etc/keys";
          };
        };

        imports = [
          ./nodes/${name}
          ./marsh
          ./marsh/desktop.nix
          home-manager.nixosModules.home-manager
          nixos-hardware.nixosModules.framework-13th-gen-intel
        ];
      };
    };
  };
}
