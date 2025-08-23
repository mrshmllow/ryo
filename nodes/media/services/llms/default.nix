let
  port = 9005;
in
{
  virtualisation.oci-containers.containers.open-webui = {
    # inherit imageFile;
    image = "ghcr.io/open-webui/open-webui:main";

    ports = [
      "127.0.0.1:${builtins.toString port}:8080"
    ];

    volumes = [
      "open-webui:/app/backend/data"
    ];
  };

  media.subdomains."ai".port = port;
}
