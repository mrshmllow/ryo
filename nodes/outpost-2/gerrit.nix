{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  listen = "[::]:8080";
  buildGerritBazelPlugin = (pkgs.callPackage "${inputs.nix-gerrit}/default.nix" {}).buildGerritBazelPlugin;

  avatars-gravatar = pkgs.callPackage ../../packages/gerrit/avatars-gravatar/default.nix {
    buildGerritBazelPlugin = buildGerritBazelPlugin;
  };
in {
  services.gerrit = {
    enable = true;
    # Magic number
    serverId = "65be6090-4b62-4db6-9d66-ab15f82633f7";

    builtinPlugins = [
      "gitiles"
      "reviewnotes"
      "download-commands"
    ];

    settings = {
      gerrit.canonicalWebUrl = "https://gerrit.althaea.zone/";
      auth = {
        type = "OAUTH";
      };
      httpd.listenUrl = "proxy-https://${listen}/";
      plugin.gerrit-oauth-provider-keycloak-oauth = {
        root-url = "https://identity.althaea.zone/";
        realm = "master";
        client-id = "gerrit";
        # client-secret set in /var/lib/gerrit/etc/secure.config
      };
      download.command = [
        "checkout"
        "cherry_pick"
        "format_patch"
        "pull"
      ];

      plugin.code-owners = {
        # A Code-Review +2 vote is required from a code owner.
        requiredApproval = "Code-Review+2";
        # The OWNERS check can be overriden using an Owners-Override vote.
        overrideApproval = "Owners-Override+1";
        # People implicitly approve their own changes automatically.
        enableImplicitApprovals = "TRUE";
      };
    };

    plugins = [
      inputs.nix-gerrit.packages.${pkgs.system}.oauth
      inputs.nix-gerrit.packages.${pkgs.system}.code-owners
      avatars-gravatar
    ];
  };

  # Open ssh port
  networking.firewall.allowedTCPPorts = [29418];

  services.caddy = {
    enable = true;
    virtualHosts."gerrit.althaea.zone".extraConfig = ''
      reverse_proxy http://${listen} {
          @notfound status 404
          handle_response @notfound {
            @repo_match {
              path_regexp ^\/([^\/]+)$
            }

            redir @repo_match /admin/repos/{re.1}
          }
      }
    '';
  };
}
