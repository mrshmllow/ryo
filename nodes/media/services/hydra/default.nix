{ config, pkgs, ... }:
let
  local-nar-cache = "/storage/nars";
in
{
  deployment.keys."credentials" = {
    keyCommand = [
      "gpg"
      "--decrypt"
      "${../../../../secrets/hydra-aws-credentials.key.gpg}"
    ];
    uploadAt = "pre-activation";
    destDir = "/var/lib/hydra/queue-runner/.aws";
    group = "hydra";
    user = "hydra-queue-runner";
  };

  services.hydra = {
    package = pkgs.hydra.overrideAttrs {
      patches = [
        # https://github.com/NixOS/hydra/issues/366#issuecomment-650126996
        # ./hydra.patch

        # ./flakes.patch
      ];
    };
    enable = true;
    buildMachinesFiles = [ ];
    useSubstitutes = false;
    hydraURL = "https://hydra.home.althaea.zone";
    notificationSender = "hydra@localhost";
    port = 3500;
    extraConfig = ''
      store_uri = s3://wire-cache?write-nar-listing=1&ls-compression=br&log-compression=br&index-debug-info=true&endpoint=s3.us-east-005.backblazeb2.com
      server_store_uri = https://cache.althaea.zone?local-nar-cache=${local-nar-cache}
      binary_cache_public_uri = https://cache.althaea.zone

      log_prefix = https://cache.althaea.zone/
      upload_logs_to_binary_cache = true
      compress_build_logs = false

      <githubstatus>
        jobs = wire:.*
        ## This example will match all jobs
        # jobs = .*
        # inputs = src
        excludeBuildFromContext = 1
        useShortContext = 1
      </githubstatus>

      <github_authorization>
        Include /var/lib/hydra/secrets/github-secrets.conf
      </github_authorization>

      <webhooks>
        Include /var/lib/hydra/secrets/webhook-secrets.conf
      </webhooks>
    '';
  };

  # nix.buildMachines = [
  #   {
  #     hostName = "localhost";
  #     protocol = null;
  #     systems = [
  #       "builtin"
  #       "x86_64-linux"
  #     ];
  #     supportedFeatures = [
  #       "kvm"
  #       "nixos-test"
  #       "big-parallel"
  #       "benchmark"
  #     ];
  #     maxJobs = 8;
  #   }
  # ];

  media.subdomains."hydra".port = config.services.hydra.port;

  services.anubis.instances.hydra.settings = {
    TARGET = "http://127.0.0.1:3500";
    BIND = ":3501";
    BIND_NETWORK = "tcp";
    SERVE_ROBOTS_TXT = true;
  };

  services.caddy.virtualHosts."hydra.althaea.zone".extraConfig = ''
    tls {
        dns cloudflare {$CLOUDFLARE_API_TOKEN}
    }

    reverse_proxy http://localhost:3501 {
        header_up X-Real-Ip {remote_host}
        header_up X-Http-Version {http.request.proto}
    }
  '';

  # systemd.services.hydra-notify.enable = false;

  networking.firewall.allowedTCPPorts = [ config.services.hydra.port ];
}
