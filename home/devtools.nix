{pkgs, ...}: {
  home.packages = with pkgs; [
    # secret scanning
    trufflehog

    #calculator
    libqalculate
  ];
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
  programs.zsh = {
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
    initExtra = ''
      function decode_aws_auth() {
        aws sts decode-authorization-message --encoded-message $1 | jq -r .DecodedMessage | jq .
      }

      function fetch-kc-token() {
        export KITTYCAD_TOKEN=$(op --account kittycadinc.1password.com item get "KittyCAD Token" --fields credential)
        export KITTYCAD_DEV_TOKEN=$(op --account kittycadinc.1password.com item get "KittyCAD Dev Token" --fields credential)
      }

      function ssh-k8s() {
        INSTANCE_ID=$(kubectl get node $1 -ojson | jq -r ".spec.providerID" | cut -d \/ -f5)
        aws ssm start-session --target $INSTANCE_ID
      }

      function vault-login() {
        export VAULT_ADDR="http://vault.hawk-dinosaur.ts.net"
        export GITHUB_VAULT_TOKEN=$(op --account kittycadinc.1password.com item get "GitHub Token Vault" --fields token)
        echo $GITHUB_VAULT_TOKEN | vault login -method=github token=-
      }

      function fetch-tfvars() {
        op --account kittycadinc.1password.com item get TerraformCreds --format=json | jq -r '.fields[] | select(.value != null) | "\(.label)=\(.value)"' | while read -r line; do
            # Exporting each line as an environment variable
            export "$line"
        done
      }
    '';
  };
  programs.git = {
    enable = true;
    userName = "Adam Sunderland";
    userEmail = "iterion@gmail.com";
    aliases = {
      co = "checkout";
      amend = "commit -a --amend";
      st = "status";
      b = "branch";
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
      #credential.helper = "osxkeychain";
      init = {
        defaultBranch = "main";
      };
      url."git@github.com:" = {
        insteadOf = "gh:";
        pushInsteadOf = "github:";
      };
    };
  };
  programs.awscli = {
    enable = true;
    settings = ./aws-settings.nix;
  };
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
  };
  services.gnome-keyring.enable = true;
}
