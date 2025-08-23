{
  services.unifi = {
    enable = true;
    openFirewall = true;
  };

  server.backups.paths = [
    "/var/lib/unifi"
  ];

  media.subdomains."unifi".port = 8443;
  networking.firewall.allowedTCPPorts = [ 8443 ];

  nixpkgs.config.allowUnfree = true;
}
