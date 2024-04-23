{ lib, ... }: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [ "8.8.8.8"];
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
          { address="37.27.42.71"; prefixLength=32; }
        ];
        ipv6.addresses = [
          { address="fe80::9400:3ff:fe3c:8ae3"; prefixLength=64; }
        ];
        ipv4.routes = [ { address = "172.31.1.1"; prefixLength = 32; } ];
        # ipv6.routes = [ { address = ""; prefixLength = 128; } ];
      };

    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="96:00:03:3c:8a:e3", NAME="eth0"
  '';
}
