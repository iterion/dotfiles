{config, lib, pkgs, ...}: let
  cfg = config.iterion.fpv;
in {
  options.iterion.fpv = {
    enable = lib.mkEnableOption "Enable all FPV apps";
  };
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      betaflight-configurator
    ];
  };
}
