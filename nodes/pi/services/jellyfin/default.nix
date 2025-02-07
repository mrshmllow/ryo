{
  services.jellyfin = {
    enable = true;
    dataDir = "/media/jellyfin";
    openFirewall = true;
  };
}
