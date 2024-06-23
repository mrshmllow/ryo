{
  pkgs,
  lib,
  ...
}: {
  imports = [./sway.nix];

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
        modules-left = ["sway/workspaces" "sway/mode" "sway/scratchpad" "clock"];
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
}
