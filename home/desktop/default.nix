{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.iterion.desktop;
in {
  imports = [
    ./alacritty.nix
    ./waybar.nix
    ./hyprland.nix
    ./anyrun.nix
  ];

  options.iterion.desktop = {
    enable = mkEnableOption "Enable all desktop apps";
  };

  config = mkIf cfg.enable {
    xdg.enable = true;
    home.packages = with pkgs; [
      # desktop apps
      _1password
      _1password-gui
      discord
      firefox
      google-chrome
      obsidian
      slack
      spotify
      zed-editor
      zoom-us
    ];
  };
}
