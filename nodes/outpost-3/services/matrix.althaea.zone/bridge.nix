{config, ...}: {
  deployment.keys."out-of-your-element.config.js" = {
    keyCommand = ["gpg" "--decrypt" "${./config.js.gpg}"];
    group = config.services.out-of-your-element.group;
    user = config.services.out-of-your-element.user;
    destDir = "/etc/keys";
    uploadAt = "pre-activation";
  };

  deployment.keys."bridge.service.registration.yaml" = {
    keyCommand = ["gpg" "--decrypt" "${./registration.yaml.gpg}"];
    group = config.services.out-of-your-element.group;
    user = config.services.out-of-your-element.user;
    destDir = "/etc/keys";
    uploadAt = "pre-activation";
  };

  deployment.keys."bridge.matrix.registration.yaml" = {
    keyCommand = ["gpg" "--decrypt" "${./registration.yaml.gpg}"];
    group = "matrix-synapse";
    user = "matrix-synapse";
    destDir = "/etc/keys";
    uploadAt = "pre-activation";
  };

  services.matrix-synapse.settings.app_service_config_files = [
    config.deployment.keys."bridge.matrix.registration.yaml".path
  ];

  services.out-of-your-element = {
    enable = true;
    configFile = config.deployment.keys."out-of-your-element.config.js".path;
    registrationFile = config.deployment.keys."bridge.service.registration.yaml".path;
  };
}
