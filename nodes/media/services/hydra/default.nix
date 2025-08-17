{
  config,
  lib,
  pkgs,
  ...
}:
let
  local-nar-cache = "/storage/nars";
  constructQuery =
    parameters:
    builtins.concatStringsSep "&" (
      builtins.map (param: "${param.name}=${builtins.toString param.value}") (lib.attrsToList parameters)
    );
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
        # https://github.com/NixOS/hydra/issues/366
        ./queue-runner.patch

        # ./flakes.patch
      ];
    };
    enable = true;
    buildMachinesFiles = [ ];
    useSubstitutes = true;
    hydraURL = "https://hydra.althaea.zone";
    notificationSender = "hydra@localhost";
    port = 3500;
    extraConfig =
      let
        query = constructQuery {
          write-nar-listing = 1;
          ls-compression = "br";
          log-compression = "br";
          endpoint = "s3.us-east-005.backblazeb2.com";
          secret-key = "/var/lib/hydra/secrets/secret.key";
        };
      in
      ''
        store_uri = s3://wire-cache?${query}
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

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

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

  services.cloudflare-dyndns = {
    enable = true;
    domains = [ "hydra.althaea.zone" ];
    ipv4 = false;
    ipv6 = true;
    proxied = true;
    apiTokenFile = config.deployment.keys."media.cf-dyndns.key".path;
  };

  deployment.keys."media.cf-dyndns.key" = {
    keyCommand = [
      "gpg"
      "--decrypt"
      "${../../../../secrets/media.cf-dyndns.key.gpg}"
    ];

    destDir = "/etc/keys";
    uploadAt = "pre-activation";
  };
}
