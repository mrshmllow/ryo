{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    # auto-cpufreq.nixosModules.default
  ];
  services.fwupd.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    age
    inputs.candy.packages.${pkgs.system}.default
    colmena

    vesktop
  ];

  networking.hostName = "althaea";
  networking.nameservers = ["1.1.1.1"];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # environment.sessionVariables.NIXOS_OZONE_WL = "1";

  nixpkgs.config.allowUnfree = true;

  nix.extraOptions = ''
    plugin-files = ${pkgs.nix-plugins}/lib/nix/plugins
  '';

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
    substituters = [
      "https://cache.nixos.org/"
      "https://cache.garnix.io"
      "https://devenv.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  virtualisation.docker.enable = true;

  services.power-profiles-daemon.enable = false;
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # lowLatency = {
    #   enable = true;
    #   # defaults (no need to be set unless modified)
    #   quantum = 64;
    #   rate = 48000;
    # };
  };

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

  # required for sway
  security.polkit.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd sway";
        user = "greeter";
      };
    };
  };

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

  services.printing.enable = true;

  programs.gamemode.enable = true;

  services.displayManager.autoLogin = {
    enable = true;
    user = "marsh";
  };

  services.tlp = {
    enable = true;
    settings = {
      # https://knowledgebase.frame.work/en_us/optimizing-ubuntu-battery-life-Sye_48Lg3
      INTEL_GPU_MIN_FREQ_ON_AC = 100;
      INTEL_GPU_MIN_FREQ_ON_BAT = 100;

      INTEL_GPU_MAX_FREQ_ON_AC = 1500;
      INTEL_GPU_MAX_FREQ_ON_BAT = 800;

      INTEL_GPU_BOOST_FREQ_ON_AC = 1500;
      INTEL_GPU_BOOST_FREQ_ON_BAT = 1000;

      WIFI_PWR_ON_AC = false;
      WIFI_PWR_ON_BAT = false;

      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";

      RUNTIME_PM_ON_AC = false;
      RUNTIME_PM_ON_BAT = true;

      GPU_SCALING_GOVERNOR_ON_AC = "performance";
      GPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 30;

      CPU_BOOST_ON_AC = true;
      CPU_BOOST_ON_BAT = true;

      CPU_HWP_DYN_BOOST_ON_AC = true;
      CPU_HWP_DYN_BOOST_ON_BAT = false;

      SCHED_POWERSAVE_ON_AC = false;
      SCHED_POWERSAVE_ON_BAT = true;

      NMI_WATCHDOG = false;

      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      USB_AUTOSUSPEND = true;
      USB_EXCLUDE_AUDIO = true;
      USB_EXCLUDE_BTUSB = true;
      USB_EXCLUDE_PHONE = true;
      USB_EXCLUDE_PRINTER = true;
      USB_EXCLUDE_WWAN = true;

      USB_AUTOSUSPEND_DISABLE_ON_SHUTDOWN = false;
    };
  };
  networking.wireless.enable = true;
  networking.wireless.networks."detnsw-a" = {
    auth = ''
      key_mgmt=WPA-EAP
      eap=PEAP
      phase2="auth=MSCHAPV2"
      identity="@DETNSW_IDENT@"
      password="@DETNSW_PASSWORD@"
    '';
  };
  networking.wireless.networks."the internet".psk = "@HOME_PSK@";
  networking.wireless.environmentFile = "/etc/keys/wireless.env";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.plymouth.enable = true;

  system.stateVersion = "23.05";
}
