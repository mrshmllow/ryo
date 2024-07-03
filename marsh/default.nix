{
  pkgs,
  inputs,
  ...
}: {
  users.users.marsh = {
    isNormalUser = true;
    shell = pkgs.fish;
    description = "marsh";
    extraGroups = ["wheel" "docker"];
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
      fish_vi_key_bindings
    '';
  };

  environment.systemPackages = with pkgs; [
    wayland
    xdg-utils
    glib
    gnome3.adwaita-icon-theme
    wl-clipboard
    pamixer
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.marsh = import ../home;
  home-manager.extraSpecialArgs = {inherit inputs;};
}
