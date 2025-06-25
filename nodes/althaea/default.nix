{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    inputs.auto-cpufreq.nixosModules.default
  ];

  desktop.enable = true;
  desktop.gnome.enable = true;

  ryo-network = {
    tailscale.enable = true;
    # home.enable = true;
  };

  services.fwupd.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    colmena
  ];

  # boot.kernelPackages = pkgs.linuxPackages_cachyos;
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_14;

  # virtualisation.libvirtd.enable = true;
  # programs.virt-manager.enable = true;
  networking.hostName = "althaea";
  networking.nameservers = ["1.1.1.1"];

  programs.fuse.userAllowOther = true;

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Australia/Sydney";
  time.hardwareClockInLocalTime = true;

  # boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  virtualisation.docker.enable = true;

  services.printing.enable = true;

  programs.gamemode.enable = true;

  services.displayManager.autoLogin = {
    enable = true;
    user = "marsh";
  };

  # https://knowledgebase.frame.work/en_us/optimizing-ubuntu-battery-life-Sye_48Lg3
  services.power-profiles-daemon.enable = false;
  programs.auto-cpufreq.enable = true;
  services.tlp.enable = false;

  powerManagement.powertop.enable = true;
  services.thermald.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "23.05";
}
