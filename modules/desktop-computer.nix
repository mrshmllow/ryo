{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.desktop;
in {
  options.desktop = {
    enable = lib.mkEnableOption "desktop computer";

    amd = lib.mkEnableOption "amdgpu";

    gnome.enable = lib.mkEnableOption "gnome desktop";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      environment.systemPackages = with pkgs; [
        google-chrome

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
          noto-fonts-cjk
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

    (lib.mkIf cfg.amd {
      })

    (lib.mkIf cfg.gnome.enable {
      # Enable the X11 windowing system.
      services.xserver.enable = true;

      # Enable the GNOME Desktop Environment.
      services.xserver.displayManager.gdm.enable = true;
      services.xserver.desktopManager.gnome.enable = true;

      environment.systemPackages = [pkgs.gnomeExtensions.appindicator];

      hardware.pulseaudio.enable = lib.mkForce false;

      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        pulse.enable = true;
      };
    })
  ];
}
