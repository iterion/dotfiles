{ config
, inputs
, lib
, pkgs
, ...
}:
let
  cfg = config.iterion.desktop;
  system = pkgs.stdenv.hostPlatform.system;
  ashellPackage = inputs.ashell.packages.${system}.default;
  toml = pkgs.formats.toml { };
  systemctl = "${pkgs.systemd}/bin/systemctl";

  ashellConfig = {
    log_level = "warn";
    position = "Top";
    layer = "Top";
    enable_esc_key = true;

    modules = {
      left = [ [ "appLauncher" "Workspaces" ] ];
      center = [ "WindowTitle" ];
      right = [
        "SystemInfo"
        "MediaPlayer"
        [
          "Tray"
          "Notifications"
          "Tempo"
          "Privacy"
          "Settings"
        ]
      ];
    };

    CustomModule = [
      {
        name = "appLauncher";
        icon = "󱗼";
        command = "${pkgs.fuzzel}/bin/fuzzel";
      }
    ];

    workspaces = {
      visibility_mode = "All";
      group_by_monitor = false;
      enable_workspace_filling = true;
      max_workspaces = 9;
    };

    window_title = {
      mode = "Title";
      truncate_title_after_length = 120;
    };

    system_info = {
      indicators = [
        "Cpu"
        "Memory"
        "Temperature"
      ];
      interval = 5;

      cpu = {
        warn_threshold = 70;
        alert_threshold = 90;
      };

      memory = {
        warn_threshold = 75;
        alert_threshold = 90;
      };

      temperature.sensor = "Cpu";
    };

    media_player = {
      max_title_length = 80;
      indicator_format = "IconAndTitle";
    };

    tray.right_click = "menu";

    tempo = {
      clock_format = "%a %d %b %R";
      formats = [
        "%a %d %b %R"
        "%Y-%m-%d %H:%M:%S"
        "%H:%M:%S"
      ];
      timezones = [
        "UTC"
        "America/New_York"
        "Europe/London"
      ];
      weather_indicator = "None";
    };

    notifications = {
      format = "%H:%M";
      show_timestamps = true;
      show_bodies = true;
      grouped = true;
      toast = true;
      toast_position = "top_right";
      toast_timeout = 6000;
      toast_limit = 4;
      toast_max_height = 150;
      blocklist = [ ];
    };

    settings = {
      lock_cmd = "${pkgs.playerctl}/bin/playerctl --all-players pause; ${pkgs.hyprlock}/bin/hyprlock";
      shutdown_cmd = "${systemctl} poweroff";
      suspend_cmd = "${systemctl} suspend";
      hibernate_cmd = "${systemctl} hibernate";
      reboot_cmd = "${systemctl} reboot";
      logout_cmd = "${pkgs.systemd}/bin/loginctl kill-user $(${pkgs.coreutils}/bin/whoami)";

      audio_sinks_more_cmd = "${pkgs.pavucontrol}/bin/pavucontrol -t 3";
      audio_sources_more_cmd = "${pkgs.pavucontrol}/bin/pavucontrol -t 4";
      wifi_more_cmd = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
      vpn_more_cmd = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
      bluetooth_more_cmd = "${pkgs.blueman}/bin/blueman-manager";

      battery_format = "IconAndPercentage";
      peripheral_battery_format = "Icon";
      audio_indicator_format = "IconAndPercentage";
      microphone_indicator_format = "Icon";
      network_indicator_format = "Icon";
      bluetooth_indicator_format = "Icon";
      brightness_indicator_format = "Icon";
      volume_step = 5;
      max_volume = 100;
      indicators = [
        "IdleInhibitor"
        "PowerProfile"
        "Audio"
        "Microphone"
        "Bluetooth"
        "Network"
        "Vpn"
        "Battery"
        "Brightness"
      ];
    };

    osd = {
      enabled = true;
      timeout = 1500;
      show_volume_percentage = true;
      show_brightness_percentage = true;
    };

    animations.enabled = true;

    appearance = {
      style = "Islands";
      font_name = "JetBrainsMono Nerd Font";
      opacity = 0.94;
      primary_color = "#3fb9a3";
      success_color = "#9ece6a";
      warning_color = "#e0af68";
      danger_color = "#ec5e63";
      text_color = "#eef1f5";
      workspace_colors = [
        "#3fb9a3"
        "#7aa2f7"
        "#e0af68"
      ];

      menu = {
        opacity = 0.92;
        backdrop = 0.25;
      };

      background_color = {
        base = "#121417";
        weak = "#1f2227";
        strong = "#3a414a";
        text = "#eef1f5";
      };
    };
  };
in
{
  config = lib.mkIf cfg.enable {
    services.mako.enable = lib.mkForce false;
    services.swaync.enable = lib.mkForce false;

    home.packages = [
      ashellPackage
      pkgs.blueman
      pkgs.networkmanagerapplet
      pkgs.pavucontrol
    ];

    xdg.configFile."ashell/config.toml".source =
      toml.generate "ashell-config.toml" ashellConfig;

    systemd.user.services.ashell = {
      Unit = {
        Description = "ashell Wayland desktop shell";
        Documentation = [ "https://github.com/MalpenZibo/ashell" ];
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };

      Service = {
        ExecStart = lib.getExe ashellPackage;
        Restart = "always";
        RestartSec = 2;
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
