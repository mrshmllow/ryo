{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.desktop;

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

  makeRcloneMount = remotePath: localPath: {
    Unit = {
      After = ["network.target"];
      Wants = ["network.target"];
    };
    Service = {
      Type = "notify";
      ExecStartPre = "${lib.getExe' pkgs.coreutils "mkdir"} -p ${localPath}";
      ExecStart = "${lib.getExe pkgs.rclone} mount google-drive:${remotePath} ${localPath} --allow-other --log-level INFO --vfs-cache-mode full";
      ExecStop = "${lib.getExe' pkgs.fuse "fusermount"} -u ${localPath}";
      Environment = ["PATH=/run/wrappers/bin/"];
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
in {
  options.desktop = {
    enable = lib.mkEnableOption "desktop computer";
    sway.enable = lib.mkEnableOption "sway wm";

    wezterm.enable = lib.mkOption {
      default = cfg.enable;
      example = true;
      description = "Whether to enable wezterm.";
      type = lib.types.bool;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      gtk = {
        enable = true;
        theme = {
          name = "adw-gtk3";
          package = pkgs.adw-gtk3;
        };
      };

      services.arrpc.enable = true;

      services.gpg-agent = {
        enable = true;
        pinentryPackage = pkgs.pinentry-gnome3;
      };

      systemd.user.services.keepass = makeRcloneMount "/Keepass" "%h/.local/share/keepass";
      # systemd.user.services.obsidian = makeRcloneMount "/obsidian" "%h/.local/share/obsidian";
    })
    (lib.mkIf cfg.wezterm.enable {
      programs.wezterm = {
        enable = true;
        extraConfig = builtins.readFile ./wez-config.lua;
      };
    })
    (lib.mkIf cfg.sway.enable {
      services.mako = {
        enable = true;
        anchor = "bottom-right";
        # backgroundColor = "#1e1e2ecc";
        backgroundColor = "#1e1e2e";
        borderColor = "#cba6f7";
        textColor = "#cdd6f4";
        borderRadius = 8;
        borderSize = 2;
        margin = "6";
        font = "JetBrainsMono Nerd Font 10";
        extraConfig = ''
          [urgency=high]
          border-color=#f38ba8
        '';
      };
      home.pointerCursor = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
        size = 24;
        x11 = {
          enable = true;
          defaultCursor = "Adwaita";
        };
      };
      programs.swaylock = {
        enable = true;
        settings = {
          color = "1e1e2e";
          bs-hl-color = "f38ba8";
          inside-color = "313244";
          ring-color = "313244";
          inside-clear-color = "b4befe";
          ring-clear-color = "b4befe";
          inside-ver-color = "89b4fa";
          ring-ver-color = "89b4fa";
          inside-wrong-color = "f38ba8";
          ring-wrong-color = "f38ba8";
          key-hl-color = "cba6f7";
          line-color = "1e1e2e";
          text-caps-lock-color = "fab387";
        };
      };
      services.swayidle = let
        pause = "${lib.getExe pkgs.playerctl} pause";
        lock = "${lib.getExe pkgs.swaylock} -fF";
      in {
        enable = true;
        events = [
          {
            event = "before-sleep";
            command = pause;
          }
          {
            event = "before-sleep";
            command = lock;
          }
        ];
        timeouts = [
          {
            timeout = 60;
            command = "${pause}; ${lock}";
          }
          {
            timeout = 90;
            command = "${pkgs.systemd}/bin/systemctl suspend";
          }
        ];
      };
      programs.rofi = {
        enable = true;
        # theme = ./rofi.catppuccin-mocha.rasi;
        extraConfig = {
          modi = "run,drun,window";
          # icon-theme = "Oranchelo";
          show-icons = true;
          terminal = "kitty";
          drun-display-format = "{icon} {name}";
          location = 0;
          disable-history = false;
          hide-scrollbar = true;
          display-drun = "   Apps ";
          display-run = "   Run ";
          display-window = " 﩯  Window";
          display-Network = " 󰤨  Network";
          sidebar-mode = true;
        };
      };
      programs.fuzzel = {
        enable = true;
      };
      programs.waybar = {
        enable = true;
        settings = {
          top = {
            position = "top";
            height = 32;
            spacing = 4;
            modules-left = [
              "sway/workspaces"
              "sway/mode"
              "sway/scratchpad"
              "clock"
            ];
            "sway/mode" = {
              format = "<span style=\"italic\">{}</span>";
            };
            "sway/scratchpad" = {
              format = "<span color=\"#a6adc8\">STASH</span> {count}";
              show-empty = false;
              tooltip = true;
              tooltip-format = "{app}: {title}";
            };

            modules-center = [];
            clock = {
              format = " {:%a %b %e %I:%M %p} ";
              tooltip-format = "{:%m/%d/%Y %H:%M}";
            };

            modules-right = [
              "cpu"
              "custom/memory"
              # "custom/gpu-usage"
              # "custom/gpu-memory"
              "pulseaudio"
              "backlight"
              "custom/caffine"
              "network"
              "tray"
              "battery"
            ];
            cpu = {
              format = " <span color=\"#a6adc8\">CPU</span> {usage}% ";
              tooltip = false;
            };
            "custom/memory" = {
              exec = "free -h --si | grep Mem: | awk '{print $3}'";
              format = "<span color=\"#a6adc8\">MEM</span> {} ";
              return-type = "";
              interval = 1;
            };
            "custom/gpu-usage" = {
              exec = "cat /sys/class/hwmon/hwmon0/device/gpu_busy_percent";
              format = "<span color=\"#a6adc8\">GPU</span> {}% ";
              return-type = "";
              interval = 1;
            };
            "custom/gpu-memory" = {
              exec = "cat /sys/class/hwmon/hwmon0/device/mem_info_vram_used | numfmt --to=iec";
              format = "{} ";
              return-type = "";
              interval = 1;
            };
            "custom/caffine" = {
              exec = pkgs.writeShellScript "caffine" ''
                if [ $(systemd-inhibit --list | grep "Caffine" | wc -l) != "0" ]; then echo "INHIBIT "; fi
              '';
              interval = 10;
              format = "<span color=\"#a6adc8\">{}</span>";
            };
            pulseaudio = {
              format = "<span color=\"#a6adc8\">VOL</span> {volume}% ";
              format-muted = "<span color=\"#a6adc8\">MUTED</span>";

              format-bluetooth = "<span color=\"#a6adc8\">BT</span> {volume}% ";
              format-bluetooth-muted = "<span color=\"#a6adc8\">BT MUTED</span> ";

              on-click = "pavucontrol --tab=3";
            };
            backlight = {
              format = "<span color=\"#a6adc8\">BRT</span> {percent}% ";
              show-tooltip = false;
            };
            network = {
              format-wifi = "<span color=\"#a6adc8\">WIFI</span> {essid} ";
              format-ethernet = "<span color=\"#a6adc8\">WIRED</span> ";

              tooltip-format = "{ifname} via {gwaddr}";

              format-linked = "<span color=\"#a6adc8\">NO IP</span> {ifname} ";
              format-disconnected = "NO IP ";

              format-alt = "{ifname}: {ipaddr}/{cidr}";
            };
            battery = {
              format = "<span color=\"#a6adc8\">BAT</span> {capacity}% ";
              format-charging = "<span color=\"#a6adc8\">BAT+</span> {capacity}% ";
              format-plugged = "<span color=\"#a6adc8\">BAT~</span> {capacity}% ";
              tooltip-format = "{time}";
            };
            tray = {
              icon-size = 21;
              spacing = 10;
            };
          };
        };
        style = ''
          * {
              /* `otf-font-awesome` is required to be installed for icons */
              font-family: "JetBrainsMono Nerd Font", Roboto, Helvetica, Arial, sans-serif;
              font-size: 14px;
          }

          window#waybar {
              background-color: transparent;
              color: #cdd6f4;
          }

          window#waybar.hidden {
              opacity: 0.2;
          }

          button {
              border: none;
              border-radius: 0;
          }

          /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
          button:hover {
              background: inherit;
          }

          #workspaces button {
              padding: 0 5px;
              background-color: transparent;
              color: #a6adc8;
          }

          #workspaces button.focused {
              color: #cba6f7;
          }

          #workspaces button.urgent {
              color: #f38ba8;
          }

          modules-left, .modules-right, .modules-center, #workspaces {
            margin-left: 8px;
            margin-right: 8px;
          }

          modules-left, .modules-right, .modules-center, #workspaces, #clock {
            background-color: #1e1e2e;
            margin-bottom: 4px;
            margin-top: 4px;

            padding: 0px 0px;

            border-radius: 8px;
          }
        '';
      };

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
    })
  ];
}
