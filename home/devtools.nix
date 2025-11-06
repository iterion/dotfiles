{
  lib,
  pkgs,
  inputs,
  config,
  ...
}: let
  homeDir =
    if pkgs.stdenv.isDarwin
    then "/Users/iterion"
    else "/home/iterion";
  baseWritableRoots = [
    "${homeDir}/.cache"
    "${homeDir}/.cargo"
    "${homeDir}/.cargo/registry/cache"
    "${homeDir}/.cargo/git/db"
    "${homeDir}/.npm"
    "${homeDir}/.cache/node"
    "${homeDir}/.cache/yarn"
    "/tmp"
  ];
  darwinWritableRoots = [
    "${homeDir}/Library/Application Support"
    "${homeDir}/Library/Caches"
    "${homeDir}/Library/Caches/Yarn"
    "${homeDir}/Library/pnpm"
  ];
  linuxWritableRoots = [
    "${homeDir}/.local/share"
    "${homeDir}/.local/state"
    "${homeDir}/.local/share/pnpm"
    "${homeDir}/.cache/pnpm"
  ];
  writableRoots =
    baseWritableRoots
    ++ lib.optionals pkgs.stdenv.isDarwin darwinWritableRoots
    ++ lib.optionals pkgs.stdenv.isLinux linuxWritableRoots;
  tomlFormat = pkgs.formats.toml {};
  codexConfig = {
    profile = "iterion-default";
    notify = [
      "${homeDir}/.codex/notify"
    ];
    profiles."iterion-default" = {
      approval_policy = "on-request";
      model_reasoning_effort = "high";
      sandbox_mode = "workspace-write";
    };
    projects = {
      "${homeDir}/dotfiles" = {trust_level = "trusted";};
      "${homeDir}/Development/offshape" = {trust_level = "trusted";};
      "${homeDir}/Development/websocket.zig" = {trust_level = "trusted";};
      "${homeDir}/Development/deploy-bot" = {trust_level = "trusted";};
      "${homeDir}/Development/infra" = {trust_level = "trusted";};
      "${homeDir}/Development/api" = {trust_level = "trusted";};
      "${homeDir}/Development/common" = {trust_level = "trusted";};
      "${homeDir}/Development/dockerfelines" = {trust_level = "trusted";};
    };
    sandbox_workspace_write = {
      network_access = true;
      writable_roots = writableRoots;
    };
    web_search_request = true;
  };
  codexToml = builtins.readFile (tomlFormat.generate "codex-config" codexConfig);
  secretsFilePath = "${inputs.self}/secrets/codex.yaml";
  havePushoverSecrets = builtins.pathExists secretsFilePath;
  secretsFile =
    if havePushoverSecrets
    then inputs.self + /secrets/codex.yaml
    else null;
  pushoverTokenFile = "${homeDir}/.config/codex/pushover-token";
  pushoverUserFile = "${homeDir}/.config/codex/pushover-user";
in {
  home.packages = with pkgs;
    [
      # secret scanning
      trufflehog

      helix
      hyperfine

      #calculator
      libqalculate

      llm

      # hex editor
      imhex

      # Curl alternative
      xh

      # Better diffing on syntax trees
      difftastic
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      terminal-notifier
    ];
  xdg.configFile."ghostty/config".text = ''
    custom-shader = ./shaders/cursor_warp.glsl
    custom-shader = ./shaders/ripple_cursor.glsl
    keybind = ctrl+shift+h=goto_split:left
    keybind = ctrl+shift+l=goto_split:right
    keybind = super+alt+c=close_surface
  '';
  xdg.configFile."ghostty/shaders" = {
    source = "${inputs.ghostty-cursor-shaders}";
    recursive = true;
  };
  home.file.".codex/config.toml".text = codexToml;
  home.file.".codex/notify" = {
    source = ./codex/notify.py;
    executable = true;
  };
  sops =
    {
      age.keyFile = "${homeDir}/.config/sops/age/keys.txt";
    }
    // (lib.optionalAttrs havePushoverSecrets {
      defaultSopsFile = secretsFile;
      secrets = {
        "codex/pushover-token" = {
          format = "yaml";
          key = "pushover-token";
          path = pushoverTokenFile;
        };
        "codex/pushover-user" = {
          format = "yaml";
          key = "pushover-user";
          path = pushoverUserFile;
        };
      };
    });
  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = false;
      nix-direnv.enable = true;
    };
    zsh = {
      enable = true;
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "brew"
          "kubectl"
        ];
        theme = "robbyrussell";
      };
      enableCompletion = true;
      shellAliases = {
        k = "kubectl";
      };
      initContent =
        ''
          function decode_aws_auth() {
            aws sts decode-authorization-message --encoded-message $1 | jq -r .DecodedMessage | jq .
          }

          function fetch-kc-token() {
            export KITTYCAD_TOKEN=$(op --account kittycadinc.1password.com item get "KittyCAD Token" --fields credential --reveal)
            export KITTYCAD_DEV_TOKEN=$(op --account kittycadinc.1password.com item get "KittyCAD Dev Token" --fields credential --reveal)
          }

          function ssh-k8s() {
            INSTANCE_ID=$(kubectl get node $1 -ojson | jq -r ".spec.providerID" | cut -d \/ -f5)
            aws ssm start-session --target $INSTANCE_ID
          }

          function vault-login() {
            export VAULT_ADDR="http://vault.hawk-dinosaur.ts.net"
            export GITHUB_VAULT_TOKEN=$(op --account kittycadinc.1password.com item get "GitHub Token Vault" --fields password --reveal)
            echo $GITHUB_VAULT_TOKEN | vault login -method=github token=-
          }

          function fetch-tfvars() {
            op --account kittycadinc.1password.com item get TerraformCreds --format=json --reveal | jq -r '.fields[] | select(.value != null) | "\(.label)=\(.value)"' | while read -r line; do
                # Exporting each line as an environment variable
                export "$line"
            done
          }

          SOPS_KEY_FILE="${homeDir}/.config/sops/age/keys.txt"
          if [ -f "$SOPS_KEY_FILE" ]; then
            export SOPS_AGE_KEY_FILE="$SOPS_KEY_FILE"
            SOPS_RECIPIENT=$(grep '^# public key:' "$SOPS_KEY_FILE" | awk '{print $4}' | head -n1)
            if [ -n "$SOPS_RECIPIENT" ]; then
              export SOPS_AGE_RECIPIENTS="$SOPS_RECIPIENT"
            fi
          fi
        ''
        + lib.optionalString havePushoverSecrets ''
          if [ -f "${pushoverTokenFile}" ]; then
            export CODEX_NOTIFY_PUSHOVER_TOKEN="$(cat ${pushoverTokenFile})"
            export CODEX_NOTIFY_PUSHOVER_TOKEN_FILE="${pushoverTokenFile}"
          fi

          if [ -f "${pushoverUserFile}" ]; then
            export CODEX_NOTIFY_PUSHOVER_USER="$(cat ${pushoverUserFile})"
            export CODEX_NOTIFY_PUSHOVER_USER_FILE="${pushoverUserFile}"
          fi
        '';
    };
    jujutsu = {
      enable = true;
      settings = {
        user = {
          email = "iterion@gmail.com";
          name = "Adam Sunderland";
        };
        ui = {
          diff-formatter = ["difft" "--color=always" "$left" "$right"];
          default-command = [
            "log"
            "--reversed"
            "--limit"
            "20"
          ];
          paginate = "never";
        };
      };
    };
    git = {
      enable = true;
      lfs = {
        enable = true;
      };
      settings = {
        user = {
          name = "Adam Sunderland";
          email = "iterion@gmail.com";
        };
        alias = {
          co = "checkout";
          amend = "commit -a --amend";
          st = "status";
          b = "branch";
        };
        color = {
          ui = "auto";
        };
        diff = {
          tool = "vimdiff";
          mnemonicprefix = true;
        };
        help = {
          autocorrect = 1;
        };
        push = {
          default = "simple";
          autoSetupRemote = true;
        };
        fetch = {
          prune = true;
        };
        stash = {
          showPatch = true;
        };
        #commit.gpgsign = true;
        credential.helper =
          if pkgs.stdenv.isDarwin
          then "osxkeychain"
          else "libsecret";
        init = {
          defaultBranch = "main";
        };
        url."git@github.com:" = {
          insteadOf = "gh:";
          pushInsteadOf = "github:";
        };
      };
    };

    awscli = {
      enable = true;
      # settings = ./aws-settings.nix;
    };
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          addKeysToAgent = "yes";
        };
        "zookeeper" = {
          user = "zoo";
          hostname = "192.168.2.2";
          proxyCommand = "bash /home/iterion/Development/infra/scripts/k8s-on-prem-proxy.sh %h %p";
          forwardAgent = true;
        };
        "mgmt1" = {
          user = "root";
          hostname = "192.168.2.13";
          proxyCommand = "bash /home/iterion/Development/infra/scripts/k8s-on-prem-proxy.sh %h %p";
          forwardAgent = true;
        };
        "mgmt2" = {
          user = "root";
          hostname = "192.168.2.14";
          proxyCommand = "bash /home/iterion/Development/infra/scripts/k8s-on-prem-proxy.sh %h %p";
          forwardAgent = true;
        };
        "compute1" = {
          user = "root";
          hostname = "192.168.2.15";
          proxyCommand = "bash /home/iterion/Development/infra/scripts/k8s-on-prem-proxy.sh %h %p";
          forwardAgent = true;
        };
      };
    };

    nushell = {
      enable = true;
      extraConfig = lib.mkAfter ''
        $env.config.show_banner = false

        def --env vault-login [] {
          $env.VAULT_ADDR = "http://vault.hawk-dinosaur.ts.net"
          let token = (op --account kittycadinc.1password.com item get "GitHub Token Vault" --fields password --reveal)
          $env.VAULT_TOKEN = ($token | vault login -format=json -method=github token=- | from json | get auth.client_token)
        }

        def --env fetch-tfvars [] {
          op --account kittycadinc.1password.com item get TerraformCreds --format=json --reveal | from json | get fields | select -i label value | where value != null | transpose -r | into record | load-env
        }

        def --env fetch-kc-token [] {
          $env.KITTYCAD_TOKEN = (op --account kittycadinc.1password.com item get "KittyCAD Token" --fields credential --reveal)
          $env.KITTYCAD_DEV_TOKEN = (op --account kittycadinc.1password.com item get "KittyCAD Dev Token" --fields credential --reveal)
        }

        def --env fetch-openai-token [] {
          $env.OPENAI_API_KEY = (op --account kittycadinc.1password.com item get "OpenAI Token" --fields credential --reveal)
        }
      '';
      shellAliases = {
        k = "kubectl";
      };
      environmentVariables = {
        EDITOR = "nvim";
      };
    };
    carapace = {
      enable = true;
      enableNushellIntegration = false;
    };

    starship = {
      enable = true;
      settings = {
        add_newline = true;
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };
      };
    };

    yazi = {
      enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = false;
    };
    gpg.enable = true;
  };
  services = {
    gpg-agent = {
      enable = false;
      pinentry.package = pkgs.wayprompt;
      enableSshSupport = true;
      enableZshIntegration = true;
      enableNushellIntegration = false;
    };
  };
}
