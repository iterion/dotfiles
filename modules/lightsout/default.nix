{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.iterion.lightsout;
in {
  options.iterion.lightsout = {
    enable = mkEnableOption "Enable the lightsout service.";
  };

  config = mkIf cfg.enable {
    systemd.services.lightsout = let
      python = pkgs.python3.withPackages (ppkgs: with ppkgs; [
        phue
      ]);
    in {
      description = "Lights out service enforces lightsout on hue bulbs";
      serviceConfig = {
        Type = "service";
        User = "iterion";
        ExecStart = "${python}/bin/python ${./lightsout.py}";
      };
    };
  };
}
