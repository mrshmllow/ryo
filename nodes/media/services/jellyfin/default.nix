{
  pkgs,
  lib,
  ...
}:
let
  domain = "jellyfin.local";
in
{
  services.jellyfin = {
    enable = true;
    logDir = "/storage/jellyfin-logs";
    cacheDir = "/storage/jellyfin-cache";
    openFirewall = true;
  };

  # Transcoding
  systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  # CPU is 6th generation.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # For Broadwell (2014) or newer processors. LIBVA_DRIVER_NAME=iHD
      libva-vdpau-driver # Previously vaapiVdpau
      # intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      # OpenCL support for intel CPUs before 12th gen
      # see: https://github.com/NixOS/nixpkgs/issues/356535
      intel-compute-runtime-legacy1
      # intel-media-sdk # QSV up to 11th gen
      intel-ocl # OpenCL support
    ];
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "intel-ocl"
    ];

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    reverse_proxy :8096
    tls internal
  '';

  services.blocky.settings.customDNS.mapping = {
    ${domain} = "10.1.1.117";
  };
}
