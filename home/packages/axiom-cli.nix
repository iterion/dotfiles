{ fetchurl
, installShellFiles
, lib
, stdenvNoCC
,
}:
let
  version = "0.20.0";
  sources = {
    aarch64-darwin = {
      artifact = "darwin_arm64";
      hash = "sha256-ByGUyh0Dp0qFfrh8UNk9T/UBkAnTPTsiq7V08n7ZDXM=";
    };
    x86_64-darwin = {
      artifact = "darwin_amd64";
      hash = "sha256-K9Sb2DltKs8aH6cqwXUvYZeVrlMMw2rKzhU9IrLqb8U=";
    };
    aarch64-linux = {
      artifact = "linux_arm64";
      hash = "sha256-beowdBfLdQwcnJoLEMw0kJUxSA3V2oFU3/xm7RVwvZU=";
    };
    x86_64-linux = {
      artifact = "linux_amd64";
      hash = "sha256-w0oedOz+5gDvtIIyh7bM8KJ+UreuiJptGmb3wooz6kg=";
    };
  };
  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Axiom CLI does not provide a release for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "axiom-cli";
  inherit version;

  src = fetchurl {
    url = "https://github.com/axiomhq/cli/releases/download/v${version}/axiom_${version}_${source.artifact}.tar.gz";
    inherit (source) hash;
  };

  nativeBuildInputs = [ installShellFiles ];

  installPhase = ''
    runHook preInstall

    install -Dm755 axiom "$out/bin/axiom"
    installManPage man/*.1
    installShellCompletion \
      --bash completions/axiom.bash \
      --fish completions/axiom.fish \
      --zsh completions/_axiom

    runHook postInstall
  '';

  meta = {
    description = "Powerful log analytics from the command line";
    homepage = "https://axiom.co/docs/reference/cli";
    changelog = "https://github.com/axiomhq/cli/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "axiom";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
