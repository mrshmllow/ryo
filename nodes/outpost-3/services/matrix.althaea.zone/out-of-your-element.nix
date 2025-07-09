{
  fetchFromGitea,
  buildNpmPackage,
  pkgs,
  ...
}:
buildNpmPackage rec {
  pname = "out-of-your-element";
  version = "2.2";

  src = fetchFromGitea {
    domain = "gitdab.com";
    owner = "cadence";
    repo = "out-of-your-element";
    rev = "v${version}";
    hash = "sha256-2oZiHkFW095KqusuPQJM6w21rL5fW/dYDMS0rACcvg0=";
  };

  npmDepsHash = "sha256-TxfkdXLglgIA6Nbf2d/QxprlfswJ5CyPDoGnImvDK80=";

  buildInputs = [
    pkgs.vips
  ];

  nativeBuildInputs = [ pkgs.pkg-config ];

  dontNpmBuild = true;

  meta = {
    description = "Matrix-Discord bridge with modern features.";
    homepage = "https://gitdab.com/cadence/out-of-your-element";
    mainProgram = "out-of-your-element";
  };
}
