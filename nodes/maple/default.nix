{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  desktop.enable = true;
  desktop.gnome.enable = true;
  desktop.amd = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

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
  networking.networkmanager.enable = true;

  time.timeZone = "Australia/Sydney";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.marsh = {
    isNormalUser = true;
    extraGroups = ["wheel" "libvirtd"]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [];
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
