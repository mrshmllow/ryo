{ pkgs, lib, ... }:
{
  nix.package = pkgs.lix;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    substituters = lib.mkForce [
      "https://cache.nixos.org?priority=1"
      "https://cache.althaea.zone?priority=2"
      "https://cache.garnix.io?priority=3"
      "https://nix-community.cachix.org?priority=10"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "cache.althaea.zone:BelRpa863X9q3Y+AOnl5SM7QFzre3qb+5I7g2s/mqHI="
      "wires.cachix.org-1:7XQoG91Bh+Aj01mAJi77Ui5AYyM1uEyV0h1wOomqjpk="
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
