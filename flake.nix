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
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    nix-gaming.url = "github:fufexan/nix-gaming";
    umu.follows = "nix-gaming";
    wezterm.url = "github:wez/wezterm/main?dir=nix";
  };

  outputs = inputs @ {
    flake-parts,
    home-manager,
    nixpkgs,
    nixos-hardware,
    pre-commit-hooks,
    nix-minecraft,
    nixos-wsl,
    nixos-cosmic,
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
        exporting_nodes = ["outpost-2" "pi" "mc"];
      in {
        imports = [
          ./nix.nix
          ./modules
          nixos-cosmic.nixosModules.default
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
          enable = true;
          authKeyFile = config.deployment.keys."tailscale.key".path;
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

      outpost-3 = {name, ...}: {
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

      mc = {name, ...}: {
        deployment = {
          targetHost = "154.26.156.55";
          targetUser = "root";
          buildOnTarget = true;
        };

        imports = [
          ./nodes/minecraft-server-f
          nix-minecraft.nixosModules.minecraft-servers
          home-manager.nixosModules.home-manager
        ];
      };

      maple = {name, ...}: {
        deployment = {
          targetHost = "maple";
          targetUser = "root";
          buildOnTarget = true;
          allowLocalDeployment = true;
        };

        imports = [
          ./nodes/${name}
          ./marsh
          home-manager.nixosModules.home-manager
        ];
      };

      althaea = {name, ...}: {
        deployment = {
          allowLocalDeployment = true;
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
