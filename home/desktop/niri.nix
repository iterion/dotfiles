{ config
, inputs
, lib
, pkgs
, ...
}:
let
  cfg = config.iterion.desktop;
  wallpapers = pkgs.callPackage ../../wallpapers { inherit pkgs; };
  system = pkgs.stdenv.hostPlatform.system;
  ashell = "${inputs.ashell.packages.${system}.default}/bin/ashell";
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      brightnessctl
      playerctl
      swaybg
    ];

    xdg.configFile."niri/config.kdl".text = ''
      input {
          keyboard {
              xkb {
                  layout "us"
                  variant "dvorak"
              }

              numlock
          }

          touchpad {
              tap
              natural-scroll
          }

          focus-follows-mouse max-scroll-amount="0%"
      }

      layout {
          gaps 8
          center-focused-column "on-overflow"

          preset-column-widths {
              proportion 0.33333
              proportion 0.5
              proportion 0.66667
              proportion 1.0
          }

          default-column-width { proportion 0.5; }

          focus-ring {
              width 3
              active-color "#3fb9a3"
              inactive-color "#59616b"
          }

          border {
              off
          }

          shadow {
              on
              softness 24
              spread 3
              offset x=0 y=4
              color "#0008"
          }
      }

      spawn-at-startup "${pkgs.swaybg}/bin/swaybg" "-i" "${wallpapers}/share/wallpapers/nix-wallpaper-binary-black.png" "-m" "fill"
      spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"

      hotkey-overlay {
          skip-at-startup
      }

      prefer-no-csd
      screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

      cursor {
          xcursor-theme "Vanilla-DMZ"
          xcursor-size 48
          hide-when-typing
      }

      blur {
          passes 2
          offset 3.0
          noise 0.02
          saturation 1.35
      }

      xwayland-satellite {
          path "${pkgs.xwayland-satellite}/bin/xwayland-satellite"
      }

      layer-rule {
          match namespace="^ashell-(menu|toast)-layer$"

          geometry-corner-radius 8

          background-effect {
              blur true
              noise 0.02
              saturation 1.35
          }

          shadow {
              on
              softness 24
              spread 3
              offset x=0 y=4
              color "#0008"
          }
      }

      window-rule {
          match app-id=r#"firefox$"# title="^Picture-in-Picture$"

          open-floating true
      }

      binds {
          Mod+Shift+Slash { show-hotkey-overlay; }

          Mod+Return hotkey-overlay-title="Open Terminal" { spawn "${pkgs.ghostty}/bin/ghostty"; }
          Mod+D hotkey-overlay-title="Run Launcher" { spawn "${pkgs.fuzzel}/bin/fuzzel"; }
          Mod+F hotkey-overlay-title="Open Firefox" { spawn "${pkgs.firefox}/bin/firefox"; }
          Mod+B hotkey-overlay-title="Toggle Bar" { spawn "${ashell}" "msg" "toggle-visibility"; }
          Super+Alt+L hotkey-overlay-title="Lock Screen" { spawn "${pkgs.hyprlock}/bin/hyprlock"; }

          XF86AudioRaiseVolume allow-when-locked=true { spawn "${ashell}" "msg" "volume-up"; }
          XF86AudioLowerVolume allow-when-locked=true { spawn "${ashell}" "msg" "volume-down"; }
          XF86AudioMute allow-when-locked=true { spawn "${ashell}" "msg" "volume-toggle-mute"; }
          XF86AudioMicMute allow-when-locked=true { spawn "${ashell}" "msg" "microphone-toggle-mute"; }

          XF86AudioPlay allow-when-locked=true { spawn "${pkgs.playerctl}/bin/playerctl" "play-pause"; }
          XF86AudioStop allow-when-locked=true { spawn "${pkgs.playerctl}/bin/playerctl" "stop"; }
          XF86AudioPrev allow-when-locked=true { spawn "${pkgs.playerctl}/bin/playerctl" "previous"; }
          XF86AudioNext allow-when-locked=true { spawn "${pkgs.playerctl}/bin/playerctl" "next"; }

          XF86MonBrightnessUp allow-when-locked=true { spawn "${ashell}" "msg" "brightness-up"; }
          XF86MonBrightnessDown allow-when-locked=true { spawn "${ashell}" "msg" "brightness-down"; }

          Mod+O repeat=false { toggle-overview; }
          Mod+Q repeat=false { close-window; }

          Mod+Left  { focus-column-left; }
          Mod+Down  { focus-window-down; }
          Mod+Up    { focus-window-up; }
          Mod+Right { focus-column-right; }
          Mod+H     { focus-column-left; }
          Mod+J     { focus-window-down; }
          Mod+K     { focus-window-up; }
          Mod+L     { focus-column-right; }

          Mod+Ctrl+Left  { move-column-left; }
          Mod+Ctrl+Down  { move-window-down; }
          Mod+Ctrl+Up    { move-window-up; }
          Mod+Ctrl+Right { move-column-right; }
          Mod+Ctrl+H     { move-column-left; }
          Mod+Ctrl+J     { move-window-down; }
          Mod+Ctrl+K     { move-window-up; }
          Mod+Ctrl+L     { move-column-right; }

          Mod+Shift+Left  { focus-monitor-left; }
          Mod+Shift+Down  { focus-monitor-down; }
          Mod+Shift+Up    { focus-monitor-up; }
          Mod+Shift+Right { focus-monitor-right; }
          Mod+Shift+H     { focus-monitor-left; }
          Mod+Shift+J     { focus-monitor-down; }
          Mod+Shift+K     { focus-monitor-up; }
          Mod+Shift+L     { focus-monitor-right; }

          Mod+Shift+Ctrl+Left  { move-column-to-monitor-left; }
          Mod+Shift+Ctrl+Down  { move-column-to-monitor-down; }
          Mod+Shift+Ctrl+Up    { move-column-to-monitor-up; }
          Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }
          Mod+Shift+Ctrl+H     { move-column-to-monitor-left; }
          Mod+Shift+Ctrl+J     { move-column-to-monitor-down; }
          Mod+Shift+Ctrl+K     { move-column-to-monitor-up; }
          Mod+Shift+Ctrl+L     { move-column-to-monitor-right; }

          Mod+Page_Down { focus-workspace-down; }
          Mod+Page_Up { focus-workspace-up; }
          Mod+U { focus-workspace-down; }
          Mod+I { focus-workspace-up; }
          Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
          Mod+Ctrl+Page_Up { move-column-to-workspace-up; }
          Mod+Ctrl+U { move-column-to-workspace-down; }
          Mod+Ctrl+I { move-column-to-workspace-up; }

          Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
          Mod+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }
          Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
          Mod+Ctrl+WheelScrollUp cooldown-ms=150 { move-column-to-workspace-up; }

          Mod+1 { focus-workspace 1; }
          Mod+2 { focus-workspace 2; }
          Mod+3 { focus-workspace 3; }
          Mod+4 { focus-workspace 4; }
          Mod+5 { focus-workspace 5; }
          Mod+6 { focus-workspace 6; }
          Mod+7 { focus-workspace 7; }
          Mod+8 { focus-workspace 8; }
          Mod+9 { focus-workspace 9; }
          Mod+Shift+1 { move-column-to-workspace 1; }
          Mod+Shift+2 { move-column-to-workspace 2; }
          Mod+Shift+3 { move-column-to-workspace 3; }
          Mod+Shift+4 { move-column-to-workspace 4; }
          Mod+Shift+5 { move-column-to-workspace 5; }
          Mod+Shift+6 { move-column-to-workspace 6; }
          Mod+Shift+7 { move-column-to-workspace 7; }
          Mod+Shift+8 { move-column-to-workspace 8; }
          Mod+Shift+9 { move-column-to-workspace 9; }

          Mod+BracketLeft  { consume-or-expel-window-left; }
          Mod+BracketRight { consume-or-expel-window-right; }
          Mod+Comma { consume-window-into-column; }
          Mod+Period { expel-window-from-column; }

          Mod+R { switch-preset-column-width; }
          Mod+Shift+R { switch-preset-column-width-back; }
          Mod+Ctrl+R { reset-window-height; }
          Mod+Ctrl+Shift+R { switch-preset-window-height; }

          Mod+M { maximize-column; }
          Mod+Shift+F { fullscreen-window; }
          Mod+Ctrl+F { expand-column-to-available-width; }
          Mod+C { center-column; }
          Mod+Ctrl+C { center-visible-columns; }

          Mod+Minus { set-column-width "-10%"; }
          Mod+Equal { set-column-width "+10%"; }
          Mod+Shift+Minus { set-window-height "-10%"; }
          Mod+Shift+Equal { set-window-height "+10%"; }

          Mod+V { toggle-window-floating; }
          Mod+Shift+V { switch-focus-between-floating-and-tiling; }
          Mod+W { toggle-column-tabbed-display; }

          Print { screenshot; }
          Ctrl+Print { screenshot-screen; }
          Alt+Print { screenshot-window; }
          Mod+Shift+S { screenshot; }

          Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
          Mod+Shift+E { quit; }
          Ctrl+Alt+Delete { quit; }
          Mod+Shift+P { power-off-monitors; }
      }
    '';
  };
}
