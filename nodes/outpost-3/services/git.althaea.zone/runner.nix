{...}: {
  services.gitea-actions-runner.instances.one = {
    name = "outpost-3";
    enable = true;
    labels = [
      "ubuntu-latest:docker://node:21-bullseye"
    ];
    tokenFile = "/etc/keys/gitea-actions-runner.env";
    url = "https://git.althaea.zone";
  };
}
