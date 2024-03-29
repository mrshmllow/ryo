{
  pkgs,
  config,
  lib,
  ...
}: {
  home.shellAliases = {
    cat = "bat";
    # ssh = "kitty +kitten ssh";
    tree = "eza --tree";
    gen_pdf = "pandoc --pdf-engine=xelatex -V geometry:margin=1in -V 'mainfont:DejaVu Serif' -V 'sansfont:DejaVu Sans' -V 'monofont:FiraCode Nerd Font'";
    # icat = "kitty +kitten icat";
    note = "vim -c ':lua require(\"orgmode.capture\"):new():open_template_by_shortcut(\"n\")' -c ':lua vim.api.nvim_win_close(1000, false)'";
    current = "vim ~/org/t3_32.org";
    refile = "vim ~/org/t3_32_refile.org";
  };
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting

      function fish_greeting
        if [ -z "$NVIM" ];
          ${lib.getExe' pkgs.krabby "krabby"} name marshadow --no-title
        end
      end

      fish_vi_key_bindings
    '';
    shellInit = ''
      ${lib.getExe pkgs.any-nix-shell} fish --info-right | source

      set fish_cursor_insert line

      set -x MANPAGER "${lib.getExe pkgs.neovim} -c 'Man!' -o -"
    '';
    functions = {
      pls = {
        body = ''
          if set -q argv[1]
            set cmd $argv[1]

            switch $cmd
              case 'test'
                  pushd ~/ryo
                  nixos-rebuild --use-remote-sudo test --flake
                  popd
              case 'update'
                  pushd ~/ryo
                  nix flake update
                  pls switch
                  popd
              case 'pi'
                  pushd ~/ryo
                  nixos-rebuild switch --flake .#pi --target-host root@pi --build-host root@pi --verbose --fast
                  popd
              case 'switch'
                  pushd ~/ryo
                  sudo nixos-rebuild --use-remote-sudo switch --flake .
                  popd
              case 'clean'
                  sudo nix-collect-garbage -d
                  nix store optimise
              case '*'
                  nix run nixpkgs#$cmd --
            end
          else
            echo "Error: No command or package provided"
            return 1
          end
        '';
      };
      catch_em_all = {
        body = ''
          while true
            ${lib.getExe' pkgs.krabby "krabby"} random
            sleep 1
          end
        '';
      };
    };
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
      {
        name = "fzf.fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
    ];
  };
  programs.bash = {
    enable = true;
    historyFile = "${config.xdg.dataHome}/bash/history";
    enableCompletion = true;
  };
}
