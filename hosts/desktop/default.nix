{
  pkgs,
  lib,
  ...
}: {
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  boot = {
    plymouth = {
      enable = true;
      theme = "breeze";
    };
  };

  environment = {
    systemPackages = with pkgs; [
      polkit_gnome
    ];
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  programs = {
    dconf.enable = true;
    seahorse.enable = true;
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = ["iterion"];
    };
    # file picker
    xfconf.enable = true;
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };
  security.rtkit.enable = true;

  services = {
    gvfs.enable = true;
    tumbler.enable = true;
    blueman.enable = true;
    dbus = {
      enable = true;
      packages = [pkgs.gnome.seahorse];
    };
    gnome.gnome-keyring.enable = true;
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = ''
            ${ lib.makeBinPath [ pkgs.greetd.tuigreet ] }/tuigreet -r --asterisks --time \
              --cmd "${pkgs.hyprland}/bin/Hyprland";
          '';
        };
      };
    };

    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "dvorak";
      };
    };
  };
}
