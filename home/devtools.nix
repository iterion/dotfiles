{ lib, pkgs, ... }:
{
  home.packages = with pkgs; [
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
  ];
  xdg.configFile."ghostty/config".text = ''
    keybind = ctrl+shift+h=goto_split:left
    keybind = ctrl+shift+l=goto_split:right
    keybind = super+alt+c=close_surface
  '';
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
      initContent = ''
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
      userName = "Adam Sunderland";
      userEmail = "iterion@gmail.com";
      aliases = {
        co = "checkout";
        amend = "commit -a --amend";
        st = "status";
        b = "branch";
      };
      lfs = {
        enable = true;
      };
      extraConfig = {
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
        credential.helper = if pkgs.stdenv.isDarwin then "osxkeychain" else "libsecret";
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
      addKeysToAgent = "yes";
      matchBlocks = {
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
