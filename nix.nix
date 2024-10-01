{pkgs, ...}: {
  nix.package = pkgs.lix;

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
    substituters = [
      "https://cache.nixos.org/"
      "https://cache.garnix.io"
      "https://devenv.cachix.org"
      "https://nix-community.cachix.org"
      "https://wires.cachix.org"
      "https://ryo.cachix.org"
      "https://cosmic.cachix.org/"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "wires.cachix.org-1:7XQoG91Bh+Aj01mAJi77Ui5AYyM1uEyV0h1wOomqjpk="
      "ryo.cachix.org-1:f/pZAkaRjfBYsTX3myaeIdPpxV6rSMcG3m1ofszjjAw="
      "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
