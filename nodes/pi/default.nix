{
  name,
  nodes,
  pkgs,
  lib,
  modulesPath,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  networking.hostName = "pi";
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Australia/Sydney";

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO9FpVP2ZEPbjcibGlSI5cutue6aaiNNSH3syLFzrpbj marsh@marsh-framework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPRXTpL1qfcm78/eofQDdpMmquk/N8LqKh7tdMnXwbwT"
  ];

  nix.settings.auto-optimise-store = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.marsh = {
    isNormalUser = true;
    extraGroups = ["wheel"]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [];
  };

  environment.systemPackages = with pkgs; [
    neovim
  ];

  services.radarr = {
    enable = true;
    openFirewall = true;
    user = "marsh";
    group = "users  ";
  };

  services.sonarr = {
    enable = true;
    openFirewall = true;
    user = "marsh";
    group = "users";
  };

  services.deluge = {
    enable = true;
    user = "marsh";
    group = "users";
    web = {
      enable = true;
      openFirewall = true;
    };
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "marsh";
    group = "users";
  };

  services.jellyseerr = {
    enable = true;
    openFirewall = true;
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  services.postgresql = {
    enable = true;
    initialScript = pkgs.writeText "synapse-init.sql" ''
      CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
      CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
        TEMPLATE template0
        LC_COLLATE = "C"
        LC_CTYPE = "C";
    '';
  };

  services.matrix-synapse = {
    enable = true;
    extras = [
      "oidc"
    ];
    settings = {
      server_name = "althaea.zone";
      public_baseurl = "https://matrix.althaea.zone";
      url_preview_enabled = true;
      max_upload_size = "200M";
      enable_registration = false;
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."http://req.jerma.fans".extraConfig = ''
      reverse_proxy http://127.0.0.1:5055
    '';
    virtualHosts."http://jelly.jerma.fans".extraConfig = ''
      reverse_proxy http://127.0.0.1:8096
    '';

    virtualHosts."https://althaea.zone".extraConfig = ''
      header /.well-known/matrix/* Content-Type application/json
      header /.well-known/matrix/* Access-Control-Allow-Origin *
      respond /.well-known/matrix/server `{"m.server": "matrix.althaea.zone:443"}`
      respond /.well-known/matrix/client `{"m.homeserver":{"base_url":"https://matrix.althaea.zone"}}`

      tls /var/lib/caddy/althaea.zone.pem /var/lib/caddy/althaea.zone.key
    '';
    virtualHosts."https://matrix.althaea.zone".extraConfig = ''
      reverse_proxy /_matrix/* localhost:8008
      reverse_proxy /_synapse/client/* localhost:8008

      tls /var/lib/caddy/althaea.zone.pem /var/lib/caddy/althaea.zone.key
    '';
  };

  services.cfdyndns = {
    enable = true;
    apiTokenFile = "/run/secrets/cf_token";
    records = ["jelly.jerma.fans" "req.jerma.fans" "althaea.zone"];
  };

  services.openssh.enable = true;
  services.openssh.openFirewall = true;
  services.openssh.settings.PermitRootLogin = "yes";

  networking.firewall.allowedTCPPorts = [80 443 8448 5432];
  networking.firewall.allowedUDPPorts = [5432];

  system.stateVersion = "23.05";
}
