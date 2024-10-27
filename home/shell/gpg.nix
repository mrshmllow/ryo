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
          sha256 = "0aaagw63bd89pzga82vhisg32gl9x5jz5b2alp47kzl2d6jgal9z";
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
