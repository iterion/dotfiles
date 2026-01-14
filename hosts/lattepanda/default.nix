{
  config,
  pkgs,
  lib,
  ...
}:
let
  mdiWebfont = pkgs.fetchzip {
    url = "https://github.com/Templarian/MaterialDesign-Webfont/archive/refs/tags/v7.4.47.zip";
    hash = "sha256-xVhKiAJy/2JaP6HEatzpuDwCbFSvPiIhdhM2csMDFbI=";
    stripRoot = true;
  };
  openaiStt = pkgs.fetchFromGitHub {
    owner = "einToast";
    repo = "openai_stt_ha";
    rev = "v1.2.0";
    hash = "sha256-1c7n341304dii6xq9bh594jpqfffcmm6c2hdwb7v5iifbmbz124l";
  };
in {
  imports = [
    ../base
    ./hardware-configuration.nix
  ];

  networking.hostName = "lattepanda-nixos";

  environment.systemPackages = [
    pkgs.mosquitto
  ];

  # use systemd boot as we don't need grub
  boot.loader.systemd-boot.enable = true;

  # What is my purpose? You tell children to go to bed. Oh my god.
  services.lightsout.enable = true;

  # Keep system time in sync for HA/automation accuracy
  services.timesyncd.enable = true;

  services.home-assistant = {
    enable = true;
    openFirewall = true;
    extraComponents = [
      "aladdin_connect"
      "caldav"
      "esphome"
      "google"
      "hue"
      "litterrobot"
      "mqtt"
      "music_assistant"
      "nest"
      "python_script"
      "solaredge"
      "tesla_fleet"
      "tesla_wall_connector"
      "tplink"
      "unifiprotect"
      "zha"
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
      caseta = pythonPackages."pylutron-caseta";
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
        caseta
      ];
    config = {
      homeassistant = {
        name = "Home";
        time_zone = config.time.timeZone;
        unit_system = "us_customary";
      };
      default_config = {};
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
            {
              name = "Office Presence Detection - combined";
              device_class = "occupancy";
              state = ''
                {% set ld2450 = is_state('binary_sensor.apollo_r_pro_1_ld2450_presence','on') %}
                {% set ld2412 = is_state('binary_sensor.apollo_r_pro_1_ld2412_presence','on') %}
                {{ ld2450 or ld2412 }}
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
    config = {
      "automation nixos" = [];
      "automation ui" = "!include automations.yaml";
      bluetooth = {};
      stt = [
        {
          platform = "openai_stt";
          api_key = "!secret openai_api_key";
          model = "gpt-4o-mini-transcribe";
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
        settings = {
          allow_anonymous = false;
        };
        users = {
          homeassistant = {
            hashedPasswordFile = "/var/lib/mosquitto/homeassistant.hash";
            acl = ["readwrite #"];
          };
        };
      }
    ];
  };

  services.music-assistant = {
    enable = true;
    providers = [
      "apple_music"
      "chromecast"
      "spotify"
      "tidal"
    ];
  };

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      homeassistant.enable = true;
      permit_join = false;
      mqtt = {
        server = "mqtt://127.0.0.1:1883";
        user = "homeassistant";
        password = "!secret mqtt_password";
      };
      serial = {
        port = "/dev/serial/by-id/usb-Nabu_Casa_ZBT-2_DCB4D912E904-if00";
        adapter = "ember";
        baudrate = 460800;
        rtscts = true;
      };
      frontend = {
        port = 8080;
      };
      advanced.log_level = "info";
    };
  };

  networking.firewall.allowedTCPPorts = lib.mkAfter [1883 8095 8080];
  networking.firewall.allowedTCPPortRanges = lib.mkAfter [
    {
      from = 4953;
      to = 5153;
    }
  ];
  networking.firewall.allowedUDPPortRanges = lib.mkAfter [
    {
      from = 4953;
      to = 5153;
    }
  ];
  networking.firewall.allowedUDPPorts = lib.mkAfter [5353];
  systemd.services.zigbee2mqtt.serviceConfig.SupplementaryGroups = ["dialout"];

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
  # Avahi for mDNS/Snapcast discovery
  services.avahi = {
    daemon = {
      enable = true;
      publish.enable = true;
      publish.userServices = true;
    };
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/hass/blueprints 0755 hass hass - -"
    "d /var/lib/hass/python_scripts 0755 hass hass - -"
    "d /var/lib/hass/custom_components 0755 hass hass - -"
    "d /var/lib/hass/custom_components/openai_stt 0755 hass hass - -"
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
    rm -rf /var/lib/hass/custom_components/openai_stt
    cp -R ${openaiStt}/custom_components/openai_stt /var/lib/hass/custom_components/
    chown -R hass:hass /var/lib/hass/custom_components/openai_stt
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
