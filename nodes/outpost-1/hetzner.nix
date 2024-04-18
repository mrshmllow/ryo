{
  name,
  nodes,
  pkgs,
  lib,
  modulesPath,
  config,
  ...
}: {
  networking = {
    nameservers = [
      "8.8.8.8"
    ];
    defaultGateway = "172.31.1.1";
    defaultGateway6 = {
      address = "";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          {
            address = "37.27.42.71";
            prefixLength = 32;
          }
        ];
        ipv6.addresses = [
          {
            address = "fe80::9400:3ff:fe36:5bff";
            prefixLength = 64;
          }
        ];
        ipv4.routes = [
          {
            address = "172.31.1.1";
            prefixLength = 32;
          }
        ];
      };
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="96:00:03:36:5b:ff", NAME="eth0"
  '';
  imports = [(modulesPath + "/profiles/qemu-guest.nix")];
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/D951-0FE6";
    fsType = "vfat";
  };
  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "xen_blkfront"];
  boot.initrd.kernelModules = ["nvme"];
  fileSystems."/" = {
    device = "/dev/sdb1";
    fsType = "ext4";
  };
  fileSystems."/mnt/meilisearch.jerma.fans" = {
    device = "/dev/disk/by-id/scsi-0HC_Volume_100608250";
    fsType = "ext4";
  };
  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = name;
  networking.domain = "";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsrE2dWjrj+nBTYrrfpVIaW6wxs3ClSDW3iKffD73p+'' ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE40+tAK8OFbutIMuGnbupORFJTtrW0weV6ke7rkvhCx''];
  system.stateVersion = "23.11";
}
