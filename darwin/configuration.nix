{
  pkgs,
  inputs,
  lib,
  ...
}: {
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    builders-use-substitutes = true;
    extra-trusted-users = "marsh";
  };

  # nix.linux-builder = {
  #   enable = true;
  #   config = {
  #     nix.settings.sandbox = false;
  #   };
  #   ephemeral = true;
  #   package = inputs.nixpkgs-darwin.legacyPackages.${pkgs.system}.darwin.linux-builder;
  #   maxJobs = 4;
  #   # supportedFeatures = [
  #   #   "kvm"
  #   #   "benchmark"
  #   #   "big-parallel"
  #   #   "nixos-test"
  #   # ];
  # };

  users.users.marsh = {
    shell = pkgs.fish;
    home = "/Users/marsh";
    packages = with pkgs; [
      git
      inputs.candy.packages.${pkgs.system}.default
      uv
    ];
  };

  environment.systemPackages = with pkgs; [
    iterm2
    wezterm
    keepassxc
    neovide
  ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "Xcode.app"
    ];

  environment.variables.EDITOR = "nvim";

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
      fish_vi_key_bindings
      ulimit -S -n 40960
    '';
  };

  # environment.shellInit = ''
  #   ulimit -S -n 40960
  # '';

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = {inherit inputs;};

  home-manager.users.marsh = {...}: {
    imports = [../home];
    desktop.wezterm.enable = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  nix.package = pkgs.lix;

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
}
