{ config, pkgs, ... }:

{
  imports =
    [ 
      ./shared-configuration.nix
      # Include the results of the hardware scan.
      ./corsair-hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
      devices = [ "nodev" ];
      efiSupport = true;
      enable = true;
      extraEntries = ''
        menuentry "Windows" {
          insmod part_gpt
          insmod fat
          insmod search_fs_uuid
          insmod chain
          search --fs-uuid --set=root A9E3-668B
          chainloader /EFI/Microsoft/Boot/bootmgfw.efi
        }
      '';
    };

  networking.hostName = "iterion-nixos"; # Define your hostname.
 
  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
      xfce = {
        enable = true;
	noDesktop = true;
	enableXfwm = false;
      };
      session = [
        {
          name = "xsession";
	  start = ''
	    ${pkgs.runtimeShell} $HOME/.xsession &
	    waitPID=$!
	  '';
	}
      ];
    };
    displayManager = {
      defaultSession = "xsession";
      gdm = {
        enable = true;
      };
    };
  };

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
