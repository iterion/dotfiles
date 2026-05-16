{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.iterion.desktop;
in {
  imports = [
    ./alacritty.nix
    ./waybar.nix
    ./hyprland.nix
  ];

  options.iterion.desktop = {
    enable = mkEnableOption "Enable all desktop apps";
    awsWorkspaces.enable = mkEnableOption "Install the AWS WorkSpaces client";
  };

  config = mkIf cfg.enable {
    xdg.enable = true;
    programs.fuzzel = {
      enable = true;
      settings = {
        main = {
          font = "JetBrainsMono Nerd Font:size=13";
          terminal = "${pkgs.ghostty}/bin/ghostty";
          layer = "overlay";
        };
      };
    };
    services.flameshot = {
      enable = true;
      settings.General = {
        showStartupLaunchMessage = false;
      };
    };
    home.packages = with pkgs;
      [
        # desktop apps
        _1password-cli
        _1password-gui
        discord
        firefox
        obsidian
        slack
        spotify
        zed-editor
        zoom-us
        prusa-slicer
        # orca-slicer
        gimp
        libva-utils
        glib
        egl-wayland
        vulkan-tools
        google-chrome
      ]
      ++ optionals cfg.awsWorkspaces.enable [
        pkgs.aws-workspaces
      ];
  };
}
