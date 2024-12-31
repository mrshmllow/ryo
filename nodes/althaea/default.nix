{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    # auto-cpufreq.nixosModules.default
  ];

  desktop.enable = true;
  desktop.sway.enable = true;

  ryo-network = {
    home.enable = true;
  };

  services.fwupd.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    colmena
  ];

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  networking.hostName = "althaea";
  networking.nameservers = ["1.1.1.1"];

  programs.fuse.userAllowOther = true;

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Australia/Sydney";
  time.hardwareClockInLocalTime = true;

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  virtualisation.docker.enable = true;

  services.power-profiles-daemon.enable = false;

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

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "23.05";
}
