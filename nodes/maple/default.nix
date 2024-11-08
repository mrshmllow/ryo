{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  desktop.enable = true;
  desktop.sway.enable = true;
  desktop.amd = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  ryo-network = {
    home.enable = true;
    det.enable = true;
  };

  # obs virtual camera
  boot.extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];
  boot.kernelModules = [
    "v4l2loopback"
  ];

  boot.kernelPackages = pkgs.linuxPackages_xanmod;
  desktop.games.sc.enable = true;

  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;
  programs.virt-manager.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  programs.fuse.userAllowOther = true;

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = builtins.floor (33 * 1.5 * 1024);
    }
  ];

  networking.hostName = "maple";

  time.timeZone = "Australia/Sydney";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.marsh = {
    isNormalUser = true;
    extraGroups = ["wheel" "libvirtd"]; # Enable ‘sudo’ for the user.
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
