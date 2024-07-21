{
  pkgs,
  lib,
  ...
}: {
  imports = [./gpg.nix];

  programs.git = {
    enable = true;
    userName = "marshmallow";
    userEmail = "marshycity@gmail.com";
  };

  home.shellAliases = {
    G = ''nvim +"G" +":only"'';
  };

  programs.fish = {
    enable = true;
    plugins = [
      {
        name = "z";
        src = pkgs.fishPlugins.z.src;
      }
      {
        name = "pisces";
        src = pkgs.fishPlugins.pisces.src;
      }
      {
        name = "puffer";
        src = pkgs.fishPlugins.puffer.src;
      }
    ];
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    git = true;
    icons = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableTransience = true;

    settings = {
      # black, red, green, blue, yellow, purple, cyan, white
      format = ''\[$username@$hostname:$directory\]$character'';
      character = {
        success_symbol = "[\\$](bold purple)";
        error_symbol = "[\\$](bold red)";

        vimcmd_symbol = "[<](bold purple)";
        vimcmd_replace_one_symbol = "[<](bold red)";
        vimcmd_replace_symbol = "[<](bold red)";
        vimcmd_visual_symbol = "[<](bold cyan)";
      };
      username = {
        show_always = true;
        format = "[$user]($style)";
      };
      hostname = {
        ssh_only = false;
        format = "[$ssh_symbol$hostname]($style)";
      };
      directory = {
        format = "[$path]($style)[$read_only]($read_only_style)";
      };
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
