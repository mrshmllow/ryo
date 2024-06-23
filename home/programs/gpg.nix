{
  config,
  pkgs,
  ...
}: {
  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.dataHome}/gnupg";
    settings = {keyserver = "hkps://keys.openpgp.org";};
    publicKeys = [
      {
        source = builtins.fetchurl {
          url = "https://github.com/mrshmllow.gpg";
          sha256 = "01mb03xcws3f44vy79x5sk64q4811nh9a1m5y039q0888g95vix7";
        };
        trust = 5;
      }
    ];
  };
  services.gpg-agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };
}
