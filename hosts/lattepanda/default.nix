{
  config,
  pkgs,
  ...
}: {
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
      "esphome"
      "python_script"
    ];
    extraPackages = pythonPackages: let
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
      mqtt = {
        broker = "127.0.0.1";
        discovery = true;
        username = "homeassistant";
        password = "!secret mqtt_password";
      };
      python_script = {};
      input_boolean = {
        disable_deep_sleep = {
          name = "Disable Deep Sleep";
          icon = "mdi:sleep-off";
        };
      };
      template = [
        {
          binary_sensor = [
            {
              name = "ESP Calendar Data Update During Deep Sleep";
              state = ''
                {% set cal = states.sensor.esp_calendar_data %}
                {% set disp = states.sensor.epaper_calendar_last_display_update %}
                {{ cal is not none and disp is not none and cal.last_updated > disp.last_updated }}
              '';
            }
          ];
        }
        {
          trigger = [
            {
              platform = "time_pattern";
              minutes = "*";
            }
          ];
          action = [
            {
              service = "calendar.get_events";
              data = {
                duration.days = 28;
              };
              target.entity_id = [
                "calendar.home"
              ];
              response_variable = "calendar_response";
            }
            {
              service = "python_script.esp_calendar_data_conversion";
              data = {
                calendar = "{{ calendar_response }}";
                now = "{{ now().date() }}";
              };
              response_variable = "calendar_converted";
            }
          ];
          sensor = [
            {
              name = "ESP Calendar Data";
              state = "OK";
              attributes = {
                todays_day_name = ''
                  {{ ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][now().weekday()] }}
                '';
                    todays_date_month_year = ''
                      {% set months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"] %}
                      {{ months[now().month-1] }} {{  now().strftime('%Y') }}
                    '';
                    closest_end_time = "{{ as_timestamp(calendar_converted.closest_end_time, default=0) }}";
                    entries = "{{ calendar_converted.entries | tojson }}";
                  };
                }
              ];
            }
          ];
    };
  };

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        address = "0.0.0.0";
        port = 1883;
      }
    ];
    extraConf = ''
      allow_anonymous false
      password_file /var/lib/mosquitto/passwd
    '';
  };

  networking.firewall.allowedTCPPorts = (config.networking.firewall.allowedTCPPorts or []) ++ [1883];

  # Home Assistant Bluetooth needs BlueZ running
  hardware.bluetooth.enable = true;
  services.dbus.packages = [pkgs.bluez];
  users.groups.home-assistant = {};
  users.users."home-assistant" = {
    isSystemUser = true;
    group = "home-assistant";
    extraGroups = ["bluetooth" "netdev"];
  };
  users.groups.esphome = {};
  users.users.esphome = {
    isSystemUser = true;
    group = "esphome";
    home = "/var/lib/esphome";
  };

  # Standalone ESPHome dashboard (add-on alternative)
  services.esphome = {
    enable = true;
    openFirewall = true;
    # Bind to all interfaces for remote access
    address = "0.0.0.0";
  };
  systemd.services.esphome.serviceConfig = {
    User = "esphome";
    Group = "esphome";
    StateDirectory = "esphome";
    StateDirectoryMode = "0750";
    Environment = [
      "UV_CACHE_DIR=/var/lib/esphome/.cache/uv"
      "XDG_CACHE_HOME=/var/lib/esphome/.cache"
    ];
  };
  systemd.services.home-assistant.serviceConfig = {
    AmbientCapabilities = ["CAP_NET_ADMIN" "CAP_NET_RAW"];
    CapabilityBoundingSet = ["CAP_NET_ADMIN" "CAP_NET_RAW"];
  };
  systemd.tmpfiles.rules = let
    mdiWebfont = pkgs.fetchzip {
      url = "https://github.com/Templarian/MaterialDesign-Webfont/archive/refs/tags/v7.4.47.zip";
      hash = "sha256-xVhKiAJy/2JaP6HEatzpuDwCbFSvPiIhdhM2csMDFbI=";
      stripRoot = true;
    };
  in [
    "d /var/lib/hass/blueprints 0755 hass hass - -"
    "d /var/lib/hass/python_scripts 0755 hass hass - -"
    "C! /var/lib/hass/python_scripts/esp_calendar_data_conversion.py 0640 hass hass - ${../../home/home-assistant/python_scripts/esp_calendar_data_conversion.py}"
    "d /var/lib/esphome/.cache 0755 esphome esphome - -"
    "d /var/lib/esphome/.cache/uv 0755 esphome esphome - -"
    "d /var/lib/esphome/.platformio 0755 esphome esphome - -"
    "d /var/lib/esphome/.platformio/penv 0755 esphome esphome - -"
    "d /var/lib/esphome/.platformio/penv/bin 0755 esphome esphome - -"
    "d /var/lib/esphome/fonts 0755 esphome esphome - -"
    "L+ /var/lib/esphome/fonts/materialdesignicons-webfont.ttf - - - - ${mdiWebfont}/fonts/materialdesignicons-webfont.ttf"
    "d /var/lib/mosquitto 0750 mosquitto mosquitto - -"
  ];

  system.activationScripts.esphomeCalendarScript = ''
    mkdir -p /var/lib/hass/python_scripts
    rm -f /var/lib/hass/python_scripts/esp_calendar_data_conversion.py
    install -m0640 ${../../home/home-assistant/python_scripts/esp_calendar_data_conversion.py} /var/lib/hass/python_scripts/esp_calendar_data_conversion.py
    chown hass:hass /var/lib/hass/python_scripts/esp_calendar_data_conversion.py
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
