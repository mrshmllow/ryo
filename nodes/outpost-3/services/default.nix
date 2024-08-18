{lib, ...}: {
  imports = [
    ./identity.althaea.zone
    ./matrix.althaea.zone
    ./element.althaea.zone
  ];

  # systemd.services.matrix-synapse.wants = "keycloak.sercice";
}
