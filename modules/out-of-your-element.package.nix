{
  fetchFromGitea,
  buildNpmPackage,
  pkgs,
  lib,
  ...
}:
buildNpmPackage rec {
  pname = "out-of-your-element";
  version = "2.3";

  src = fetchFromGitea {
    domain = "gitdab.com";
    owner = "cadence";
    repo = "out-of-your-element";
    rev = "v${version}";
    hash = "sha256-zKJAgbCiHRPeuGFo7vcJeNJYGyOde/dqALzd8W3L2bU=";
  };

  npmDepsHash = "sha256-RtE1P/qTYyvb1setxOd2N5efPF0X0GIkVoaLgLxPuk8=";

  buildInputs = [pkgs.vips];

  nativeBuildInputs = [pkgs.pkg-config];

  dontNpmBuild = true;

  meta = {
    description = "Matrix-Discord bridge with modern features.";
    homepage = "https://gitdab.com/cadence/out-of-your-element";
    mainProgram = "out-of-your-element";
  };
}
