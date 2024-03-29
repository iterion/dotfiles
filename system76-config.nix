{ config, pkgs, ... }:

{
  imports =
    [ 
      ./shared-configuration.nix
      # Include the results of the hardware scan.
      ./system76-hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "system76-nixos";

  boot.initrd.luks.devices."luks-bcdc740f-7023-4bb5-982f-081db97f671f".device = "/dev/disk/by-uuid/bcdc740f-7023-4bb5-982f-081db97f671f";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix = {
    package = pkgs.nixFlakes;
  };
}
