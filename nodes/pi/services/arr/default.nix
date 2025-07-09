{ pkgs, ... }:
{
  nixpkgs.config.permittedInsecurePackages = [
    "dotnet-sdk-6.0.428"
    "aspnetcore-runtime-6.0.36"
  ];

  services.sonarr = {
    enable = true;
    openFirewall = true;
    package = pkgs.sonarr.overrideAttrs { doCheck = false; };
  };

  services = {
    radarr = {
      enable = true;
      openFirewall = true;
    };

    prowlarr = {
      enable = true;
      openFirewall = true;
    };
  };
}
