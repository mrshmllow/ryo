{
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [./desktop.nix ./out-of-your-element.nix ./networking.nix ./server/minecraft.nix];

  options.ryo = {
    exporting_nodes = lib.mkOption {
      default = [];
      type = lib.types.listOf lib.types.str;
    };
  };
}
