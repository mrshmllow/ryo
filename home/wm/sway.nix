{
  pkgs,
  lib,
  ...
}: let
  dbus-sway-environment = pkgs.writeTextFile {
    name = "dbus-sway-environment";
    destination = "/bin/dbus-sway-environment";
    executable = true;

    text = ''
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
      systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };

  configure-gtk = pkgs.writeTextFile {
    name = "configure-gtk";
    destination = "/bin/configure-gtk";
    executable = true;
    text = let
      schema = pkgs.gsettings-desktop-schemas;
      datadir = "${schema}/share/gsettings-schemas/${schema.name}";
      # What is this doing?
    in ''
      export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
      gnome_schema=org.gnome.desktop.interface
    '';
    # gsettings set $gnome_schema gtk-theme 'Dracula'
  };
in {
  wayland.windowManager.sway = {
    enable = true;
    package = null;
    checkConfig = false;
    config = {
      workspaceAutoBackAndForth = true;
      assigns = {
        "1" = [
          {
            class = "^Google-chrome$";
          }
        ];
        "3" = [
          {
            class = "^vesktop$";
          }
        ];
        "5" = [
          {
            class = "^steam$";
          }
        ];
      };
      floating = {
        criteria = [
          {
            class = "Rofi";
          }
          {
            app_id = "pavucontrol";
          }
        ];
      };
      gaps = let
        outer = 2;
      in {
        top = outer;
        horizontal = outer;
        bottom = 0;

        inner = 0;
        smartBorders = "on";
        smartGaps = true;
      };
      input = {
        "5426:125:Razer_Razer_DeathAdder_V2_Pro" = {
          accel_profile = "flat";
          pointer_accel = ".5";
        };
        "type:touchpad" = {
          natural_scroll = "enabled";
          tap = "enabled";
        };
      };
      # menu = "${lib.getExe pkgs.rofi} -normal-window -show drun";
      menu = "${lib.getExe pkgs.rofi} -normal-window -show drun";
      modifier = "Mod4";
      output = let
        bg = ../wallpaper.jpg;
      in {
        DP-2 = {
          mode = "1920x1080@144.001Hz";
          bg = "${bg} fill";
        };
        eDP-1 = {
          mode = "2256x1504@59.99Hz";
          bg = "${bg} fill";
        };
      };
      startup = [
        {command = "${dbus-sway-environment}";}
        {command = "${configure-gtk}";}
        {command = "${lib.getExe pkgs.autotiling-rs}";}
      ];
      terminal = "wezterm";
      window = {
        titlebar = false;
      };
      keybindings = let
        pactl = lib.getExe' pkgs.pulseaudio "pactl";
      in
        lib.mkOptionDefault {
          "Mod4+Shift+s" = ''exec IMG=~/Pictures/$(date +%Y-%m-%d_%H-%m-%s).png && ${lib.getExe pkgs.grim} -g "$(${lib.getExe pkgs.slurp})" $IMG && ${lib.getExe' pkgs.wl-clipboard "wl-copy"} < $IMG'';
          "Mod4+n" = ''exec neovide'';

          "XF86AudioRaiseVolume" = ''exec ${pactl} set-sink-volume @DEFAULT_SINK@ +5%'';
          "XF86AudioLowerVolume" = ''exec ${pactl} set-sink-volume @DEFAULT_SINK@ -5%'';
          "XF86AudioMute" = ''exec ${pactl} set-sink-mute @DEFAULT_SINK@ toggle'';

          "XF86AudioPlay" = ''exec ${lib.getExe pkgs.playerctl} play-pause'';
          "XF86AudioNext" = ''exec ${lib.getExe pkgs.playerctl} next'';
          "XF86AudioPrev" = ''exec ${lib.getExe pkgs.playerctl} previous'';

          "XF86MonBrightnessDown" = ''exec ${lib.getExe pkgs.brightnessctl} set 5%-'';
          "XF86MonBrightnessUp" = ''exec ${lib.getExe pkgs.brightnessctl} set +5%'';
        };
      bars = [
        {
          command = "${lib.getExe pkgs.waybar}";
        }
      ];
      colors = {
        focused = {
          text = "#1e1e2e";

          background = "#cba6f7";
          border = "#cba6f7";

          childBorder = "#cba6f7";

          indicator = "#6c7086";
        };
        unfocused = {
          text = "#cdd6f4";

          background = "#1e1e2e";
          border = "#1e1e2e";

          childBorder = "#1e1e2e";

          indicator = "#6c7086";
        };
      };
    };
    extraConfig = ''
      bindgesture swipe:right workspace prev
      bindgesture swipe:left workspace next

      layer_effects "notifications" blur disable; shadows disable;
      layer_effects "waybar" blur enable;

      blur enable
      corner_radius 10
      shadows enable
    '';
  };
}
