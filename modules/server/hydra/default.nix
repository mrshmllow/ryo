{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.hydra;
  local-nar-cache = "";
  constructQuery =
    parameters:
    builtins.concatStringsSep "&" (
      builtins.map (param: "${param.name}=${builtins.toString param.value}") (lib.attrsToList parameters)
    );
in
{
  options.server.hydra = {
    enable = lib.mkEnableOption "hydra build server";
  };

  config = lib.mkIf cfg.enable {
    server.caddy.enable = true;

    deployment.keys."credentials" = {
      keyCommand = [
        "gpg"
        "--decrypt"
        "${../../../secrets/hydra-aws-credentials.key.gpg}"
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

          ./other.patch
        ];
      };
      enable = true;
      buildMachinesFiles = [
        "/etc/nix/machines"
      ];
      useSubstitutes = false;
      hydraURL = "https://hydra.althaea.zone";
      notificationSender = "hydra@localhost";
      port = 3500;
      extraConfig =
        let
          query = constructQuery {
            ls-compression = "br";
            log-compression = "br";
            endpoint = "s3.us-east-005.backblazeb2.com";
            secret-key = "/var/lib/hydra/secrets/secret.key";
          };
        in
        ''
          max_concurrent_evals = 1

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

    nix.buildMachines = [
      {
        hostName = "localhost";
        protocol = null;
        systems = [
          "builtin"
          "x86_64-linux"
          "aarch64-linux"
        ];
        supportedFeatures = [
          "kvm"
          "nixos-test"
          "big-parallel"
          "benchmark"
        ];
        maxJobs = 2;
      }
    ];

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
  };
}
