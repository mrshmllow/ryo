{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    candy.url = "github:mrshmllow/nvim-candy";
    wire.url = "github:wires-org/wire";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # star citizen
    nix-citizen.url = "github:LovingMelody/nix-citizen";
    nix-citizen.inputs.nix-gaming.follows = "nix-gaming";
    nix-gaming.url = "github:fufexan/nix-gaming";

    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    mac-app-util.url = "github:hraban/mac-app-util";

    umu.url = "github:Open-Wine-Components/umu-launcher?dir=packaging/nix";

    # other apps
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    typst-bot.url = "github:mattfbacon/typst-bot";
    typst-bot.flake = false;

    wezterm.url = "github:wez/wezterm/main?dir=nix";
    auto-cpufreq = {
      url = "github:AdnanHodzic/auto-cpufreq";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    nix-darwin,
    mac-app-util,
    nix-citizen,
    chaotic,
    self,
    ...
  }: let
    forAllSystems = nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-darwin"
      "i686-linux"
      "aarch64-linux"
    ];
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

    darwinConfigurations.macbook = nix-darwin.lib.darwinSystem {
      modules = [
        ./darwin/configuration.nix
        home-manager.darwinModules.home-manager
        mac-app-util.darwinModules.default
      ];
      specialArgs = {
        inherit inputs;
        nixpkgs = inputs.nixpkgs-darwin;
      };
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

    devShells = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = with pkgs;
            self.checks.${system}.pre-commit-check.enabledPackages
            ++ [
              colmena
              home-manager.packages.${system}.default
              #
            ]
            ++ (
              if system == "aarch64-darwin"
              then [
                nix-darwin.packages.${system}.default
              ]
              else []
            );
        };
      }
    );

    nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        nixos-wsl.nixosModules.default
        home-manager.nixosModules.home-manager
        ./marsh
        ./wsl
        ./nix.nix
        {nixpkgs.hostPlatform = "x86_64-linux";}
      ];
    };

    wire = inputs.wire.makeHive {
      inherit (self) nixosConfigurations;

      meta = {
        nixpkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
        };
        specialArgs = {inherit inputs;};
      };

      defaults = {
        pkgs,
        name,
        lib,
        config,
        ...
      }: {
        imports = [
          ./nix.nix
          ./modules
          nixos-cosmic.nixosModules.default
          home-manager.nixosModules.home-manager
          nix-minecraft.nixosModules.minecraft-servers
          nix-citizen.nixosModules.StarCitizen
          chaotic.nixosModules.default
        ];

        ryo.exporting_nodes = ["outpost-3"];
        ryo-network.tailscale.enable = true;

        services.prometheus.exporters = lib.mkIf (builtins.elem name config.ryo.exporting_nodes) {
          node = {
            enable = true;
            enabledCollectors = ["systemd"];
            port = 9002;
          };
        };
      };

      outpost-3 = {name, ...}: {
        deployment = {
          targetHost = "100.74.233.10";
          targetUser = "root";
          buildOnTarget = true;
        };

        nixpkgs.hostPlatform = "x86_64-linux";

        imports = [./nodes/${name}];
      };

      pi = {name, ...}: {
        deployment = {
          targetHost = "10.1.1.2";
          targetUser = "root";
        };

        nixpkgs.hostPlatform = "aarch64-linux";

        imports = [./nodes/${name}];
      };

      wsl = {
        nixpkgs.hostPlatform = "x86_64-linux";
      };

      maple = {name, ...}: {
        deployment = {
          targetHost = "maple";
          targetUser = "root";
          buildOnTarget = true;
          allowLocalDeployment = true;
        };

        nixpkgs.hostPlatform = "x86_64-linux";

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

        nixpkgs.hostPlatform = "x86_64-linux";

        imports = [
          ./nodes/${name}
          ./marsh
          home-manager.nixosModules.home-manager
          nixos-hardware.nixosModules.framework-12th-gen-intel
        ];
      };
    };
  };
}
