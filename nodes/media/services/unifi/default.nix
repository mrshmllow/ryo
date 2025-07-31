{
  services.unifi = {
    enable = true;
    openFirewall = true;
  };

  media.subdomains."unifi".port = 8443;
  networking.firewall.allowedTCPPorts = [ 8443 ];

  nixpkgs.config.allowUnfree = true;
}
