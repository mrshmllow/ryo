{
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./services
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "media"; # Define your hostname.

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
      53
    ];
    allowedUDPPorts = [ 53 ];
  };

  services.blocky = {
    enable = true;
    settings = {
      upstream.default = [
        "https://one.one.one.one/dns-query"
      ];
      bootstrapDns = {
        upstream = "https://one.one.one.one/dns-query";
        ips = [
          "1.1.1.1"
          "1.0.0.1"
        ];
      };
    };
  };

  services.caddy.enable = true;

  # Set your time zone.
  time.timeZone = "Australia/Sydney";

  # for jetkvm usb connection
  boot.loader.timeout = 25;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.marsh = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    password = "marsh";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPSvOZoSGVEpR6eTDK9OJ31MWQPF2s8oLc8J7MBh6nez marsh@maple"
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPSvOZoSGVEpR6eTDK9OJ31MWQPF2s8oLc8J7MBh6nez marsh@maple"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEf5PCchOeMbngf8Ta+4qErlwGcColab/aw+vOx7ZZu+ marsh@althaea"
  ];

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  system.stateVersion = "25.05"; # Did you read the comment?

}
