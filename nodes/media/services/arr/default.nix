{ pkgs, config, ... }:
{
  nixpkgs.config.permittedInsecurePackages = [
    "dotnet-sdk-6.0.428"
    "aspnetcore-runtime-6.0.36"
  ];

  server.backups.paths = [
    config.services.sonarr.dataDir
    config.services.radarr.dataDir
    config.services.prowlarr.dataDir
  ];

  services = {
    sonarr = {
      enable = true;
      openFirewall = true;
      package = pkgs.sonarr.overrideAttrs { doCheck = false; };
    };

    radarr = {
      enable = true;
      openFirewall = true;
    };

    prowlarr = {
      enable = true;
      openFirewall = true;
    };
  };

  media.subdomains = {
    "radarr".port = config.services.radarr.settings.server.port;
    "sonarr".port = config.services.sonarr.settings.server.port;
    "prowlarr".port = config.services.prowlarr.settings.server.port;
  };
}
