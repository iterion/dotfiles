{ lib, ... }:

with lib;

{
  options.iterion.work = {
    enable = mkEnableOption "Enable work packages";
  };
}
