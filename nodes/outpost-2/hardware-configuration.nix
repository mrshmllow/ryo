{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "ahci" "sd_mod" "sr_mod" "virtio_blk"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/063e1baa-b7a3-4ee0-8370-e52cc9cd50d2";
    fsType = "ext4";
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/95fcf6c3-438f-4dc9-92b5-2e68e5d85e80";}
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault false;

  networking = {
    nameservers = ["1.1.1.1" "8.8.8.8"];
    defaultGateway = "77.90.2.1";
    dhcpcd.enable = false;
    interfaces.ens3 = {
      ipv4.addresses = [
        {
          address = "77.90.2.117";
          prefixLength = 24;
        }
      ];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
