{ lib
, buildPythonPackage
, pythonOlder
, pythonAtLeast
, fetchFromGitHub
, pytest
}: buildPythonPackage rec {
    pname = "phue";
    version = "1.1";

    src = fetchFromGitHub {
      owner = "studioimaginaire";
      repo = pname;
      rev = version;
      sha256 = "1n63b6cjjrdwdfmwq0zx1xabjnhndk9mgfkm4w7z9ardcfpvg84l";
    };

    buildInputs = [];

    propagatedBuildInputs = [];

    nativeCheckInputs = [
      pytest
    ];

    disabled = pythonOlder "3.6" || pythonAtLeast "3.8";

    meta = with lib; {
      description = "A Python library for the Philips Hue system";
      homepage = "https://github.com/studioimaginaire/phue";
      license = licenses.mit;
    };
  }
