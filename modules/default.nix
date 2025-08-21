{
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./desktop.nix
    ./out-of-your-element.nix
    ./networking.nix
    ./server
  ];

  options.ryo = {
    exporting_nodes = lib.mkOption {
      default = [ ];
      type = lib.types.listOf lib.types.str;
    };
  };

  config = {
    system.activationScripts.diff = {
      supportsDryActivation = true;
      text = ''
        if [ -e /run/current-system ]; then
          PATH=${lib.makeBinPath [ config.nix.package ]} \
            ${lib.getExe pkgs.nvd} \
            diff /run/current-system $systemConfig
        fi
      '';
    };
  };
}
