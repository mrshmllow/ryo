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

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.marsh = {
    imports = [../home];
  };

  home-manager.extraSpecialArgs = {inherit inputs;};
}
