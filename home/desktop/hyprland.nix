{ config
, pkgs
, lib
, inputs
, ...
}:
let
  wallpapers = pkgs.callPackage ../../wallpapers { inherit pkgs; };
  cfg = config.iterion.desktop;
  system = pkgs.stdenv.hostPlatform.system;
  uwsm = "${pkgs.uwsm}/bin/uwsm";
  ashell = "${inputs.ashell.packages.${system}.default}/bin/ashell";
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      wallpapers

      # some desktop libs & utils
      wlr-randr
      qt6.qtwayland
      libsForQt5.qt5.qtwayland
      gtk3
      gtk4

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
      gtk4.theme = config.gtk.theme;
      iconTheme = {
        name = "Pop";
        package = pkgs.pop-icon-theme;
      };
      theme = {
        name = "Pop";
        package = pkgs.pop-gtk-theme;
      };
    };

    services.hyprpaper = {
      enable = true;
      package = inputs.hyprpaper.packages.${system}.hyprpaper;
      settings = {
        ipc = "on";
        splash = false;

        preload = [ "${wallpapers}/share/wallpapers/nix-wallpaper-binary-black.png" ];

        wallpaper = [ ",${wallpapers}/share/wallpapers/nix-wallpaper-binary-black.png" ];
      };
    };
    systemd.user.services.hyprpaper.Install.WantedBy = lib.mkForce [ ];
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
    systemd.user.services.hypridle.Install.WantedBy = lib.mkForce [ ];
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
      configType = "hyprlang";
      xwayland.enable = true;
      systemd.enable = false;
      settings = {
        "$mod" = "SUPER";
        "debug:disable_logs" = false;
        "general:gaps_out" = 5;
        #"decoration:inactive_opacity" = 0.8;
        xwayland.force_zero_scaling = true;

        input = {
          kb_layout = "us";
          kb_variant = "dvorak";
        };
        cursor = {
          no_hardware_cursors = true;
        };
        exec-once = [
          "${pkgs.systemd}/bin/systemctl --user start hyprpaper.service"
          "${pkgs.systemd}/bin/systemctl --user start hypridle.service"
          "${uwsm} app -- ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        ];
        layerrule = [
          "blur on, match:namespace ashell-menu-layer"
          "blur on, match:namespace ashell-toast-layer"
          "ignore_alpha 0.01, match:namespace ashell-menu-layer"
          "ignore_alpha 0.01, match:namespace ashell-toast-layer"
        ];
        bind =
          [
            "$mod, C, sendshortcut, CTRL, C, class:(google-chrome)"
            "$mod, V, sendshortcut, CTRL, V, class:(google-chrome)"
            "$mod, X, sendshortcut, CTRL, X, class:(google-chrome)"
            "$mod, C, sendshortcut, CTRL_SHIFT, C, class:(Alacritty)"
            "$mod, V, sendshortcut, CTRL_SHIFT, V, class:(Alacritty)"
            "$mod, X, sendshortcut, CTRL_SHIFT, X, class:(Alacritty)"
            "$mod, F, exec, ${uwsm} app -- ${pkgs.firefox}/bin/firefox"
            "$mod, Return, exec, ${uwsm} app -- com.mitchellh.ghostty.desktop"
            "$mod, D, exec, ${uwsm} app -- ${pkgs.fuzzel}/bin/fuzzel"
            "$mod, B, exec, ${ashell} msg toggle-visibility"
            "$mod, Left, movewindow, l"
            "$mod, Right, movewindow, r"
            "$mod SHIFT, Apostrophe, killactive,"
            "$mod SHIFT, S, exec, ${uwsm} app -- ${pkgs.flameshot}/bin/flameshot gui"
          ]
          ++ (
            # workspaces
            # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
            builtins.concatLists (builtins.genList
              (
                x:
                let
                  ws =
                    let
                      c = (x + 1) / 10;
                    in
                    builtins.toString (x + 1 - (c * 10));
                in
                [
                  "$mod, ${ws}, workspace, ${toString (x + 1)}"
                  "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
                ]
              )
              10)
          );
        bindel = [
          ", XF86AudioRaiseVolume, exec, ${ashell} msg volume-up"
          ", XF86AudioLowerVolume, exec, ${ashell} msg volume-down"
          ", XF86MonBrightnessUp, exec, ${ashell} msg brightness-up"
          ", XF86MonBrightnessDown, exec, ${ashell} msg brightness-down"
        ];
        bindl = [
          ", XF86AudioMute, exec, ${ashell} msg volume-toggle-mute"
          ", XF86AudioMicMute, exec, ${ashell} msg microphone-toggle-mute"
          ", XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause"
          ", XF86AudioStop, exec, ${pkgs.playerctl}/bin/playerctl stop"
          ", XF86AudioPrev, exec, ${pkgs.playerctl}/bin/playerctl previous"
          ", XF86AudioNext, exec, ${pkgs.playerctl}/bin/playerctl next"
        ];
      };
    };
  };
}
