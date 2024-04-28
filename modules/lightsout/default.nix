{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.lightsout;
in {
  options.services.lightsout = {
    enable = mkEnableOption "Enable the lightsout service.";
  };

  config = mkIf cfg.enable {
    systemd.services.lightsout = let
      python = pkgs.python3.withPackages (ppkgs: with ppkgs; [
        phue
      ]);
    in {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Lights out service enforces lightsout on hue bulbs";
      script = ''
        ${python}/bin/python ${./lightsout.py}
      '';
      serviceConfig = {
        Restart = "always";
        User = "nobody";
      };
    };
  };
}
