{pkgs, lib, ...}: {
  imports = [./wm];

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3";
      package = pkgs.adw-gtk3;
    };
  };

  systemd.user.services.keepass = {
    Unit = {
        After = ["network.target"];
        Wants = ["network.target"];
    };
    Service = {
        Type = "notify";
        ExecStartPre = "${lib.getExe' pkgs.coreutils "mkdir"} -p %h/.local/share/keepass";
        ExecStart = "${lib.getExe pkgs.rclone} mount google-drive:/Keepass %h/.local/share/keepass --allow-other --log-level INFO";
        ExecStop = "${lib.getExe' pkgs.fuse "fusermount"} -u %h/.local/share/keepass";
        Environment = [ "PATH=/run/wrappers/bin/" ];
    };
    Install = {
        WantedBy = ["default.target"];
    };
  };
}
