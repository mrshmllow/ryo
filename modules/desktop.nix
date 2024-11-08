{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  cfg = config.desktop;
in {
  options.desktop = {
    enable = lib.mkEnableOption "desktop computer";

    amd = lib.mkEnableOption "amdgpu";

    gnome.enable = lib.mkEnableOption "gnome desktop";
    sway.enable = lib.mkEnableOption "sway wm";
    cosmic.enable = lib.mkEnableOption "cosmic desktop";
    games.sc.enable = lib.mkEnableOption "star citizen";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home-manager.sharedModules = [
        {
          desktop.enable = true;
        }
      ];

      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      environment.systemPackages = with pkgs; [
        (google-chrome.override {
          commandLineArgs = [
            "--enable-features=VaapiVideoDecodeLinuxGL"
            "--ignore-gpu-blocklist"
            "--enable-zero-copy"
          ];
        })

        vesktop
        obsidian
        keepassxc
      ];

      nixpkgs.config.allowUnfree = true;

      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
      };
      programs.steam.gamescopeSession.enable = true;

      boot.plymouth.enable = true;

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      services.earlyoom.enable = true;

      fonts = {
        enableDefaultPackages = true;
        fontDir.enable = true;
        packages = with pkgs; [
          source-han-sans
          source-han-sans-japanese
          source-han-serif-japanese
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-emoji
          (nerdfonts.override {fonts = ["FiraCode" "JetBrainsMono"];})
        ];
        fontconfig = {
          defaultFonts = {
            monospace = ["JetBrainsMono"];
            serif = ["Noto Serif" "Source Han Serif"];
            sansSerif = ["Noto Sans" "Source Han Sans"];
          };
        };
      };
    })

    (lib.mkIf cfg.gnome.enable {
      # Enable the X11 windowing system.
      services.xserver.enable = true;

      # Enable the GNOME Desktop Environment.
      services.xserver.displayManager.gdm.enable = true;
      services.xserver.desktopManager.gnome.enable = true;

      environment.systemPackages = [pkgs.gnomeExtensions.appindicator pkgs.gnomeExtensions.clipboard-history];
    })

    (lib.mkIf cfg.cosmic.enable {
      services.desktopManager.cosmic.enable = true;
    })

    (lib.mkIf (cfg.gnome.enable
      || cfg.cosmic.enable
      || cfg.sway.enable) {
      hardware.pulseaudio.enable = lib.mkForce false;

      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        pulse.enable = true;
      };
    })

    (lib.mkIf cfg.games.sc.enable {
      programs.gamemode.enable = true;

      boot.kernel.sysctl = {
        "vm.max_map_count" = 16777216;
        "fs.file-max" = 524288;
      };

      environment.systemPackages = [
        (inputs.nix-gaming.packages.${pkgs.system}.star-citizen.override
          {
            useUmu = true;
          })
      ];
    })

    (lib.mkIf cfg.sway.enable {
      home-manager.sharedModules = [
        {
          desktop.sway.enable = true;
        }
      ];

      environment.systemPackages = with pkgs; [
        wayland
        xdg-utils
        glib
        adwaita-icon-theme
        wl-clipboard
        pamixer
        pavucontrol

        (pkgs.writeShellScriptBin "caffine" ''
          systemd-inhibit --what=idle --who=Caffine --why=Caffine --mode=block sleep inf
        '')
      ];

      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd sway";
            user = "greeter";
          };
        };
      };

      security.polkit.enable = true;

      programs.sway = {
        enable = true;
        package = pkgs.swayfx;
        wrapperFeatures.gtk = true;
      };

      xdg.portal = {
        enable = true;
        wlr.enable = true;
        # gtk portal needed to make gtk apps happy
        extraPortals = [pkgs.xdg-desktop-portal-gtk];
      };

      security.pam.loginLimits = [
        {
          domain = "@users";
          item = "rtprio";
          type = "-";
          value = 1;
        }
      ];
    })
  ];
}
