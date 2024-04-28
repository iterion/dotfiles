{ config, lib, ... }: let
  cfg = config.iterion.desktop;
in {
  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        font.normal = {
          family = "FiraCode Nerd Font";
          style = "Regular";
        };
      };
    };
  };
}
