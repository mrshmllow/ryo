{
  systemd.network = {
    enable = true;
    networks."internet" = {
      matchConfig = {
        MACAddress = "00:50:56:00:3a:39";
      };
      dns = [
        "1.1.1.1"
        "1.0.0.1"
      ];
      addresses = [
        { Address = "78.46.84.55/27"; }
      ];
      routes = [
        { Gateway = "78.46.84.33"; }
      ];
    };
  };

  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=tty1"
  ];
}
