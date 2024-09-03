{config, pkgs, lib, inputs, ...}: let
  wallpapers = (pkgs.callPackage ../../wallpapers { inherit pkgs; });
  cfg = config.iterion.desktop;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      wallpapers

      # toolbar
      waybar

      # some desktop libs & utils
      wlr-randr
      qt6.qtwayland
      libsForQt5.qt5.qtwayland
      gtk3
      gtk4

      #wayland screenshots
      inputs.hyprland-contrib.packages.${pkgs.system}.grimblast

      # wayland copy/paste
      wl-clipboard
    ];

    home.pointerCursor = {
      package = pkgs.vanilla-dmz;
      name = "Vanilla-DMZ";
      size = 48;
      gtk.enable = true;
    };
    qt = {
      enable = true;
    };
    gtk = {
      enable = true;
    };

    # notifications
    services.mako = {
      enable = true;
      extraConfig = ''
        on-button-right=dismiss-all
      '';
    };
    services.hyprpaper = {
      enable = true;
      package = inputs.hyprpaper.packages.${pkgs.system}.hyprpaper;
      settings = {
        ipc = "on";
        splash = false;

        preload = ["${wallpapers}/share/wallpapers/nix-wallpaper-binary-black.png"];

        wallpaper = [",${wallpapers}/share/wallpapers/nix-wallpaper-binary-black.png"];
      };
    };
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
        };
        listener = [
          {
            timeout = 5 * 60;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 6 * 60;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          disable_loading_bar = true;
          grace = 300;
          hide_cursor = true;
          no_fade_in = false;
        };
        background = [
          {
            path = "${wallpapers}/share/wallpapers/nix-wallpaper-binary-black.png";
            blur_passes = 1;
          }
        ];
        input-field = [
          {
            fade_on_empty = false;
            outline_thickness = 2;
            size = "300, 50";
          }
        ];
      };
    };
    wayland.windowManager.hyprland = {
      enable = true;
      package = pkgs.hyprland;
      xwayland.enable = true;
      systemd = {
        enable = true;
        variables = ["--all"];
      };
      settings = {
        "$mod" = "SUPER";
        monitor = [
          "eDP-1,1920x1080@144,0x0,1"
          "HDMI-A-3,3840x2160,1920x0,1.5"
        ];
        "debug:disable_logs" = false;
        "general:gaps_out" = 5;
        #"decoration:inactive_opacity" = 0.8;
        xwayland.force_zero_scaling = true;

        input = {
          kb_layout = "us";
          kb_variant = "dvorak";
        };
        env = [
          "WLR_NO_HARDWARE_CURSORS,1"
        ];
        exec-once = [
          "${pkgs.mako}/bin/mako"
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
          "${pkgs.waybar}/bin/waybar"
        ];
        device = [
          {
            name = "clearly-superior-technologies.-cst-laser-trackball";
            sensitivity = -0.5;
          }
        ];
        layerrule = [];
        bind =
          [
            "$mod, F, exec, ${pkgs.firefox}/bin/firefox"
            "$mod, Return, exec, ${pkgs.alacritty}/bin/alacritty"
            "$mod, D, exec, ${inputs.anyrun.packages.${pkgs.system}.anyrun}/bin/anyrun"
            "$mod, Left, movewindow, l"
            "$mod, Right, movewindow, r"
            "$mod SHIFT, Apostrophe, killactive,"
            "$mod SHIFT, S, exec, ${inputs.hyprland-contrib.packages.${pkgs.system}.grimblast}/bin/grimblast --notify copy area"
          ]
          ++ (
            # workspaces
            # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
            builtins.concatLists (builtins.genList (
                x: let
                  ws = let
                    c = (x + 1) / 10;
                  in
                    builtins.toString (x + 1 - (c * 10));
                in [
                  "$mod, ${ws}, workspace, ${toString (x + 1)}"
                  "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
                ]
              )
              10)
          );
      };
    };
  };
}
