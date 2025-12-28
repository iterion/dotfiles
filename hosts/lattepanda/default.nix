{config, pkgs, ...}: {
  imports = [
    ../base
    ./hardware-configuration.nix
  ];

  networking.hostName = "lattepanda-nixos";

  environment.systemPackages = [];

  # use systemd boot as we don't need grub
  boot.loader.systemd-boot.enable = true;

  # What is my purpose? You tell children to go to bed. Oh my god.
  services.lightsout.enable = true;

  services.home-assistant = {
    enable = true;
    openFirewall = true;
    extraComponents = [
      "google"
      "unifiprotect"
      "tesla_wall_connector"
      "tplink"
      "nest"
      "solaredge"
      "litterrobot"
      "caldav"
      "hue"
      "aladdin_connect"
      "tesla_fleet"
    ];
    extraPackages = pythonPackages:
      let
        googleNest = pythonPackages."google-nest-sdm" or null;
        kasa = pythonPackages.python-kasa or (pythonPackages."python-kasa" or null);
        uiprotect = pythonPackages."pyunifiprotect" or null;
        aiosolaredge = pythonPackages."aiosolaredge" or null;
        pylitterbot = pythonPackages."pylitterbot" or null;
        getmac = pythonPackages."getmac" or null;
        teslaWallConnector = pythonPackages."tesla-wall-connector" or null;
        samsungctl = pythonPackages."samsungctl" or null;
        samsungtvws = pythonPackages."samsungtvws" or null;
        caldav = pythonPackages."caldav" or null;
        gtts = pythonPackages."gtts" or null;
        aladdin = pythonPackages."pyaladdinconnect" or null;
        teslaFleet = pythonPackages."tesla-fleet-api" or null;
      in
        builtins.filter (p: p != null) [
          googleNest
          kasa
          uiprotect
          aiosolaredge
          pylitterbot
          getmac
          teslaWallConnector
          samsungctl
          samsungtvws
          caldav
          gtts
          aladdin
          teslaFleet
        ];
    config = {
      homeassistant = {
        name = "Home";
        time_zone = config.time.timeZone;
        unit_system = "us_customary";
      };
      default_config = {};
    };
  };

  # Home Assistant Bluetooth needs BlueZ running
  hardware.bluetooth.enable = true;
  services.dbus.packages = [ pkgs.bluez ];
  users.groups.home-assistant = {};
  users.users."home-assistant" = {
    isSystemUser = true;
    group = "home-assistant";
    extraGroups = [ "bluetooth" "netdev" ];
  };
  systemd.services.home-assistant.serviceConfig = {
    AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
    CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/hass/blueprints 0755 hass hass - -"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
