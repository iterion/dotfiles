{pkgs, ...}: {
  home.packages = with pkgs; [
    helvum
    coppwr
  ];
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        output = [
          "eDP-1"
          "HDMI-A-3"
        ];
        modules-left = ["hyprland/workspaces"];
        modules-center = ["hyprland/window"];
        modules-right = ["idle_inhibitor" "cpu" "temperature" "wireplumber" "clock" "tray"];

        "hyprland/workspaces" = {
          all-outputs = true;
        };
        "hyprland/window" = {
          "separate-outputs" = true;
        };
        clock = {
          format = "{:%H:%M}  ";
          format-alt = "{:%Y-%m-%d %R}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
            on-click-forward = "tz_up";
            on-click-backward = "tz_down";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };
        wireplumber = {
          format = "{volume}% {icon}";
          format-muted = "";
          on-click = "coppwr";
          format-icons = ["" "" ""];
        };
      };
    };
  };
}
