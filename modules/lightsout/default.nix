{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.lightsout;
  python = pkgs.python3.withPackages (ppkgs: with ppkgs; [
    phue
  ]);
in {
  options.services.lightsout = {
    enable = mkEnableOption "Enable the lightsout service.";
  };

  config = mkIf cfg.enable {
    systemd.timers.lightsout = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "10s";
        OnUnitActiveSec = "10s";
        Unit = "lightsout.service";
      }; 
    };
    systemd.services.lightsout = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Lights out service enforces lightsout on hue bulbs";
      script = ''
        ${python}/bin/python ${./lightsout.py}
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
  };
}
