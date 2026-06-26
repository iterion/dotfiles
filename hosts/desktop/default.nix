{ config
, pkgs
, lib
, ...
}: {
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  boot = {
    plymouth = {
      enable = true;
      theme = "rings";
      themePackages = with pkgs; [
        # By default we would install all themes
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "rings" ];
        })
      ];
    };

    # Enable "Silent boot"
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      polkit_gnome
      kdePackages.ark
      ffmpeg
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
      polkitPolicyOwners = [ "iterion" ];
    };
    # file picker
    xfconf.enable = true;
    thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
    hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };
    niri = {
      enable = true;
      useNautilus = false;
    };
    uwsm.waylandCompositors.hyprland = {
      prettyName = "Hyprland";
      comment = "Hyprland compositor managed by UWSM";
      binPath = "/run/current-system/sw/share/wayland-sessions/hyprland.desktop";
    };
  };
  security.rtkit.enable = true;

  services = {
    gvfs.enable = true;
    tumbler.enable = true;
    blueman.enable = true;
    dbus = {
      enable = true;
      packages = [ pkgs.seahorse ];
    };
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = ''
            ${pkgs.tuigreet}/bin/tuigreet -r --asterisks --time \
              --remember-user-session \
              --sessions /run/current-system/sw/share/wayland-sessions \
              --cmd "${lib.getExe config.programs.uwsm.package} start -F -- /run/current-system/sw/share/wayland-sessions/hyprland.desktop";
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
