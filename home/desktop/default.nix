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
      _1password-cli
      _1password-gui
      aws-workspaces
      discord
      firefox
      obsidian
      slack
      spotify
      zed-editor
      zoom-us
      # orca-slicer
      gimp
      libva-utils
      vdpauinfo
      glib
      egl-wayland
      vulkan-tools
      (google-chrome.override {
        commandLineArgs = [
          "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks"
        ];
      })
    ];
  };
}
