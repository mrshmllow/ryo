{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.services.minecraft-servers;
in {
  options.services.minecraft-servers = {
    voicechat-servers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };

    unifiedmetrics-servers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };

    velocity = {
      enable = lib.mkEnableOption "velocity server";

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      port = lib.mkOption {
        type = lib.types.int;
        default = 25565;
      };

      config = {
        motd = lib.mkOption {
          type = lib.types.str;
          default = "A minecraft server";
        };

        servers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
        };

        try = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
        };
      };
    };
  };

  config = {
    services.minecraft-servers.servers = lib.mkMerge [
      (lib.genAttrs cfg.velocity.config.servers (name: {
        serverProperties = {
          white-list = true;
          online-mode = false;
          server-ip = "127.0.0.1";
        };
      }))
      (lib.genAttrs cfg.voicechat-servers (name: {
        files = {
          "config/voicechat/voicechat-server.properties" = pkgs.writeText "voicechat-server.properties" ''
            # Setting this to "-1" sets the port to the Minecraft servers port (Not recommended)
            port=${builtins.toString ((lib.lists.findFirstIndex (n: n == name) null cfg.voicechat-servers) + 20000)}
            # Leave empty to use 'server-ip' of server.properties
            bind_address=
            # The distance to where the voice can be heard
            max_voice_distance=48.0
            # The multiplier of the voice distance when crouching
            crouch_distance_multiplier=1.0
            # The multiplier of the voice distance when whispering
            whisper_distance_multiplier=0.5
            # The opus codec
            # Possible values are 'VOIP', 'AUDIO' and 'RESTRICTED_LOWDELAY'
            codec=VOIP
            # The maximum size in bytes that voice packets are allowed to have
            mtu_size=1024
            # The frequency at which keep alive packets are sent
            # Setting this to a higher value may result in timeouts
            keep_alive=1000
            # If group chats are allowed
            enable_groups=true
            # The host name that clients should use to connect to the voice chat
            # This may also include a port, e.g. 'example.com:24454'
            # Don't change this value if you don't know what you are doing
            voice_host=
            # If players are allowed to record the voice chat
            allow_recording=true
            # If spectators are allowed to talk to other players
            spectator_interaction=false
            # If spectators can talk to players they are spectating
            spectator_player_possession=false
            # If players without the mod should get kicked from the server
            force_voice_chat=false
            # The amount of milliseconds, the server should wait to check if the player has the mod installed
            # Only active when force_voice_chat is set to true
            login_timeout=10000
            # The range where the voice chat should broadcast audio to
            # A value <0 means 'max_voice_distance'
            broadcast_range=-1.0
            # If the voice chat server should reply to pings
            allow_pings=true
          '';
        };
      }))
      (lib.genAttrs cfg.unifiedmetrics-servers (name: {
        files = {
          # 9101 because we leave velocity to use 9100 by default
          "config/unifiedmetrics/driver/prometheus.yml" = pkgs.writeText "prometheus.yml" ''
            mode: "HTTP"
            http:
              host: "0.0.0.0"
              port: ${builtins.toString ((lib.lists.findFirstIndex (n: n == name) null cfg.unifiedmetrics-servers) + 9101)}
              authentication:
                scheme: "NONE"
                username: "username"
                password: "password"
            pushGateway:
              job: "unifiedmetrics"
              url: "http://pushgateway:9091"
              authentication:
                scheme: "NONE"
                username: "username"
                password: "password"
              interval: 10
          '';
        };
        symlinks = {
          "mods/unifiedmetrics-fabric.jar" = pkgs.fetchurl {
            url = "https://github.com/Cubxity/UnifiedMetrics/releases/download/v0.3.8/unifiedmetrics-platform-fabric-0.3.8.jar";
            hash = "sha256-ytiOOjLtsxXTKd1Ig7oRxu9boHt7mPEi5zeodUc5rwI=";
          };
          "mods/kotlin.jar" = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/Ha28R6CL/versions/csX9r2wS/fabric-language-kotlin-1.13.0%2Bkotlin.2.1.0.jar";
            hash = "sha256-in9nOy4TFb8svDzIaXU+III8Q/mqW+WW0PdNw8YmrZI=";
          };
        };
      }))
      {
        velocity = lib.mkIf cfg.velocity.enable {
          enable = cfg.velocity.enable;
          autoStart = true;
          package = pkgs.velocityServers.velocity;

          # https://docs.papermc.io/velocity/tuning#tune-your-startup-flags
          jvmOpts = "-XX:+UseG1GC -XX:G1HeapRegionSize=4M -XX:+UnlockExperimentalVMOptions -XX:+ParallelRefProcEnabled -XX:+AlwaysPreTouch -XX:MaxInlineLevel=15";

          symlinks = {
            "plugins/SimpleVoiceChatVelocity.jar" = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/9eGKb6K1/versions/yGTasgG4/voicechat-velocity-2.5.24.jar";
              hash = "sha256-olCVpSs7FGcJQ9dgOaT+mTtmycuevxrBrFnv343zoRI=";
            };
            "velocity.toml" = let
              serverEntry = name: ''${name} = "${cfg.servers.${name}.serverProperties.server-ip}:${builtins.toString cfg.servers.${name}.serverProperties.server-port}"'';
              serverEntries = lib.concatStringsSep "\n" (map serverEntry cfg.velocity.config.servers);
              tryList = lib.concatStringsSep ", " (map (s: ''"${s}"'') cfg.velocity.config.try);
            in
              pkgs.writeText "velocity.toml" ''
                # Do not change this
                config-version = "2.7"

                bind = "0.0.0.0:${builtins.toString cfg.velocity.port}"

                # MiniMessage format
                motd = "${cfg.velocity.config.motd}"

                # What should we display for the maximum number of players? (Velocity does not support a cap
                # on the number of players online.)
                show-max-players = 20

                # Should we authenticate players with Mojang? By default, this is on.
                online-mode = true

                # Should the proxy enforce the new public key security standard? By default, this is on.
                force-key-authentication = true

                # If client's ISP/AS sent from this proxy is different from the one from Mojang's
                # authentication server, the player is kicked. This disallows some VPN and proxy
                # connections but is a weak form of protection.
                prevent-client-proxy-connections = false

                # Should we forward IP addresses and other data to backend servers?
                # Available options:
                # - "none":        No forwarding will be done. All players will appear to be connecting
                #                  from the proxy and will have offline-mode UUIDs.
                # - "legacy":      Forward player IPs and UUIDs in a BungeeCord-compatible format. Use this
                #                  if you run servers using Minecraft 1.12 or lower.
                # - "bungeeguard": Forward player IPs and UUIDs in a format supported by the BungeeGuard
                #                  plugin. Use this if you run servers using Minecraft 1.12 or lower, and are
                #                  unable to implement network level firewalling (on a shared host).
                # - "modern":      Forward player IPs and UUIDs as part of the login process using
                #                  Velocity's native forwarding. Only applicable for Minecraft 1.13 or higher.
                player-info-forwarding-mode = "modern"

                # If you are using modern or BungeeGuard IP forwarding, configure a file that contains a unique secret here.
                # The file is expected to be UTF-8 encoded and not empty.
                forwarding-secret-file = "forwarding.secret"

                # Announce whether or not your server supports Forge. If you run a modded server, we
                # suggest turning this on.
                #
                # If your network runs one modpack consistently, consider using ping-passthrough = "mods"
                # instead for a nicer display in the server list.
                announce-forge = false

                # If enabled (default is false) and the proxy is in online mode, Velocity will kick
                # any existing player who is online if a duplicate connection attempt is made.
                kick-existing-players = false

                # Should Velocity pass server list ping requests to a backend server?
                # Available options:
                # - "disabled":    No pass-through will be done. The velocity.toml and server-icon.png
                #                  will determine the initial server list ping response.
                # - "mods":        Passes only the mod list from your backend server into the response.
                #                  The first server in your try list (or forced host) with a mod list will be
                #                  used. If no backend servers can be contacted, Velocity won't display any
                #                  mod information.
                # - "description": Uses the description and mod list from the backend server. The first
                #                  server in the try (or forced host) list that responds is used for the
                #                  description and mod list.
                # - "all":         Uses the backend server's response as the proxy response. The Velocity
                #                  configuration is used if no servers could be contacted.
                ping-passthrough = "DISABLED"

                # If not enabled (default is true) player IP addresses will be replaced by <ip address withheld> in logs
                enable-player-address-logging = true

                [servers]
                ${serverEntries}

                try = [${tryList}]

                [forced-hosts]

                [advanced]
                # How large a Minecraft packet has to be before we compress it. Setting this to zero will
                # compress all packets, and setting it to -1 will disable compression entirely.
                compression-threshold = 256

                # How much compression should be done (from 0-9). The default is -1, which uses the
                # default level of 6.
                compression-level = -1

                # How fast (in milliseconds) are clients allowed to connect after the last connection? By
                # default, this is three seconds. Disable this by setting this to 0.
                login-ratelimit = 3000

                # Specify a custom timeout for connection timeouts here. The default is five seconds.
                connection-timeout = 5000

                # Specify a read timeout for connections here. The default is 30 seconds.
                read-timeout = 30000

                # Enables compatibility with HAProxy's PROXY protocol. If you don't know what this is for, then
                # don't enable it.
                haproxy-protocol = false

                # Enables TCP fast open support on the proxy. Requires the proxy to run on Linux.
                tcp-fast-open = false

                # Enables BungeeCord plugin messaging channel support on Velocity.
                bungee-plugin-message-channel = true

                # Shows ping requests to the proxy from clients.
                show-ping-requests = false

                # By default, Velocity will attempt to gracefully handle situations where the user unexpectedly
                # loses connection to the server without an explicit disconnect message by attempting to fall the
                # user back, except in the case of read timeouts. BungeeCord will disconnect the user instead. You
                # can disable this setting to use the BungeeCord behavior.
                failover-on-unexpected-server-disconnect = true

                # Declares the proxy commands to 1.13+ clients.
                announce-proxy-commands = true

                # Enables the logging of commands
                log-command-executions = false

                # Enables logging of player connections when connecting to the proxy, switching servers
                # and disconnecting from the proxy.
                log-player-connections = true

                # Allows players transferred from other hosts via the
                # Transfer packet (Minecraft 1.20.5) to be received.
                accepts-transfers = false

                [query]
                # Whether to enable responding to GameSpy 4 query responses or not.
                enabled = false

                # If query is enabled, on what port should the query protocol listen on?
                port = 25566

                # This is the map name that is reported to the query services.
                map = "Velocity"

                # Whether plugins should be shown in query response by default or not
                show-plugins = false
              '';
          };
        };
      }
    ];

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.velocity.openFirewall [
      cfg.velocity.port
    ];
  };
}
