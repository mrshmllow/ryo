{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    wayland
    xdg-utils
    glib
    adwaita-icon-theme
    wl-clipboard
    pamixer

    (pkgs.writeShellScriptBin "caffine" ''
      systemd-inhibit --what=idle --who=Caffine --why=Caffine --mode=block sleep inf
    '')
  ];

  home-manager.users.marsh = {
    imports = [../home/wm];
  };
}
