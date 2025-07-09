{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  desktop.enable = true;
  # desktop.sway.enable = true;
  desktop.gnome.enable = true;
  desktop.amd = true;
  desktop.apps.davinci-resolve.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # off until sway
  # ryo-network = {
  #   home.enable = true;
  # };

  # obs virtual camera
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.kernelModules = [
    "v4l2loopback"
    "amd_3d_vcache"
  ];

  services.postgresql.enable = true;

  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; [
    (pkgs.wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        obs-pipewire-audio-capture
      ];
    })

    mpv

    (opentrack.overrideAttrs (prev: {
      version = "wine-extended-proton";
      patches = [
        (pkgs.replaceVars ../../0001-test.patch {
          umu = lib.getExe' inputs.umu.packages.${pkgs.system}.umu "umu-run";
        })
      ];
      src = pkgs.fetchFromGitHub {
        owner = "Priton-CE";
        repo = "opentrack-StarCitizen";
        rev = "wine-extended-proton";
        hash = "sha256-xN4Z1Cpmj8ktqWCQYPZTfqznHrYe28qlKkPoQxHRPJ8=";
      };
    }))
  ];

  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  hardware.cpu.amd.updateMicrocode = true;

  # services.ollama = {
  #   enable = true;
  #   acceleration = "rocm";
  #   environmentVariables = {
  #     HSA_OVERRIDE_GFX_VERSION = "10.3.0";
  #   };
  # };
  #
  # services.open-webui = {
  #   enable = true;
  #   environment = {WEBUI_AUTH = "False";};
  # };

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
      size = builtins.floor (33 * 1024);
    }
  ];

  networking.hostName = "maple";

  time.timeZone = "Australia/Sydney";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.marsh = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "libvirtd"
    ]; # Enable ‘sudo’ for the user.
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
