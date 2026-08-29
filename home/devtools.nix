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
  developmentProjectDirs = [
    "OrcaSlicer"
    "admin-dashboard"
    "advent-of-code"
    "api"
    "api-codex"
    "argocd-templates"
    "aws-service-quota-bot"
    "backstage"
    "bad-bson"
    "boot2image"
    "bottlerocket-kernel-kit"
    "cio"
    "cli"
    "configs"
    "dagster-etl"
    "db"
    "deploy-bot"
    "diff-viewer-extension"
    "discord-bots"
    "discourse-deploy"
    "dockerfelines"
    "documentation"
    "dropshot"
    "dropshot-template"
    "dropshot-upstream"
    "engi-meow-ring"
    "engine"
    "engine-deux"
    "engine-manager"
    "executor"
    "factory-gnome"
    "format"
    "gha-actions-public"
    "git-secrets"
    "gltf"
    "gltf-validator"
    "go"
    "hoops"
    "infra"
    "ingress-nginx"
    "jj"
    "kcl-book"
    "kcl-corpus"
    "kcl-llm-finetuning"
    "kerb2d"
    "kittycad.go"
    "kittycad.py"
    "kittycad.rs"
    "kittycad.ts"
    "litterbox"
    "llm-inference"
    "mcmc-dataset"
    "ml-litterbox"
    "ml-research"
    "modeling-api"
    "modeling-app"
    "nexecutor"
    "node_modules"
    "notes"
    "offshape"
    "otel-collector-local"
    "otel-instrument"
    "patch-goblin"
    "pet-store"
    "proprietary-to-kcl"
    "roadrunner"
    "ruststep"
    "stunner"
    "stunner-gateway-operator"
    "stunner-helm"
    "test"
    "test-analysis-bot"
    "text-to-cad"
    "text-to-cad-backroom"
    "text-to-cad-discord-bot-deploy"
    "text-to-cad-ui"
    "third-party-api-clients"
    "ts-actions"
    "twenty-twenty"
    "viewer"
    "viewer-deployment"
    "vitess"
    "vpx-encode"
    "web-view"
    "webrtc"
    "website"
    "websocket.zig"
    "zoo-mcp"
  ];
  trustedDevelopmentProjects =
    builtins.listToAttrs
    (map (dir: {
        name = "${homeDir}/Development/${dir}";
        value = {trust_level = "trusted";};
      })
      developmentProjectDirs);
  codexCloudResourceSafety = ''
    # Cloud Resource Safety

    - Never run `terraform apply`, `terraform destroy`, or any Terraform command that writes state or mutates infrastructure.
    - Never create, update, delete, patch, apply, scale, restart, drain, cordon, uncordon, or roll out cloud or Kubernetes resources.
    - Treat AWS, Kubernetes, Helm, Terraform, Pulumi, CDK, CloudFormation, and similar infrastructure tooling as read-only unless I explicitly run the command myself.
    - If a task requires a cloud or infrastructure mutation, stop before execution and give me the exact command or runbook to execute manually.
    - Do not request approval to bypass this rule. The restriction is about Codex behavior, not the approval policy.
  '';
  codexGlobalInstructions =
    ''
      # Personal Preferences

      - Use Jujutsu (`jj`) for version control operations by default.
      - Prefer `jj` commands (`jj status`, `jj diff`, `jj log`, `jj bookmark`, `jj resolve`, etc.) over Git commands.
      - Only use `git` when I explicitly ask for `git`.
      - When translating examples, provide `jj` equivalents first.

    ''
    + codexCloudResourceSafety;
  tomlFormat = pkgs.formats.toml {};
  codexConfig = {
    approval_policy = "on-request";
    approvals_reviewer = "auto_review";
    developer_instructions = codexCloudResourceSafety;
    model = "gpt-5.6-sol";
    model_reasoning_effort = "xhigh";
    notify = [
      "${homeDir}/.codex/notify"
    ];
    sandbox_mode = "workspace-write";
    service_tier = "fast";
    features = {
      goals = true;
    };
    projects =
      {
        "${homeDir}/dotfiles" = {trust_level = "trusted";};
      }
      // trustedDevelopmentProjects;
    sandbox_workspace_write = {
      network_access = true;
      writable_roots = writableRoots;
    };
    web_search_mode = "enabled";
  };
  codexTomlFile = tomlFormat.generate "codex-config" codexConfig;
  secretsFilePath = "${inputs.self}/secrets/codex.yaml";
  havePushoverSecrets = builtins.pathExists secretsFilePath;
  ageKeyFile = "${homeDir}/.config/sops/age/keys.txt";
  secretsFile =
    if havePushoverSecrets
    then inputs.self + /secrets/codex.yaml
    else null;
  pushoverTokenFile = "${homeDir}/.config/codex/pushover-token";
  pushoverUserFile = "${homeDir}/.config/codex/pushover-user";
  ghosttyConfigText = ''
    custom-shader = ./shaders/cursor_warp.glsl
    custom-shader = ./shaders/ripple_cursor.glsl
    keybind = ctrl+shift+h=goto_split:left
    keybind = ctrl+shift+l=goto_split:right
    keybind = ctrl+alt+period=new_split:right
    keybind = ctrl+alt+comma=new_split:down
    keybind = super+alt+c=close_surface
  '';
  rampCli = let
    version = "0.2.5";
    assets = {
      aarch64-darwin = {
        os = "darwin";
        arch = "arm64";
        hash = "sha256-t3S5fncgmv3LaeK/gXLVg/flVw8RQJt6oj83S9Vvcpk=";
      };
      x86_64-darwin = {
        os = "darwin";
        arch = "amd64";
        hash = "sha256-z5oaG6oj7Amc8tI8wSepU1aAx93HqYwk0om2St/Oe0E=";
      };
      x86_64-linux = {
        os = "linux";
        arch = "amd64";
        hash = "sha256-QDRt9LMEmqjq3YgVPM/kl9bn2V6iGhBCCFIqWuGV9SA=";
      };
      aarch64-linux = {
        os = "linux";
        arch = "arm64";
        hash = "sha256-J3hqGu8TuWH31VvDU9s/hD7zYWfQM3Xpy+Woa6Rnw9U=";
      };
    };
    asset =
      assets.${pkgs.stdenv.hostPlatform.system}
      or (throw "Unsupported system for Ramp CLI: ${pkgs.stdenv.hostPlatform.system}");
    binary = "ramp-${asset.os}-${asset.arch}";
  in
    pkgs.stdenv.mkDerivation {
      pname = "ramp-cli";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://github.com/ramp-public/ramp-cli/releases/download/v${version}/${binary}.tar.gz";
        inherit (asset) hash;
      };

      dontFixup = true;

      installPhase = ''
        runHook preInstall

        mkdir -p "$out/lib/ramp-cli" "$out/bin"
        cp -R . "$out/lib/ramp-cli"
        chmod +x "$out/lib/ramp-cli/${binary}"
        ln -s "$out/lib/ramp-cli/${binary}" "$out/bin/ramp"

        runHook postInstall
      '';

      meta = {
        description = "Ramp CLI for terminal finance workflows and AI agents";
        homepage = "https://github.com/ramp-public/ramp-cli";
        license = lib.licenses.mit;
        mainProgram = "ramp";
        platforms = builtins.attrNames assets;
      };
    };
in {
  home.packages = with pkgs;
    [
      # agentic tools
      opencode
      rampCli

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

      # Better nix devenvs
      devenv
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      terminal-notifier
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      claude-code
      codex
    ];
  xdg.configFile."ghostty/config".text = ghosttyConfigText;
  xdg.configFile."ghostty/shaders" = {
    source = "${inputs.ghostty-cursor-shaders}";
    recursive = true;
  };
  home.file = lib.mkMerge [
    {
      ".codex/config.toml" = {
        source = codexTomlFile;
        force = true;
      };
      ".codex/AGENTS.md" = {
        text = codexGlobalInstructions;
        force = true;
      };
      ".codex/notify" = {
        source = ./codex/notify.py;
        executable = true;
      };
    }
    (lib.optionalAttrs pkgs.stdenv.isDarwin {
      "Library/Application Support/com.mitchellh.ghostty/config".text =
        ghosttyConfigText;
      "Library/Application Support/com.mitchellh.ghostty/shaders" = {
        source = "${inputs.ghostty-cursor-shaders}";
        recursive = true;
      };
    })
  ];
  sops =
    {
      age.keyFile = ageKeyFile;
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
  systemd.user.services.sops-nix.Unit.ConditionPathExists =
    lib.mkIf havePushoverSecrets ageKeyFile;
  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = false;
      nix-direnv.enable = true;
    };
    zsh = {
      enable = true;
      dotDir = config.home.homeDirectory;
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
          HISTSIZE="100000"
          SAVEHIST="100000"
          setopt APPEND_HISTORY
          setopt INC_APPEND_HISTORY

          alias cdr='cd $(git rev-parse --show-toplevel)'

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
      package =
        (inputs.jj.packages.${pkgs.stdenv.hostPlatform.system}.jujutsu-quick.override {
          rustPlatform = pkgs.rustPlatform;
        }).overrideAttrs {
          doCheck = false;
        };
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
        templates.git_push_bookmark = ''"iterion/" ++ change_id.short()'';
        "remotes.origin.auto-track-bookmarks" = true;
      };
    };
    git = {
      enable = true;
      signing.format = "openpgp";
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
        "framework framework-16" = {
          hostname = "framework-16.hawk-dinosaur.ts.net";
          user = "iterion";
          identityFile = "~/.ssh/id_ed25519";
          identitiesOnly = true;
          forwardAgent = false;
          serverAliveInterval = 30;
          serverAliveCountMax = 3;
          extraOptions.StrictHostKeyChecking = "accept-new";
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
      shellWrapperName = "yy";
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
