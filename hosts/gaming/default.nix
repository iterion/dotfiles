{ pkgs, ... }:

{
  imports =
    [ 
      ../base
      ../desktop
      ./hardware-configuration.nix
    ];

  # Bootloader.
  # boot.loader.grub = {
  #   devices = [ "nodev" ];
  #   efiSupport = true;
  #   enable = true;
  #   extraEntries = ''
  #     menuentry "Windows" {
  #       insmod part_gpt
  #       insmod fat
  #       insmod search_fs_uuid
  #       insmod chain
  #       search --fs-uuid --set=root A9E3-668B
  #       chainloader /EFI/Microsoft/Boot/bootmgfw.efi
  #     }
  #   '';
  # };
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment = {
    systemPackages = with pkgs; [
      quickemu
      lm_sensors
    ];
  };

  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    steam = {
      enable = true;
      extest.enable = true;
    };
  };

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = [
    ];
  };
  networking.hostName = "iterion-gaming"; # Define your hostname.
 
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
