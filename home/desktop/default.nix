{
  pkgs,
  lib,
  ...
}: let
  makeRcloneMount = remotePath: localPath: {
    Unit = {
      After = ["network.target"];
      Wants = ["network.target"];
    };
    Service = {
      Type = "notify";
      ExecStartPre = "${lib.getExe' pkgs.coreutils "mkdir"} -p ${localPath}";
      ExecStart = "${lib.getExe pkgs.rclone} mount google-drive:${remotePath} ${localPath} --allow-other --log-level INFO";
      ExecStop = "${lib.getExe' pkgs.fuse "fusermount"} -u ${localPath}";
      Environment = ["PATH=/run/wrappers/bin/"];
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
in {
  imports = [./wezterm];

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3";
      package = pkgs.adw-gtk3;
    };
  };

  services.arrpc.enable = true;

  systemd.user.services.keepass = makeRcloneMount "/Keepass" "%h/.local/share/keepass";
  systemd.user.services.obsidian = makeRcloneMount "/obsidian" "%h/.local/share/obsidian";
}
