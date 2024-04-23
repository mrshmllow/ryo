{
  inputs,
  name,
  nodes,
  pkgs,
  lib,
  modulesPath,
  config,
  ...
}: {
  imports = [./hardware-configuration.nix ./networking.nix ./grafana.nix];

  nixpkgs.system = "aarch64-linux";

  nix.settings.sandbox = "relaxed";

  systemd.services.yard-search = {
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    description = "yard-search web server";
    environment = {
      NEXT_PUBLIC_MEILISEARCH_URL = "https://meilisearch.jerma.fans/";
      NEXT_PUBLIC_MEILISEARCH_KEY = "hellothisisakey";
    };
    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      ExecStart = lib.getExe inputs.yard-search.packages.aarch64-linux.yard-search;
      SyslogLevel = "debug";
    };
  };

  services.meilisearch = {
    enable = true;
    environment = "production";
    masterKeyEnvironmentFile = "/run/keys/meilimasterkey";
  };

  #fileSystems."/mnt/meilisearch" = {
  #  device = "/dev/disk/by-id/scsi-0HC_Volume_100641973";
  #  fsType = "ext4";
    # options = [ "bind" ];
  #};

  #systemd.tmpfiles.rules = [
#	"L+ /var/lib/meilisearch - - - - /mnt/meilisearch"
  #];

  systemd.services.meilisearch.environment = {
    #MEILI_DB_PATH = lib.mkForce "/mnt/meilisearch";
    #MEILI_DUMP_DIR = lib.mkForce "/mnt/meilisearch/dumps";
  };

  # systemd.services.meilisearch.serviceConfig.StateDirectory = lib.mkForce "meilisearch-state";

  users.users.root.openssh.authorizedKeys.keys = [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsrE2dWjrj+nBTYrrfpVIaW6wxs3ClSDW3iKffD73p+'' ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE40+tAK8OFbutIMuGnbupORFJTtrW0weV6ke7rkvhCx''];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = "outpost-1";
  networking.domain = "";
  services.openssh.enable = true;
  system.stateVersion = "23.11";
}
